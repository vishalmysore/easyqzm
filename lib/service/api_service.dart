import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';

import '../model/question.dart';

class ApiService {
  final String apiUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:7860/api/',  // Default for local environment
  );


  // Fetch the token from localStorage
  final String? token = window.localStorage['jwtToken'];

  // Fetch questions based on user input and difficulty
  Future<QuizResponse> fetchQuestions(String userInput, String difficulty) async {
    print("Token stored in fetching localStorage: $token");
    // Make sure to add the token to the headers if it's available
    final response = await http.get(
      Uri.parse('${apiUrl}getQuestions?prompt=$userInput&difficulty=$difficulty'),
      headers: {
        'Authorization': token != null ? 'Bearer $token' : '',  // Add token if it's available
      },
    );

    // Handle the response
    if (response.statusCode == 200) {
      // Parse the response to create QuizResponse
      final data = jsonDecode(response.body);
      return QuizResponse.fromJson(data);
    } else {
      throw Exception("Error fetching quiz data");
    }
  }


}
