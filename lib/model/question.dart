class Question {
  final String questionId;
  final String questionText;
  final List<String> answerChoices;
  final String correctAnswer;
  String? userAnswer;

  Question({
    required this.questionId,
    required this.questionText,
    required this.answerChoices,
    required this.correctAnswer,
    this.userAnswer,
  });

  // To convert JSON response into Question object
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      questionText: json['questionText'],
      answerChoices: List<String>.from(json['answerChoices']),
      correctAnswer: json['correctAnswer'],
      userAnswer: json['userAnswer'],
    );
  }
}

class QuizResponse {
  final String quizId;
  final List<Question> questions;

  QuizResponse({required this.quizId, required this.questions});

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      quizId: json['quizId'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }
}
