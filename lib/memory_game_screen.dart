import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<_CardModel> _cards = <_CardModel>[];
  bool _isChecking = false;
  int _moves = 0;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadAssetsAndSetup();
  }

  Future<void> _loadAssetsAndSetup() async {
    // Use AssetManifest API (handles format changes across Flutter versions)
    final AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> puzzleAssets = manifest
        .listAssets()
        .where((String key) => key.startsWith('assets/puzzle/'))
        .toList(growable: false);

    if (puzzleAssets.isEmpty) {
      setState(() {
        _cards.clear();
        _debugInfo = 'Không tìm thấy file trong assets/puzzle';
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
      _debugInfo = 'Đã nạp ${puzzleAssets.length} ảnh từ assets/puzzle';
    });
  }

  void _onCardTap(int index) async {
    if (_isChecking) return;
    if (index < 0 || index >= _cards.length) return;

    final _CardModel tapped = _cards[index];
    if (tapped.isMatched || tapped.isFaceUp) return;

    setState(() {
      tapped.isFaceUp = true;
    });

    final List<_CardModel> faceUpUnmatched =
        _cards.where((c) => c.isFaceUp && !c.isMatched).toList(growable: false);

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
          return AlertDialog(
            title: const Text('Chúc mừng!'),
            content: Text('Bạn đã hoàn thành với $_moves lượt lật.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadAssetsAndSetup();
                },
                child: const Text('Chơi lại'),
              ),
            ],
          );
        },
      );
    }
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
                  // Determine grid crossAxisCount based on width
                  final double width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width >= 1000) {
                    crossAxisCount = 6;
                  } else if (width >= 800) {
                    crossAxisCount = 5;
                  } else if (width >= 600) {
                    crossAxisCount = 4;
                  } else if (width >= 400) {
                    crossAxisCount = 3;
                  }

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
                            Text('Còn: ${_cards.where((c) => !c.isMatched).length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
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
          const Text('Đang tải ảnh hoặc không tìm thấy ảnh trong assets/puzzle'),
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


