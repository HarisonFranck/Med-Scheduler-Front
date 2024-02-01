import 'Utilisateur.dart';
import 'package:flutter/material.dart';

class AuthProviderUser with ChangeNotifier {
  Utilisateur? _utilisateur;
  bool _isLoggedIn = false;

  Utilisateur get utilisateur => _utilisateur!;
  bool get isLoggedIn => _isLoggedIn;

  void setUser(Utilisateur user) {
    _utilisateur = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _utilisateur = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
