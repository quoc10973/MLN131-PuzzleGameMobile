import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryGameScreen extends StatefulWidget {
  final String assetFolder;
  const MemoryGameScreen({super.key, required this.assetFolder});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<_CardModel> _cards = <_CardModel>[];
  bool _isChecking = false;
  int _moves = 0;
  int _quizPoints = 0;
  String? _debugInfo;
  List<_QuizQuestion> _quizQuestions = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _loadAssetsAndSetup();
    await _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/quiz_chuong4_5.json');
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
      _quizQuestions = jsonData
          .map((json) => _QuizQuestion.fromJson(json as Map<String, dynamic>))
          .toList();
      _quizQuestions.shuffle(); // Randomize questions
    } catch (e) {
      // Quiz load error - can still play without quiz
    }
  }

  Future<void> _loadAssetsAndSetup() async {
    final String folder = widget.assetFolder;
    // Use new API only
    final AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> puzzleAssets = manifest
        .listAssets()
        .where((String key) => key.startsWith(folder))
        .toList(growable: false);

    if (puzzleAssets.isEmpty) {
      setState(() {
        _cards.clear();
        _debugInfo = 'Không tìm thấy file trong $folder';
      });
      return;
    }

    // Create pairs from each asset
    final List<_CardModel> generated = <_CardModel>[];
    int idCounter = 0;
    for (final String path in puzzleAssets) {
      generated.add(_CardModel(id: idCounter++, imagePath: path));
      generated.add(_CardModel(id: idCounter++, imagePath: path));
    }

    generated.shuffle();

    setState(() {
      _moves = 0;
      _cards
        ..clear()
        ..addAll(generated);
      _debugInfo = 'Đã nạp ${puzzleAssets.length} ảnh từ $folder';
    });
  }

  void _onCardTap(int index) async {
    if (_isChecking) return;
    if (index < 0 || index >= _cards.length) return;

    final _CardModel tapped = _cards[index];
    if (tapped.isMatched || tapped.isFaceUp) return;

    // Kiểm tra số thẻ đang lật trước khi lật thẻ này
    final int currentlyFaceUp = _cards.where((c) => c.isFaceUp && !c.isMatched).length;
    
    // Nếu chưa có thẻ nào lật và không đủ 2 điểm, không cho lật
    if (currentlyFaceUp == 0 && _quizPoints < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cần 2 điểm quiz để bắt đầu lật ảnh! Hiện tại: $_quizPoints điểm'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 70, left: 8, right: 8),
          ),
        );
      return;
    }
    
    // Trừ 2 điểm khi bắt đầu lật cặp (chỉ lần lật đầu tiên)
    if (currentlyFaceUp == 0) {
      setState(() {
        _quizPoints -= 2;
      });
    }

    // Lật thẻ
    setState(() {
      tapped.isFaceUp = true;
    });

    final List<_CardModel> faceUpUnmatched =
        _cards.where((c) => c.isFaceUp && !c.isMatched).toList(growable: false);

    // Khi có 2 thẻ được lật (cặp thẻ), xử lý
    if (faceUpUnmatched.length == 2) {
      setState(() {
        _moves += 1;
      });
      _isChecking = true;

      final _CardModel a = faceUpUnmatched[0];
      final _CardModel b = faceUpUnmatched[1];

      if (a.imagePath == b.imagePath) {
        // Match
        await Future<void>.delayed(const Duration(milliseconds: 250));
        setState(() {
          a.isMatched = true;
          b.isMatched = true;
        });
        _isChecking = false;
        _checkWin();
      } else {
        // Not a match, flip back after a short delay
        await Future<void>.delayed(const Duration(milliseconds: 800));
        setState(() {
          a.isFaceUp = false;
          b.isFaceUp = false;
        });
        _isChecking = false;
      }
    }
  }

  void _checkWin() {
    final bool allMatched = _cards.isNotEmpty && _cards.every((c) => c.isMatched);
    if (allMatched) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // Xác định level hiện tại và level tiếp theo
          final currentLevel = widget.assetFolder;
          String? nextLevel;
          String levelName;
          
          if (currentLevel.contains('lv1')) {
            nextLevel = 'assets/puzzle/lv2/';
            levelName = 'Dễ';
          } else if (currentLevel.contains('lv2')) {
            nextLevel = 'assets/puzzle/lv3/';
            levelName = 'Vừa';
          } else {
            levelName = 'Khó';
          }
          
          return AlertDialog(
            title: const Text('Chúc mừng!'),
            content: Text('Bạn đã hoàn thành với $_moves lượt lật.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadAssetsAndSetup();
                  setState(() {
                    _quizPoints = 0;
                  });
                },
                child: const Text('Chơi lại'),
              ),
              if (nextLevel != null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => MemoryGameScreen(assetFolder: nextLevel!),
                      ),
                    );
                  },
                  child: const Text('Chơi tiếp'),
                ),
              ],
            ],
          );
        },
      );
    }
  }

  void _showQuizModal() {
    if (_quizQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được quiz!'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 70, left: 8, right: 8),
        ),
      );
      return;
    }
    // Random chọn một câu hỏi từ danh sách
    final randomIndex = DateTime.now().microsecondsSinceEpoch % _quizQuestions.length;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuizModal(
        question: _quizQuestions[randomIndex],
        onCorrect: () {
          setState(() {
            _quizPoints++;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Trả lời đúng! +1 điểm'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 70, left: 8, right: 8),
            ),
          );
        },
        onWrong: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Trả lời sai! Không có điểm'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 70, left: 8, right: 8),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game lật ảnh'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadAssetsAndSetup,
            icon: const Icon(Icons.refresh),
            tooltip: 'Chơi lại',
          ),
        ],
      ),
      body: SafeArea(
        child: _cards.isEmpty
            ? _EmptyOrLoading(debugInfo: _debugInfo)
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width >= 1000) {
                    crossAxisCount = 6;
                  } else if (width >= 800) {
                    crossAxisCount = 5;
                  } else if (width >= 600) {
                    crossAxisCount = 4;
                  } else if (width >= 360) {
                    crossAxisCount = 3;
                  }
                  // < 360: default 2

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Lượt: $_moves',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            Text('Điểm: $_quizPoints',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.green)),
                            Text('Còn: ${_cards.where((c) => !c.isMatched).length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _cards.length,
                          itemBuilder: (BuildContext context, int index) {
                            final _CardModel card = _cards[index];
                            return _CardView(
                              card: card,
                              onTap: () => _onCardTap(index),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showQuizModal,
                            icon: const Icon(Icons.quiz),
                            label: const Text('Trả lời quiz để có điểm!'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyOrLoading extends StatelessWidget {
  const _EmptyOrLoading({this.debugInfo});

  final String? debugInfo;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Đang tải ảnh hoặc không tìm thấy ảnh.'),
          if (debugInfo != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              debugInfo!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardModel {
  _CardModel({required this.id, required this.imagePath});

  final int id;
  final String imagePath;
  bool isFaceUp = false;
  bool isMatched = false;
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.onTap});

  final _CardModel card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget front = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.grey.shade200,
        child: Image.asset(
          card.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Không tải được ảnh',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
    );

    final Widget back = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.blue,
        child: const Center(
          child: Icon(Icons.help_outline, color: Colors.white, size: 32),
        ),
      ),
    );

    return GestureDetector(
      onTap: card.isMatched ? null : onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: card.isMatched
            ? const SizedBox.shrink()
            : card.isFaceUp
                ? front
                : back,
      ),
    );
  }
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;

  _QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory _QuizQuestion.fromJson(Map<String, dynamic> json) {
    final originalOptions = List<String>.from(json['options'] as List);
    final originalAnswer = json['answer'] as String;
    
    // Tìm index của đáp án gốc (A=0, B=1, C=2, D=3)
    final originalAnswerIndex = originalAnswer.codeUnitAt(0) - 65;
    
    // Random thứ tự
    final indices = List.generate(originalOptions.length, (i) => i)..shuffle();
    final shuffledOptions = indices.map((i) => originalOptions[i]).toList();
    
    // Tìm vị trí mới của đáp án trong mảng đã shuffle
    final newAnswerIndex = indices.indexOf(originalAnswerIndex);
    final newAnswer = String.fromCharCode(65 + newAnswerIndex); // A, B, C, D
    
    return _QuizQuestion(
      question: json['question'] as String,
      options: shuffledOptions,
      answer: newAnswer,
    );
  }
}

class _QuizModal extends StatefulWidget {
  final _QuizQuestion question;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  const _QuizModal({
    required this.question,
    required this.onCorrect,
    required this.onWrong,
  });

  @override
  State<_QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<_QuizModal> {
  String? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Câu hỏi Quiz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
              final isSelected = _selectedAnswer == optionLetter;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blue : null,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedAnswer = optionLetter;
                    });
                  },
                  child: Text(
                    '$optionLetter. $option',
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _selectedAnswer == null
              ? null
              : () {
                  if (_selectedAnswer == widget.question.answer) {
                    widget.onCorrect();
                  } else {
                    widget.onWrong();
                  }
                },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
