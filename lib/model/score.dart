import 'dart:convert';
import 'package:easyqzm/model/question.dart';
import 'package:http/http.dart' as http;

class Score {
  final String? userId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;
  final int totalScore;
  final double percentage;
  final String? quizId;
  final String? url;
  final String? topics;
  final List<Question> questions;

  Score({
    this.userId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedQuestions,
    required this.totalScore,
    required this.percentage,
    this.quizId,
    this.url,
    this.topics,
    required this.questions,
  });

  // Convert Score object to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'skippedQuestions': skippedQuestions,
      'totalScore': totalScore,
      'percentage': percentage,
      'quizId': quizId,
      'url': url,
      'topics': topics,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

// Extend Question class with toJson
extension QuestionExtension on Question {
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'answerChoices': answerChoices,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
    };
  }
}

// Function to calculate quiz score


// Function to send result to backend

