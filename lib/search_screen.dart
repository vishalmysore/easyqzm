import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'model/question.dart';
import 'model/question.model.dart';
import 'model/score.dart';
import 'model/sharedtext.dart';
import 'service/api_service.dart';
import 'package:universal_html/html.dart' hide Text,Navigator;
import 'package:loader_overlay/loader_overlay.dart';
class SearchScreen extends StatefulWidget {
  final String? text;

  const SearchScreen({Key? key, required this.text}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  final ApiService apiService = ApiService();
  Future<QuizResponse>? quizResponse;

  final String? userId = window.localStorage['username'];
  late  String userInput;

  @override
  void dispose() {

    super.dispose();
  }
  Future<void> _fetchData(String difficulty) async {
    context.loaderOverlay.show();
    userInput = _controller.text.trim();
    if (userInput.isEmpty) return;


    try {
      final response = await apiService.fetchQuestions(userInput, difficulty);
      setState(() {
        quizResponse = Future.value(response);

      });
    } catch (e) {
      setState(() {
        quizResponse = Future.error("Error: ${e.toString()}");

      });
    }
    context.loaderOverlay.hide();
  }

  // Function to check answers
  void _checkAnswers() {
    if (quizResponse != null) {

      quizResponse!.then((quiz) {
        int correctAnswers = 0;
        Score finalScore = calculateScore(quiz, userId!);
        apiService.submitScore(finalScore);
        // Count correct answers
        for (var question in quiz.questions) {
          if (question.userAnswer == question.correctAnswer) {
            correctAnswers++;
          }
        }

        // Show a dialog with the result
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Quiz Completed!"),
              content: Text("You got $correctAnswers out of ${quiz.questions.length} correct!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Score calculateScore(QuizResponse quizResponse, String userId) {
    int correctAnswers = 0;
    int incorrectAnswers = 0;
    int skippedQuestions = 0;
    int totalQuestions = quizResponse.questions.length;

    for (var question in quizResponse.questions) {
      if (question.userAnswer == null || question.userAnswer!.isEmpty) {
        skippedQuestions++;
      } else if (question.userAnswer == question.correctAnswer) {
        correctAnswers++;
      } else {
        incorrectAnswers++;
      }
    }

    int totalScore = correctAnswers * 10; // Assuming each question is worth 10 points
    int score = correctAnswers ;
    double percentage = (correctAnswers / totalQuestions) * 100;

    return Score(
      userId: userId,
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      skippedQuestions: skippedQuestions,
      totalScore: totalScore,
      percentage: percentage,
      quizId: quizResponse.quizId,
      questions: quizResponse.questions,
      url: userInput, topics:userInput
    );
  }
  @override
  Widget build(BuildContext context) {
    print("building search screen ${widget.text}");
    return  LoaderOverlay ( child: Scaffold(
      appBar: AppBar(title: Text("Search Quiz")),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
          Consumer<SharedTextModel>(
          builder: (context, sharedTextModel, child) {
            print(sharedTextModel.sharedText);
            // Update the controller's text when sharedText changes
            if (_controller.text != sharedTextModel.sharedText) {
      _controller.text = sharedTextModel.sharedText;
      }
        return TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Enter a topic or link",
          border: OutlineInputBorder(),
        ),
      );
    },
    ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () => _fetchData("1"), child: Text("Easy")),
                  ElevatedButton(onPressed: () => _fetchData("2"), child: Text("Tough")),
                  ElevatedButton(onPressed: () => _fetchData("3"), child: Text("Tougher")),
                  ElevatedButton(onPressed: () => _fetchData("4"), child: Text("Crazy")),
                ],
              ),
              SizedBox(height: 20),
              FutureBuilder<QuizResponse>(
                future: quizResponse,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  } else if (snapshot.hasData) {
                    final quiz = snapshot.data!;
                    return Column(
                      children: [
                        // Use ListView.builder with shrinkWrap: true to prevent overflow
                        ListView.builder(
                          shrinkWrap: true,  // This allows the ListView to take up only the necessary space
                          physics: NeverScrollableScrollPhysics(),  // Disable scrolling within this ListView to allow the parent scroll to work
                          itemCount: quiz.questions.length,
                          itemBuilder: (context, index) {
                            final question = quiz.questions[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.questionText,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    ...question.answerChoices.map((choice) {
                                      return RadioListTile<String>(
                                        title: Text(choice),
                                        value: choice,
                                        groupValue: question.userAnswer,
                                        onChanged: (value) {
                                          setState(() {
                                            question.userAnswer = value;  // Update the user's answer
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _checkAnswers,  // Call the check answers function on press
                          child: Text("Submit"),
                        ),
                      ],
                    );
                  }
                  return Center(child: Text("No quiz data available."));
                },
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
