import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProviderNotif with ChangeNotifier {
  RemoteMessage? _message;
  bool _isLoggedIn = false;

  RemoteMessage get message => _message!;
  bool get isLoggedIn => _isLoggedIn;

  void setNotif(RemoteMessage message) {
    _message = message;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _message = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
