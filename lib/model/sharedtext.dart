import 'package:flutter/material.dart';
class SharedTextModel extends ChangeNotifier {
  String _sharedText = '';

  String get sharedText => _sharedText;

  void updateSharedText(String newText) {
    print("received $newText");
    _sharedText = newText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();  // Ensure this runs *after* the build phase
    });
  }
}
