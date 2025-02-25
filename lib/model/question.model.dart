import 'package:flutter/material.dart';

class QuestionsModel with ChangeNotifier {
  List<String> _questions = [];

  List<String> get questions => _questions;

  void setQuestions(List<String> newQuestions) {
    _questions = newQuestions;
    notifyListeners(); // Notify listeners when data changes
  }
}
