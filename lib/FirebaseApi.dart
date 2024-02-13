import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:convert';

class FirebaseApi{

  final firebaseMessaging = FirebaseMessaging.instance;

  final androidChannel = AndroidNotificationChannel("notif", "Notif",  playSound: true,enableVibration: true,showBadge: true,enableLights: true,importance: Importance.high,);

  final flutterLocalNotif = FlutterLocalNotificationsPlugin();

  Future<void> initFireBase()async{
    await firebaseMessaging.requestPermission();

    final token = await firebaseMessaging.getToken();

    print("TOKEN FIREBASE: ${token.toString()}");

  }


  Future initPushForegroundNotif()async{

    firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;

      if(notif==null)return;

      flutterLocalNotif.show(notif.hashCode,notif.title,notif.body, NotificationDetails(
        android: AndroidNotificationDetails(androidChannel.id, androidChannel.name,importance: Importance.high,enableVibration: true,playSound: true,channelDescription: androidChannel.description,icon: '@drawable/ic_launcher',),
      ),
        payload: jsonEncode(message.toMap())
      );

    });
  }


  Future initLocalNotif()async{
    const android = AndroidInitializationSettings('@drawable/ic_launcher');

    const settings = InitializationSettings(android: android);

    await flutterLocalNotif.initialize(settings);

      final platform = flutterLocalNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await platform?.createNotificationChannel(androidChannel);
  }

}
