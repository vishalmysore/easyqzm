import 'dart:convert';

import 'package:easyqzm/model/userupdate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' hide Text,Navigator;
class User {
  final String userId;
  final String? emailId;
  final String name;
  final String avatar;
  final List<String> expertTopics;
  final List<String> achievements;
  final bool isPermanent;
  final List<dynamic> articles;

  User({
    required this.userId,
    this.emailId,
    required this.name,
    required this.avatar,
    required this.expertTopics,
    required this.achievements,
    required this.isPermanent,
    required this.articles,
  });

  // Convert the User object into a map (for sending in the POST request)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emailId': emailId,
      'name': name,
      'avatar': avatar,
      'expertTopics': expertTopics,
      'achievements': achievements,
      'isPermanent': isPermanent,
      'articles': articles,
    };
  }
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      emailId: json['emailId'],
      name: json['name'],
      avatar: json['avatar'],
      expertTopics: List<String>.from(json['expertTopics']),
      achievements: List<String>.from(json['achievements']),
      isPermanent: json['isPermanent'],
      articles: List<String>.from(json['articles']),
    );
  }
}

Future<void> loadUserFromStorage(UserUpdate userUpdate) async {
  // Retrieve the JSON string from local storage
  String? userJson = window.localStorage['user'];

  if (userJson != null) {
    try {
      // Decode the JSON string into a map
      Map<String, dynamic> userMap = jsonDecode(userJson);

      // Create a User object from the map
      User user = User.fromJson(userMap);

      // Update the UserUpdate provider with the new User object
      userUpdate.setUser(user);
    } catch (e) {
      print('Error decoding user JSON: $e');
    }
  } else {
    print('No user data found in local storage.');
  }
}


Future<User> createNewUser(String username, UserUpdate userUpdte) async {
 final String apiUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:7860/api/',  // Default for local environment
  );


  // Generate user object
  final User user = User(
    userId: username,
    emailId: null,
    name: username,
    avatar: 'https://i.pravatar.cc/150?img=${(username.split('').fold(0, (acc, char) => acc + char.codeUnitAt(0)) % 70 + 1).toString()}',
    expertTopics: ["AI", "Cybersecurity", "Machine Learning"],
    achievements: ["Top Scorer", "AI Guru", "Fastest Learner"],
    isPermanent: false,
    articles: [],
  );

  // Sending HTTP POST request
  try {
    final response = await http.post(
      Uri.parse('${apiUrl}createNewTempUser'),  // Add the full endpoint path
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(user.toJson()),  // Send the user object as JSON
    );

    if (response.statusCode == 200) {

      String: var userStr = jsonEncode(user.toJson());
      window.localStorage['user'] =userStr;
      // Success, handle response if necessary
      final responseData = json.decode(response.body);
      String token = responseData['token'];
      // Store the token in localStorage
      window.localStorage['jwtToken'] = token;
      userUpdte.setUser(user);
      print("Token stored in localStorage: $token");
    } else {
      // Handle error response
      print('Failed to create user: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }

  return user;
}
