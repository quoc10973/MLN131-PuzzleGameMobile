import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer; // "A", "B", "C", "D"

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  bool _showResult = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/quiz_chuong4_5.json');
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
      setState(() {
        _questions = jsonData
            .map((json) => QuizQuestion.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải quiz: $e')),
        );
      }
    }
  }

  void _handleAnswer(String answer) {
    if (_showResult) return;
    
    setState(() {
      _selectedAnswer = answer;
      if (answer == _questions[_currentIndex].answer) {
        _score++;
      }
      _showResult = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả'),
        content: Text('Bạn đã trả lời đúng $_score/${_questions.length} câu hỏi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Không có câu hỏi')),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = _selectedAnswer == currentQuestion.answer;

    return Scaffold(
      appBar: AppBar(
        title: Text('Câu hỏi ${_currentIndex + 1}/${_questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentQuestion.question,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
                  final isSelected = _selectedAnswer == optionLetter;
                  
                  Color buttonColor = Colors.blue;
                  if (_showResult) {
                    if (optionLetter == currentQuestion.answer) {
                      buttonColor = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      buttonColor = Colors.red;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => _handleAnswer(optionLetter),
                      child: Text(
                        '$optionLetter. ${currentQuestion.options[index]}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showResult) ...[
              const SizedBox(height: 10),
              Text(
                isCorrect ? '✓ Đúng!' : '✗ Sai!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Câu tiếp' : 'Xem kết quả',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



