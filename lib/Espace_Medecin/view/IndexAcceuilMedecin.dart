import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'Agenda.dart';
import 'MedecinDetails.dart';
import 'package:icons_plus/icons_plus.dart';
import 'NotificationMedecin.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'ListAppointment.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Repository/MedecinRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:badges/badges.dart' as b;
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexAcceuilMedecin extends StatefulWidget {
  const IndexAcceuilMedecin({super.key});

  @override
  _IndexAcceuilMedecinState createState() => _IndexAcceuilMedecinState();
}

class _IndexAcceuilMedecinState extends State<IndexAcceuilMedecin> {
  late AuthProvider authProvider;
  late String token;
  late AuthProviderUser authProviderUser;
  String baseUrl = UrlBase().baseUrl;

  BaseRepository? baseRepository;
  MedecinRepository? medecinRepository;
  Utilities? utilities;

  List<Map<String, dynamic>>? _pages;
  int _selectedPageIndex = 0;
  int onPageIdex = 0;

  late Future<Utilisateur> user;
  Utilisateur? utilisateur;
  Medecin? medecin;
  int idUser = 0;
  int nbAppoint = 0;

  RemoteMessage? theMessage;

  String notifMessage = "";
  bool isAgendaTaped = false;
  bool isTaped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    refreshNotificationBadge();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      setState(() {
        theMessage = message;
      });
      if (theMessage != null) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        notifMessage =
            "${theMessage!.notification!.title},${theMessage!.notification!.body},${theMessage!.sentTime}";
        sharedPreferences.setString("notificationMedecin", notifMessage);
      }
    });
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);
    token = authProvider.token;

    Map<String, dynamic> payload = Jwt.parseJwt(token);

    idUser = payload['id'];

    user = baseRepository!.getUser(idUser);
    userGetted();
  }

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

  void userGetted() async {
    if (utilisateur == null) {
      utilisateur = await user;

      authProviderUser.setUser(utilisateur!);
    }
    // Maintenant que l'utilisateur est récupéré, initialisez les pages
    initPages();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Traitez le message ici
      setState(() {
        nbAppoint = 1;
      });
    });
  }

  void initPages() {
    if (utilisateur != null) {
      _pages = [
        {
          'page': Agenda(),
        },
        {
          'page': ListAppointment(),
        },
        {
          'page': NotificationMedecin(),
        },
        {
          'page': MedecinDetails(),
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
    medecinRepository =
        MedecinRepository(context: context, utilities: utilities!);
  }

  void _selectPage(int index) {
    /* if (index == 0 || index == 1 || index == 3) {
      notifMessage = "";
      isTaped = false;
    }
    if (index == 1 || index == 2 || index == 3) {
      isAgendaTaped = false;
    }*/

    setState(() {
      _selectedPageIndex = index;
    });
  }

  void refreshNotificationBadge() {
    setState(() {
      isAgendaTaped = false;
      isTaped = false;
      notifMessage = "";
    });
  }

  int nb = 0;
  bool badgeShow = false;
  @override
  Widget build(BuildContext context) {
    if (utilisateur != null) {
      filterAppointments(
              medecinRepository!.getAllAppointmentByMedecin(utilisateur!))
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
            BottomNavigationBarItem(
              activeIcon: b.Badge(
                showBadge: false,
                position: b.BadgePosition.topEnd(top: -2, end: -6),
                badgeAnimation: const b.BadgeAnimation.scale(),
                badgeStyle: const b.BadgeStyle(
                  elevation: 4,
                  badgeColor: Colors.redAccent,
                ),
                // Ajustez cette valeur selon vos besoins
                child: const Icon(
                  FontAwesome.calendar,
                  color: Color.fromARGB(230, 20, 20, 90),
                  size: 22,
                ),
              ),
              icon: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectPage(0);

                    isAgendaTaped = true;
                  });
                },
                child: b.Badge(
                  onTap: () {
                    setState(() {
                      _selectPage(0);

                      isAgendaTaped = true;
                      didChangeDependencies();
                    });
                  },
                  showBadge:
                      (!isAgendaTaped && notifMessage != "") ? true : false,
                  position: b.BadgePosition.topEnd(top: -4, end: -8),
                  badgeAnimation: const b.BadgeAnimation.scale(),
                  badgeStyle: const b.BadgeStyle(
                    elevation: 4,
                    badgeColor: Color.fromARGB(230, 20, 20, 90),
                  ),
                  // Ajustez cette valeur selon vos besoins
                  child: const Icon(
                    FontAwesome.calendar,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
              label: 'Agenda',
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
                    didChangeDependencies();
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
