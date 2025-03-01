

import 'package:easyqzm/model/userperformance.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';

import '../model/link.dart';
import '../model/question.dart';
import '../model/score.dart';
import '../model/user.dart';

class ApiService {
  final String apiUrl = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/api/'  // Production
      : 'http://localhost:7860/api/';  // Local


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

  Future<UserPerformance?> fetchUserPerformance() async {
    final url = Uri.parse('${apiUrl}getUserAnalytics');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : '',
        },
      );

      if (response.statusCode == 200) {
        return UserPerformance.fromJson(json.decode(response.body));
      } else {
        print('Failed to load user performance: ${response.statusCode}');
        return null; // Return null in case of an error
      }
    } catch (e) {
      print('Error fetching user performance: $e');
      return null; // Handle exceptions
    }
  }


  Future<void> submitScore(Score score) async {


    try {
      final response = await http.post(
        Uri.parse('${apiUrl}updateResults'),
        headers: {'Content-Type': 'application/json','Authorization': token != null ? 'Bearer $token' : '', },
        body: jsonEncode(score.toJson()),
      );

      if (response.statusCode == 200) {
        print('Score submitted successfully');
      } else {
        print('Failed to submit score: ${response.body}');
      }
    } catch (e) {
      print('Error submitting score: $e');
    }
  }


  Future<List<Link>> getTrendingLastHour() async {
    final url = Uri.parse('${apiUrl}getTrendingLastHour');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : '',
        },
      );

      if (response.statusCode == 200) {
        // Decode JSON response
        List<dynamic> jsonData = jsonDecode(response.body);

        // Convert JSON list to List<Link>
        return jsonData.map((item) => Link.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch trending links: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending links: $e');
      throw Exception('Failed to fetch trending links');
    }
  }


  Future<List<Link>> getTrendingLastAll() async {
    final url = Uri.parse('${apiUrl}getTrendingAll');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : '',
        },
      );

      if (response.statusCode == 200) {
        // Decode JSON response
        List<dynamic> jsonData = jsonDecode(response.body);

        // Convert JSON list to List<Link>
        return jsonData.map((item) => Link.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch trending links: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending links: $e');
      throw Exception('Failed to fetch trending links');
    }
  }
}
