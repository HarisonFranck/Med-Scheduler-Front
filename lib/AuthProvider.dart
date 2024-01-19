import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  late String _token;
  bool _isLoggedIn = false;

  String get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  void setToken(String token) {
    _token = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
// Réinitialiser le token et l'état d'authentification lors de la déconnexion
    _token = '';
    _isLoggedIn = false;
    notifyListeners();
  }
}
