import 'dart:async';

import 'package:easyqzm/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../util/debug.dart' as debug;
import '../service/websocket.dart';

class UserUpdate with ChangeNotifier {
  User? _user;
  late final WebSocketService _wsService;
  late final Stream _scoreStream;
  late final StreamSubscription _scoreSubscription;
  bool _signOut = false;
  int _notificationCount = 0;

  User? get user => _user;
  int get notificationCount => _notificationCount;
  bool get signOut => _signOut;
  void signedUser(User? newUser) async {
    _user = newUser;
    notifyListeners();
  }
  void signedOut(User? newUser) async {
    _user = newUser;
    _signOut = true;
    notifyListeners();
  }
  void setUser(User? newUser,String token) {
    _user = newUser;

    _wsService = WebSocketService();  // Initialize WebSocket service
    _scoreStream = _wsService.connect('score',token); // Connect to WebSocket stream

    _scoreSubscription = _scoreStream.listen((message) {
      debug.d('Score update: $message');
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
