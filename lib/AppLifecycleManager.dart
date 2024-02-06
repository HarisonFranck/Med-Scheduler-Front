import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  Timer? _timer;

  void startListening() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stopListening() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _startTimer();
    } else if (state == AppLifecycleState.resumed) {
      _cancelTimer();
    }
  }

  void _startTimer() {
    _timer = Timer(Duration(minutes: 50), () {
// Afficher un dialogue ou fermer l'application selon vos besoins
      stopApp();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

// Fonction pour arrêter l'application
  void stopApp() {
    SystemNavigator.pop();
  }
}
