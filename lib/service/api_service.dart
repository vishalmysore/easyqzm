

import 'dart:math';

import 'package:easyqzm/model/userperformance.dart';
import 'package:easyqzm/service/sse_service.dart';
import 'package:faker/faker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';

import '../model/link.dart';
import '../model/performanceupdate.dart';
import '../model/question.dart';
import '../model/score.dart';
import '../model/story.dart';
import '../model/tokennotifier.dart';
import '../model/user.dart';
import '../model/userupdate.dart';
import '../util/debug.dart' as debug;
class ApiService {
  final String apiUrl = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/api/'  // Production
      : 'http://localhost:7860/api/';  // Local

  final String authUrl = kReleaseMode
      ? 'https://vishalmysore-easyqserver.hf.space/auth/'  // Production
      : 'http://localhost:7860/auth/';
  String? token;
  final TokenProvider tokenProvider = TokenProvider();

  Future<http.Response?> sendContactUsData(Map<String, dynamic> contactUsData) async {
    await fetchToken();
    try {
      final response = await http.post(
          Uri.parse('${apiUrl}contactUs'), // Endpoint for contact-us

        headers: {
      'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : '',  // Add token if it's available
        },
        body: json.encode(contactUsData),
      );

     return response;
    } catch (e) {
      print('Error sending data: $e');
      return null; // Return false on error
    }
  }

  Future<Story?> fetchStory(String category) async {
    await fetchToken();
    List<String> storyTypes = ["horror", "comedy", "thriller", "drama", "history", "realistic"];
    List<String> mathTypes = ["algebra", "geometry", "trigonometry", "calculus", "exponents", "percentage"];
    List<String> scienceTypes = ["chemistry", "periodic table", "gravity", "speed", "volume and weight", "solar system"];
    List<String> historyTypes = ["ancient civilizations", "medieval era", "world wars", "industrial revolution", "modern history", "renaissance"];
    List<String> geographyTypes = ["continents and oceans", "mountains and rivers", "climate and weather", "maps and navigation", "natural disasters", "ecosystems"];
    List<String> civicsTypes = ["constitution", "fundamental rights", "government branches", "elections and democracy", "law and justice", "public administration"];
    List<String> indoorSports = [
      "badminton",
      "table tennis",
      "chess",
      "carrom",
      "bowling",
      "snooker",
      "squash",
      "fencing",
      "gymnastics",
      "boxing",
      "weightlifting"
    ];
    List<String> outdoorSports = [
      "football",
      "cricket",
      "basketball",
      "tennis",
      "golf",
      "hockey",
      "rugby",
      "baseball",
      "cycling",
      "skiing",
      "track and field",
      "archery",
      "rowing"
    ];

    String? randomSubcategory;
    if (category == "stories") {
      randomSubcategory = storyTypes[Random().nextInt(storyTypes.length)];
    } else if (category == "math") {
      randomSubcategory = mathTypes[Random().nextInt(mathTypes.length)];
    } else if (category == "science") {
      randomSubcategory = scienceTypes[Random().nextInt(scienceTypes.length)];
    } else if (category == "history") {
      randomSubcategory = historyTypes[Random().nextInt(historyTypes.length)];
    } else if (category == "geography") {
      randomSubcategory = geographyTypes[Random().nextInt(geographyTypes.length)];
    } else if (category == "civics") {
      randomSubcategory = civicsTypes[Random().nextInt(civicsTypes.length)];
    } else if (category == "indoorSports") {
      randomSubcategory = indoorSports[Random().nextInt(geographyTypes.length)];
    } else if (category == "outdoorSports") {
      randomSubcategory = outdoorSports[Random().nextInt(civicsTypes.length)];
    }else {
      randomSubcategory = "Unknown Category";
    }
    try {
      final response = await http.get(Uri.parse('${apiUrl}getStory?category=${category}&storyType=$randomSubcategory'),headers: {

        'Authorization': token != null ? 'Bearer $token' : '',  // Add token if it's available
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        return Story.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching story: $e');
      return null;
    }
  }

  Future<Story?> fetchNews() async {
    await fetchToken();
    List<String> storyTypes = ["world affairs", "sports", "cricket", "economy", "trading", "India","technology"];

    // Select a random story type
    String randomStoryType = storyTypes[Random().nextInt(storyTypes.length)];
    try {
      final response = await http.get(Uri.parse('${apiUrl}getNews?category=news&storyType=$randomStoryType'),headers: {

        'Authorization': token != null ? 'Bearer $token' : '',  // Add token if it's available
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        return Story.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching story: $e');
      return null;
    }
  }
  Future<User?> sendTokenToBackend(String tokenAccess, UserUpdate userUpdate) async {
    try {
      // Retrieve JWT token from secure storage
      await fetchToken();

      // Determine if it's a new user
      bool newUser = token == null;

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'jwtToken': token, // Send null if no token found
        'newUser': newUser,
      };

      debug.d(requestBody.toString());

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
        debug.d('Token sent successfully: $responseData');

        if (responseData.containsKey('jwtToken')) {
          // Save JWT token and user ID in secure storage
          await storageService.store(key: 'jwtToken', value: responseData['jwtToken']);
          await storageService.store(key: 'username', value: responseData['userId']);
          final User user = User(
            userId: responseData['userId'],
            emailId: responseData['emailid'],
            name: responseData['userId'],
            avatar: responseData['avtaar'],
            expertTopics: ["AI", "Cybersecurity", "Machine Learning"],
            achievements: ["Top Scorer", "AI Guru", "Fastest Learner"],
            isPermanent: true,
            articles: [],
          );
          String: var userStr = jsonEncode(user.toJson());
          await storageService.store(key: 'user', value:userStr);
          userUpdate.signedUser(user);
          return user;
          // Update username and verification status
         // UsernameService().updateUsername(responseData['userId']);
         // UsernameService().updateVerificationStatus(true);

          debug.d('JWT Token saved and new user ID is ${responseData['userId']}');
        }
      } else {
        debug.d('Error sending token: ${response.body}');
      }
    } catch (error) {
      debug.d('Error sending token: $error');
    }
    return null;
  }



  // Fetch the token from localStorage
  Future<void> fetchToken() async {
    // Only fetch token if it's not already set
    token ??= await storageService.retrieve(key: "jwtToken");
  }

  // Fetch questions based on user input and difficulty
  Future<QuizResponse> fetchQuestions(String userInput, String difficulty) async {
    await fetchToken();
    debug.d("Token stored in fetching localStorage: $token");
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
      throw Exception("Please refresh the page or login again");
    }
  }





  Future<UserPerformance?> fetchUserPerformance() async {
    await fetchToken();
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
        debug.d('Failed to load user performance: ${response.statusCode}');
        return null; // Return null in case of an error
      }
    } catch (e) {
      handleError();
      throw Exception("Please refresh the page or login again"); // Handle exceptions
    }
  }

  void handleError() {
    tokenProvider.setTokenExpired(true);
  }

  Future<void> submitScore(Score score) async {
    await fetchToken();

    try {
      final response = await http.post(
        Uri.parse('${apiUrl}updateResults'),
        headers: {'Content-Type': 'application/json','Authorization': token != null ? 'Bearer $token' : '', },
        body: jsonEncode(score.toJson()),
      );

      if (response.statusCode == 200) {
        debug.d('Score submitted successfully');
      } else {
        debug.d('Failed to submit score: ${response.body}');
      }
    } catch (e) {
      handleError();
      throw Exception("Please refresh the page or login again");
    }
  }


  Future<List<Link>> getTrendingLastHour() async {
    await fetchToken();
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
      handleError();
      throw Exception("Please refresh the page or login again");
    }
  }


  Future<List<Link>> getTrendingLastAll() async {
    await fetchToken();
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
      throw Exception("Please refresh the page or login again");
    }
  }
}
