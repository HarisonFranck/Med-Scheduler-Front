import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Espace_Client/view/BienvenuePage.dart';
import 'package:provider/provider.dart';
import 'AuthProvider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:med_scheduler_front/AuthProviderUser.dart';
import 'AppLifecycleManager.dart';
import 'package:med_scheduler_front/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'FirebaseApi.dart';



void main()async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initFireBase();
  await FirebaseApi().initPushForegroundNotif();
  await FirebaseApi().initLocalNotif();
  AppLifecycleManager().startListening();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderUser()),
        // D'autres providers peuvent être ajoutés ici selon vos besoins.
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Scheduler',


      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:BienvenuePage(),
    );
  }
}