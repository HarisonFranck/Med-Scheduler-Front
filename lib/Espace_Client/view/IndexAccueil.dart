import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'ListAppointment.dart';
import 'AccueilPatient.dart';
import 'PatientDetails.dart';
import 'package:icons_plus/icons_plus.dart';
import 'NotificationPatient.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:med_scheduler_front/Models/AuthProviderNotif.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:badges/badges.dart' as b;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexAccueil extends StatefulWidget {
  @override
  _IndexAccueilState createState() => _IndexAccueilState();
}

class _IndexAccueilState extends State<IndexAccueil> {
  late AuthProvider authProvider;
  late String token;
  late AuthProviderUser authProviderUser;
  late AuthProviderNotif authProviderNotif;

  bool isTaped = false;

  String baseUrl = UrlBase().baseUrl;

  BaseRepository? baseRepository;
  UserRepository? userRepository;
  Utilities? utilities;

  String notifMessage = "";

  List<Map<String, dynamic>>? _pages;
  int _selectedPageIndex = 0;
  int onPageIdex = 0;

  late Future<Utilisateur> user;
  Utilisateur? utilisateur;
  int idUser = 0;

  Future<List<CustomAppointment>> filterAppointments(
      Future<List<CustomAppointment>> appointmentsFuture) async {
    List<CustomAppointment> allAppointments = await appointmentsFuture;

    // Filtrer les rendez-vous avec startAt égal à DateTime.now()
    List<CustomAppointment> filteredAppointments = allAppointments
        .where((appointment) =>
            utilities!.isToday(appointment.startAt, appointment.timeStart))
        .toList();

    return filteredAppointments;
  }

  RemoteMessage? theMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      setState(() {
        theMessage = message;
      });
      if (theMessage != null) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        notifMessage =
            "${message.notification!.title},${theMessage!.notification!.body},${theMessage!.sentTime}";
        sharedPreferences.setString("notificationPatient", notifMessage);
      }
    });

    authProvider = Provider.of<AuthProvider>(context);
    token = authProvider.token;

    authProviderUser = Provider.of<AuthProviderUser>(context);
    authProviderNotif = Provider.of<AuthProviderNotif>(context);

    Map<String, dynamic> payload = Jwt.parseJwt(token);

    idUser = payload['id'];

    user = baseRepository!.getUser(idUser);
    userGetted();
  }

  void userGetted() async {
    if (utilisateur == null) {
      utilisateur = await user;
      authProviderUser.setUser(utilisateur!);
    }
    // Maintenant que l'utilisateur est récupéré, initialisez les pages
    initPages();
  }

  void initPages() {
    if (authProviderUser.utilisateur != null) {
      _pages = [
        {
          'page': AccueilPatient(),
        },
        {
          'page': ListAppointment(),
        },
        {
          'page': NotificationPatient(),
        },
        {
          'page': PatientDetails(),
        }
      ];

      // Une fois les pages initialisées, forcez une reconstruction de l'interface utilisateur
      // pour refléter les changements
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
    userRepository = UserRepository(context: context, utilities: utilities!);
  }

  void _selectPage(int index) {
    if (index != 2) {
      notifMessage = "";
      isTaped = false;
    }
    setState(() {
      _selectedPageIndex = index;
    });
  }

  int nb = 0;
  @override
  Widget build(BuildContext context) {
    if (utilisateur != null) {
      filterAppointments(
              userRepository!.getAllAppointmentByPatient(utilisateur!))
          .then((value) {
        setState(() {
          nb = value.length;
        });
      });
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        body: (utilisateur != null)
            ? _pages![_selectedPageIndex]['page']
            : Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  loadingWidget(),
                  const SizedBox(
                    height: 30,
                  ),
                  Text(
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.5), letterSpacing: 2),
                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                    textAlign: TextAlign.center,
                  )
                ],
              )),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 5,
          onTap: _selectPage,
          enableFeedback: true,
          unselectedItemColor: Colors.redAccent,
          selectedItemColor: const Color.fromARGB(230, 20, 20, 90),
          currentIndex: _selectedPageIndex,
          items: [
            const BottomNavigationBarItem(
              activeIcon: Icon(
                FontAwesome.house,
                color: Color.fromARGB(230, 20, 20, 90),
                size: 22,
              ),
              icon: Icon(
                FontAwesome.house,
                color: Colors.redAccent,
                size: 20,
              ),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.user_doctor,
                size: 20,
              ),
              label: 'Rendez-vous',
            ),
            BottomNavigationBarItem(
              activeIcon: b.Badge(
                onTap: () {},
                showBadge: false,
                position: b.BadgePosition.topEnd(top: -2, end: -3),
                badgeAnimation: const b.BadgeAnimation.scale(),
                badgeStyle: const b.BadgeStyle(
                  elevation: 4,
                  badgeColor: Colors.redAccent,
                ),
                // Ajustez cette valeur selon vos besoins
                child: const Icon(
                  Icons.notifications,
                  color: Color.fromARGB(230, 20, 20, 90),
                  size: 25,
                ),
              ),
              icon: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectPage(2);
                    isTaped = true;
                  });
                },
                child: b.Badge(
                  onTap: () {
                    setState(() {
                      isTaped = true;
                    });
                  },
                  showBadge: (notifMessage != "" && !isTaped) ? true : false,
                  position: b.BadgePosition.topEnd(top: -2, end: -2),
                  badgeAnimation: const b.BadgeAnimation.scale(),
                  badgeStyle: const b.BadgeStyle(
                    elevation: 4,
                    badgeColor: Color.fromARGB(230, 20, 20, 90),
                  ),
                  // Ajustez cette valeur selon vos besoins
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.redAccent,
                    size: 25,
                  ),
                ),
              ),
              label: 'Notification',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.user,
                size: 18,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget loadingWidget() {
    return Center(
        child: Container(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LoadingAnimationWidget.hexagonDots(
              color: Colors.redAccent, size: 120),
          Image.asset(
            'assets/images/logo2.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          )
        ],
      ),
    ));
  }
}
