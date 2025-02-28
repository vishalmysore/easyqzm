import 'dart:async';

import 'package:easyqzm/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../service/websocket.dart';

class UserUpdate with ChangeNotifier {
  User? _user;
  late final WebSocketService _wsService;
  late final Stream _scoreStream;
  late final StreamSubscription _scoreSubscription;

  int _notificationCount = 0;

  User? get user => _user;
  int get notificationCount => _notificationCount;

  void setUser(User? newUser) {
    _user = newUser;

    _wsService = WebSocketService();  // Initialize WebSocket service
    _scoreStream = _wsService.connect('score'); // Connect to WebSocket stream

    _scoreSubscription = _scoreStream.listen((message) {
      print('Score update: $message');
      _notificationCount++;
      notifyListeners();

    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();  // Ensure this runs *after* the build phase
    });
  }

  @override
  void dispose() {
    _scoreSubscription.cancel(); // Cleanup listener
    super.dispose();
  }

  void clearNotifications() {
    _notificationCount = 0;
    notifyListeners();
  }
}
