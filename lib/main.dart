import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:easyqzm/model/performanceupdate.dart';
import 'package:easyqzm/model/userupdate.dart';
import 'package:easyqzm/service/sse_service.dart';
import 'package:easyqzm/sharing/sharing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // Import uni_links for deep linking
import 'dart:async';
import 'package:flutter/services.dart';


import 'app/homescreen.dart';
import 'home_screen.dart'; // Import the HomeScreen
import 'model/question.model.dart';
import 'model/sharedtext.dart';
import 'search_screen.dart';
import 'sharing/sharing.dart';
import 'package:faker/faker.dart';
import 'package:universal_html/html.dart' hide Text,Navigator;
import 'model/user.dart';
import 'service/api_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SharedTextModel()),
        ChangeNotifierProvider(create: (_) => QuestionsModel()),
        ChangeNotifierProvider(create: (_) => UserUpdate()),
        ChangeNotifierProvider(create: (_) => PerformanceUpdate()),
      ],
      child: MyApp(),
    ),
  );


}

class MyApp extends StatefulWidget {

  const  MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final  platform = MethodChannel('com.easyqzm/sharing');
  String? sharedText;
  StreamSubscription? _sub;


  @override
   initState()  {
    super.initState();
    _extractUrlParameters();
    setUserandNotifier();
    //_initUniLinks(); // Initialize deep linking
    platform.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') {
        final String text = call.arguments;
        print("text here $text");
       updateSharedText(text);
      }
    });
  }

  Future<void> setUserandNotifier() async {
    await _setupUser();
    setNotifier();
  }

  Future<void> _setupUser() async{
    var faker = Faker();

    String? storedUsername = window.localStorage['username'];
    String? jwtToken = window.localStorage['jwtToken'];
    print(jwtToken);
    // If not, generate a new one and store it
    if((jwtToken == null) || await  isTokenExpired(jwtToken)) {
      storedUsername = faker.internet.userName();
      await createNewUser(storedUsername,context.read<UserUpdate>());
      window.localStorage['username'] = storedUsername;
      window.sessionStorage['username'] = storedUsername;
    } else {
      await  loadUserFromStorage(context.read<UserUpdate>());
    }

  }

  void setNotifier() {
    SSEService _sseService = SSEService();
    _sseService.connect(context.read<PerformanceUpdate>());
  }

  Future<bool> isTokenExpired(String? token) async {
    if (token == null) {
      return true; // Token is null, consider it expired
    }

    try {
      // Decode the JWT token
      final jwt = JWT.decode(token);

      // Extract the 'exp' claim (expiration time)
      final exp = jwt.payload['exp'];

      if (exp == null) {
        return true; // No expiration claim, consider it expired
      }

      // Convert 'exp' to DateTime
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);

      // Compare with current time
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true; // Error decoding token, consider it expired
    }
  }
  void _extractUrlParameters() {
    // Access the current URI
    Uri currentUri = Uri.base;

    // Retrieve query parameters
    Map<String, String> queryParams = currentUri.queryParameters;

    // Extract the 'data' parameter
    String? dataParam = queryParams['data'];
    String? referringUrl = document.referrer;
    String? urlParam = queryParams['url'];
    if (dataParam != null) {
      try {
        // Decode the JSON data if necessary
        Map<String, dynamic> data = jsonDecode(dataParam);
        // Update the sharedText with the extracted data
        setState(() {
          sharedText = data['articleUrl'];
        });
      } catch (e) {
        print('Error decoding JSON: $e');
      }
    }else
    if (referringUrl != null) {
       updateSharedText(referringUrl);
    } else {
      if(urlParam != null) {
        updateSharedText(urlParam);
      }
    }
  }
  void updateSharedText(String text) {
  //  final sharedTextModel = context.read<SharedTextModel>();
  //  sharedTextModel.updateSharedText(text);
    print('shared text here in update $text');

    sharedText=text;
    // Remove all previous screens and navigate to the new one
    final sharedTextModel = context.read<SharedTextModel>();
    sharedTextModel.updateSharedText(text);
  }

  // Initialize deep linking and capture the URL


  @override
  void dispose() {
    _sub?.cancel(); // Clean up the subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Check if there's a shared URL, and navigate to ShareUrlScreen if present
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'EasyQz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  MyHomePage(title: 'AI Powered Education'),

    );
  }
}


