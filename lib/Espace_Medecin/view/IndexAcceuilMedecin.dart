import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Medecin.dart';
//import 'Agenda.dart';
import 'Agenda.dart';
import 'MedecinDetails.dart';
import 'package:icons_plus/icons_plus.dart';
import 'NotificationMedecin.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/UrlBase.dart';
import 'ListAppointment.dart';

class IndexAcceuilMedecin extends StatefulWidget {
  const IndexAcceuilMedecin({super.key});


  @override
  _IndexAcceuilMedecinState createState() => _IndexAcceuilMedecinState();
}

class _IndexAcceuilMedecinState extends State<IndexAcceuilMedecin> {

  late AuthProvider authProvider;
  late String token;
  String baseUrl = UrlBase().baseUrl;

  Future<Utilisateur> getUser(int id) async {
    final url = Uri.parse("${baseUrl}api/users/$id");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        Utilisateur user = Utilisateur.fromJson(jsonData);

        print('UTILISATEUR: ${user.lastName}');

        return user;
      } else {
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw Exception('-- Failed to load data. Error: $e');
    }
  }

  List<Map<String, dynamic>>? _pages;
  int _selectedPageIndex = 0;
  int onPageIdex = 0;

  late Future<Utilisateur> user;
  Utilisateur? utilisateur;
  Medecin? medecin;
  int idUser = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);
    token = authProvider.token;

    Map<String, dynamic> payload = Jwt.parseJwt(token);

    idUser = payload['id'];
    print('ID USER INDEXED: $idUser');

    user = getUser(idUser);
    userGetted();
  }

  void userGetted() async {
    utilisateur = await user;
    medecin = Medecin(id: utilisateur!.id, roles: utilisateur!.roles, speciality: utilisateur!.speciality, lastName: utilisateur!.lastName, firstName: utilisateur!.firstName, userType: utilisateur!.userType, phone: utilisateur!.phone, email: utilisateur!.email, address: utilisateur!.address, center: utilisateur!.center, createdAt: utilisateur!.createdAt, city: utilisateur!.city);

    print('USER OO: ${medecin!.lastName}');

    // Maintenant que l'utilisateur est récupéré, initialisez les pages
    initPages();
  }

  void initPages() {
    if (utilisateur != null) {
      _pages = [
        {
          'page': Agenda(medecin: medecin!),
        },
        {
          'page': ListAppointment(user: utilisateur!),
        },
        {
          'page': NotificationMedecin(user: utilisateur!),
        },
        {
          'page': MedecinDetails(user: utilisateur!),
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
    print('INIT STATE');

    //userGetted();

    super.initState();
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });

    print('WIDGET: ${_pages![_selectedPageIndex]['page']}');
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color.fromARGB(1000, 238, 239, 244),
        body: (utilisateur != null)
            ? _pages![_selectedPageIndex]['page']
            : const Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.redAccent,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text(
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
          selectedItemColor: Color.fromARGB(230, 20, 20, 90),
          currentIndex: _selectedPageIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(FontAwesome.calendar),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.user_doctor,
                size: 30,
              ),
              label: 'Rendez-vous',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications,
                size: 35,
              ),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesome.user,
                size: 28,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
