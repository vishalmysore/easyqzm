import 'package:easyqzm/model/question.dart';

class Story {
  final String storyId;
  final String storyText;
  final String userId;
  final String storyType;
  final String title;
  final List<Question>? questions;
  final String createdTimestamp;

  Story({
    required this.storyId,
    required this.storyText,
    required this.userId,
    required this.storyType,
    required this.title,
    this.questions,
    required this.createdTimestamp,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      storyId: json['storyId'],
      storyText: json['storyText'],
      userId: json['userId'],
      storyType: json['storyType'],
      title: json['title'],
      questions: json['questions'] != null
          ? (json['questions'] as List).map((q) => Question.fromJson(q)).toList()
          : [],
      createdTimestamp: json['createdTimestamp'],
    );
  }

  QuizResponse getQuizResponse() {
    return QuizResponse(
      quizId: storyId, // Use storyId as quizId
      questions: questions ?? [], // Use questions from the Story
    );
  }
}


