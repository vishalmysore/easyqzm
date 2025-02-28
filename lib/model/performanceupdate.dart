import 'dart:async';
import 'dart:convert';

import 'package:easyqzm/model/user.dart';
import 'package:easyqzm/model/userperformance.dart';
import 'package:easyqzm/service/sse_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

import '../service/websocket.dart';

class PerformanceUpdate with ChangeNotifier {
  User? _user;
  UserPerformance? _performance;

  late final WebSocketService _wsService;
  late final Stream _scoreStream;
  late final StreamSubscription _scoreSubscription;
  List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => _notifications;
  void setPerformance(UserPerformance perf) {
    this._performance = perf;
    notifyListeners();
    _wsService = WebSocketService();  // Initialize WebSocket service
    _scoreStream = _wsService.connect('challenges'); // Connect to WebSocket stream

    _scoreSubscription = _scoreStream.listen((message) {
      print('challenge received update: $message');
      notifyListeners();
    });


  }

  void updated(SSEModel event) {
    String? notificationString = event.data;

    if (notificationString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(notificationString);

        if (data['action'] == 'newTestTaken') {
          String formattedNotification =
              "User ${data['userId']} took a new test on ${data['topics']} "
              "(${data['quizType']}). Score: ${data['currentScore']}";

          _addNotification(data);
        }
      } catch (e) {
        print("Error parsing notification: $e");
      }
    }
  }

  void _addNotification(Map<String, dynamic> notification) {
    _notifications.add(notification);
    notifyListeners();
  }
}