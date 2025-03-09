import 'package:flutter/cupertino.dart';

class TokenProvider with ChangeNotifier {
  bool _isTokenExpired = false;

  bool get isTokenExpired => _isTokenExpired;

  setTokenExpired(bool value) {
    if (_isTokenExpired != value) {
      _isTokenExpired = value;
      notifyListeners();
    }
  }
}