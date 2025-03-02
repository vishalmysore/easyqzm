

import 'package:easyqzm/model/userperformance.dart';
import 'package:easyqzm/model/userupdate.dart';
import 'package:easyqzm/service/storage_service.dart';
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
  final StorageService storageService = StorageService();


  ApiService() {

  }

  Future<String?> getToken() async {
    String? token = await storageService.retrieve(key: 'jwtToken');
    return token;
  }
  final String apiUrl = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/api/'  // Production
      : 'http://localhost:7860/api/';  // Local

  final String authUrl = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/auth/'  // Production
      : 'http://localhost:7860/auth/';



  Future<User?> sendTokenToBackend(String tokenAccess, UserUpdate userUpdate) async {
    try {
      // Retrieve JWT token from secure storage
      String? token = await getToken();

      // Determine if it's a new user
      bool newUser = token == null;

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'jwtToken': token, // Send null if no token found
        'newUser': newUser,
      };

      print(requestBody);

      // Send POST request
      final response = await http.post(
        Uri.parse('${authUrl}google'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': tokenAccess != null ? 'Bearer $tokenAccess' : '',  // Add token if it's available
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Token sent successfully: $responseData');

        if (responseData.containsKey('jwtToken')) {
          // Save JWT token and user ID in secure storage
          await storageService.store(key: 'jwtToken', value: responseData['jwtToken']);
          await storageService.store(key: 'username', value: responseData['userId']);
          final User user = User(
            userId: responseData['userId'],
            emailId: responseData['emailId'],
            name: responseData['userId'],
            avatar: responseData['avtaar'],
            expertTopics: ["AI", "Cybersecurity", "Machine Learning"],
            achievements: ["Top Scorer", "AI Guru", "Fastest Learner"],
            isPermanent: false,
            articles: [],
          );
          String: var userStr = jsonEncode(user.toJson());
          await storageService.store(key: 'user', value:userStr);
          userUpdate.signedUser(user);
          return user;
          // Update username and verification status
         // UsernameService().updateUsername(responseData['userId']);
         // UsernameService().updateVerificationStatus(true);

          print('JWT Token saved and new user ID is ${responseData['userId']}');
        }
      } else {
        print('Error sending token: ${response.body}');
      }
    } catch (error) {
      print('Error sending token: $error');
    }
    return null;
  }

  // Fetch the token from localStorage


  // Fetch questions based on user input and difficulty
  Future<QuizResponse> fetchQuestions(String userInput, String difficulty) async {
    String? token = await getToken();
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
    String? token = await getToken();
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
    String? token = await getToken();

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
    String? token = await getToken();
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
    String? token = await getToken();
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
