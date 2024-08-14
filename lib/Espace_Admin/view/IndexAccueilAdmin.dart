import 'package:flutter/material.dart';
import 'AccueilAdmin.dart';
import 'AdminDetails.dart';
import 'package:icons_plus/icons_plus.dart';
import 'NotificationAdmin.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'SearchMedecin.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';

class IndexAccueilAdmin extends StatefulWidget {
  @override
  _IndexAccueilAdminState createState() => _IndexAccueilAdminState();
}

class _IndexAccueilAdminState extends State<IndexAccueilAdmin> {
  late AuthProvider authProvider;
  late AuthProviderUser authProviderUser;
  late String token;
  String baseUrl = UrlBase().baseUrl;

  BaseRepository? baseRepository;
  Utilities? utilities;

  Utilisateur? userPassed;

  List<Map<String, dynamic>>? _pages;
  int _selectedPageIndex = 0;
  int onPageIdex = 0;

  late Future<Utilisateur> user;
  Utilisateur? utilisateur;
  int idUser = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);
    authProviderUser = Provider.of<AuthProviderUser>(context);
    token = authProvider.token;

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
          'page': AccueilAdmin(),
        },
        {
          'page': SearchMedecin(),
        },
        {
          'page': NotificationAdmin(),
        },
        {
          'page': AdminDetails(),
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
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color.fromARGB(1000, 238, 239, 244),
        body: (authProviderUser.isLoggedIn)
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
                          color: Colors.black.withOpacity(0.5),
                          letterSpacing: 2),
                      'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 5,
          onTap: _selectPage,
          enableFeedback: true,
          unselectedItemColor: Colors.redAccent,
          selectedItemColor: Color.fromARGB(230, 20, 20, 90),
          currentIndex: _selectedPageIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.house,
                size: 17,
              ),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.user_doctor,
                size: 20,
              ),
              label: 'Rendez-vous',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications,
                size: 25,
              ),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
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
