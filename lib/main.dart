import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:easyqzm/model/performanceupdate.dart';
import 'package:easyqzm/model/userupdate.dart';
import 'package:easyqzm/service/sse_service.dart';
import 'package:easyqzm/service/storage_service.dart';
import 'package:easyqzm/sharing/sharing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // Import uni_links for deep linking
import 'dart:async';
import 'package:flutter/services.dart';
import '../util/debug.dart' as debug;
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
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
  final storageService = StorageService();
  String? sharedText;
  StreamSubscription? _sub;


  @override
   initState()  {
    super.initState();
    Icon(CupertinoIcons.add);
    _extractUrlParameters();
    setUserandNotifier();
    //_initUniLinks(); // Initialize deep linking
    platform.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') {
        final String text = call.arguments;
        debug.d("text here $text");
       updateSharedText(text);
      }
    });
  }

  Future<void> setUserandNotifier() async {
    String? token = await _setupUser();
    setNotifier(token!);
  }

  Future<String?> _setupUser() async{
    var faker = Faker();

    String? storedUsername = await storageService.retrieve(key: 'username');
    String? jwtToken = await storageService.retrieve(key:'jwtToken');
    debug.d(jwtToken.toString());
    // If not, generate a new one and store it
    if((jwtToken == null) || await  isTokenExpired(jwtToken)) {
      storedUsername = faker.internet.userName();
      await createNewUser(storedUsername,context.read<UserUpdate>());
      await storageService.store(key: 'username', value: storedUsername);

    } else {
      await  loadUserFromStorage(context.read<UserUpdate>());
    }
    jwtToken = await storageService.retrieve(key:'jwtToken');
    return jwtToken;

  }

  void setNotifier(String tokenStr) {
    SSEService _sseService = SSEService(token: tokenStr);


    try {
      _sseService.connect(context.read<PerformanceUpdate>(),tokenStr);
      debug.d(" Called _sseService.connect()");
    } catch (error, stackTrace) {
      debug.d(" Exception in setNotifier: $error");
      debug.d(stackTrace.toString());
    }


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
    if(urlParam != null) {
      updateSharedText(urlParam);
    } else
    if (referringUrl != null) {
       updateSharedText(referringUrl);
    }

  }
  void updateSharedText(String text) {
  //  final sharedTextModel = context.read<SharedTextModel>();
  //  sharedTextModel.updateSharedText(text);
    debug.d('shared text here in update $text');

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
      home:  MyHomePage(title: 'AI Deep Research Agent for Education'),

    );
  }
}


