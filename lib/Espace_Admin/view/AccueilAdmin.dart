import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:med_scheduler_front/Specialite.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/main.dart';
import 'dart:io';
import 'package:med_scheduler_front/Centre.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'MedecinDetails.dart';

class AccueilAdmin extends StatefulWidget {
  final Utilisateur user;

  AccueilAdmin({required this.user});

  @override
  _AccueilAdminState createState() => _AccueilAdminState();
}

class _AccueilAdminState extends State<AccueilAdmin> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyUpdMed = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyUpdSpec = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyUpdCenter = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyAddCenter = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyAddSpec = GlobalKey<FormState>();

  late AuthProvider authProvider;
  late String token;
  late Future<List<Medecin>> medecinsFuture;
  late Future<List<Specialite>> specialiteFuture;
  late Future<List<Centre>> centerFuture;

  String baseUrl = UrlBase().baseUrl;

  bool dataLoaded = false;

  List<String> strChoice = ["Specialite", "Centre", "Medecin"];

  String currentChoice = "Specialite";

  Specialite? spec;

  List<Specialite> listSpec = [];

  Future<void> getAllAsync() async {
    medecinsFuture = getAllMedecin();
    specialiteFuture = getAllSpecialite();
    centerFuture = getAllCenter();
  }

  void getAll() {
    getAllSpecialite().then((value) => {
          setState(() {
            listSpec = value;
          })
        });
  }

  void ReInitDataSpec() {
    specController.text = "";
    specDescController.text = "";
  }

  void ReInitDataCenter() {
    centerController.text = "";
    centerDescController.text = "";
  }

  void ReInitDataMedecin() {
    nomController.text = "";
    prenomController.text = "";
    spec = null;
    addresseController.text = "";
    emailController.text = "";
    villeController.text = "";
    phoneController.text = "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getAllAsync();
      getAll();
      if (mounted) {
        setState(() {
          dataLoaded = true;
        });
      }
    });
  }

  Future<List<Medecin>> getAllMedecin() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    // Définir l'URL de base
    Uri url = Uri.parse("${baseUrl}api/doctors?page=1");

    print('URI: $url');

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print('STATUS CODE MEDS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Medecin.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
          '-- Erreur d\'obtention des données\n vérifier votre connexion internet. Code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print(' -- E: $e --\n STACK: $stackTrace');
      throw e;
    }
  }

  Future<List<Centre>> getAllCenter() async {
    final url = Uri.parse("${baseUrl}api/centers?page=1");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Centre.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {
      //print('Error: $e \nStack trace: $stackTrace');
      throw Exception(
          '-- Erreur de connexion.\n Veuillez vérifier votre connexion internet !');
    }
  }

  Future<List<Specialite>> getAllSpecialite() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;
    final url = Uri.parse("${baseUrl}api/specialities?page=1");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print('STATUS CODE SPECS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Specialite.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {
      //print('Error: $e \nStack trace: $stackTrace');
      throw Exception(
          '-- Erreur de connexion.\n Veuillez vérifier votre connexion internet !');
    }
  }

  String abbreviateName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else {
      // Si le nom contient plusieurs mots
      String firstName = nameParts.first;

      if (nameParts.length > 1) {
        // Si le prénom contient plus de deux mots, utiliser seulement le premier mot
        return "$firstName ${nameParts[1]}";
      } else {
        // Sinon, construire l'abréviation en prenant la première lettre du premier mot
        // et le nom complet du deuxième mot
        String lastName = nameParts.last;
        String abbreviation = "${firstName[0]}.$lastName";
        return abbreviation;
      }
    }
  }

  String limiterNombreMots(String texte) {
    // Séparez le texte en mots
    List<String> mots = texte.split(' ');

    // Vérifiez le nombre de mots
    if (mots.length <= 10) {
      // Retournez tout le texte s'il contient 10 mots ou moins
      return texte;
    } else {
      // Retournez les 10 premiers mots avec trois points de suspension
      String texteLimite = mots.take(10).join(' ');
      return '$texteLimite...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        body: (dataLoaded)
            ? Column(
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  Row(
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                  textAlign: TextAlign.center,
                                  textScaler: TextScaler.linear(1.3),
                                  'Bonjour,',
                                  style: TextStyle(
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                textAlign: TextAlign.center,
                                textScaler: TextScaler.linear(1.45),
                                'Administrateur',
                                style: TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(230, 20, 20, 90),
                                ),
                              ),
                            ],
                          )),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 15, top: 20),
                        child: Image.asset(
                          'assets/images/Medhome.png',
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ChipsChoice<String>.single(
                        choiceStyle: C2ChipStyle(
                          height: 50,
                          backgroundColor: Colors.white,
                          foregroundStyle: const TextStyle(fontSize: 17),
                          borderRadius: BorderRadius.circular(6),
                          checkmarkColor: const Color.fromARGB(230, 20, 20, 90),
                          borderColor: const Color.fromARGB(230, 20, 20, 90),
                          borderOpacity: 1,
                          borderStyle: BorderStyle.solid,
                          borderWidth: 2,
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 40),
                          foregroundColor:
                              const Color.fromARGB(230, 20, 20, 90),
                        ),
                        placeholderStyle: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.w700),
                        choiceItems: C2Choice.listFrom(
                            source: strChoice,
                            value: (i, v) => v,
                            label: (i, v) => v),
                        choiceCheckmark: true,
                        value: currentChoice,
                        padding: const EdgeInsets.all(10),
                        onChanged: (choice) {
                          setState(() {
                            currentChoice = choice;
                          });
                        }),
                  ),
                  if (currentChoice == "Specialite") ...[
                    Expanded(
                        flex: 3,
                        child: FutureBuilder<List<Specialite>>(
                          future: specialiteFuture,
                          builder: (context, specsSnapshot) {
                            if (specsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: ListView(
                                children: const [
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ));
                            } else if (specsSnapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${specsSnapshot.error}'),
                              );
                            } else {
                              List<Specialite> specs = specsSnapshot.data!;

                              if (specs.isEmpty) {
                                print('NOTHING');
                                return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 18,
                                        left: 18,
                                        top: 20,
                                        bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Container(
                                        height: 200,
                                        child: Card(
                                          elevation: 0.5,
                                          color: Colors.white,
                                          child: ListView(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20,
                                                    top: 10,
                                                    right: 50),
                                                child: Text(
                                                  'Acune specialite pour le moment',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.grey
                                                          .withOpacity(0.9),
                                                      letterSpacing: 2),
                                                ),
                                              ),
                                              const Opacity(
                                                opacity: 0.4,
                                                child: Divider(
                                                  thickness: 1,
                                                  indent: 20,
                                                  endIndent: 20,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const Spacer()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ));
                              }

                              return ListView.builder(
                                itemCount: specs.length,
                                itemBuilder: (context, index) {
                                  Specialite spec = specs[index];

                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18, left: 18, bottom: 10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: Container(
                                          height: 200,
                                          child: Card(
                                            elevation: 0.5,
                                            color: Colors.white,
                                            child: Column(
                                              children: [
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 30),
                                                      child: Text(
                                                        '${spec.label}',
                                                        style: TextStyle(
                                                            letterSpacing: 2,
                                                            fontSize: 16,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.8)),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Column(
                                                      children: [
                                                        if (spec
                                                            .users.isEmpty) ...[
                                                          IconButton(
                                                              onPressed: () {
                                                                confirmSuppressionSpec(
                                                                    spec);
                                                              },
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .redAccent,
                                                              ))
                                                        ],
                                                        IconButton(
                                                            onPressed: () {
                                                              ModifierSpecialite(
                                                                  spec);
                                                            },
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color: Colors
                                                                  .redAccent,
                                                            ))
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                const Spacer(),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10, right: 10),
                                                  child: Text(
                                                      '${(spec.description != null && spec.description != "") ? limiterNombreMots(spec.description!) : "Aucun description"}',
                                                      style: TextStyle(
                                                          letterSpacing: 2,
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.6))),
                                                ),
                                                const Opacity(
                                                  opacity: 0.4,
                                                  child: Divider(
                                                    thickness: 1,
                                                    indent: 20,
                                                    endIndent: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ));
                                },
                              );
                            }
                          },
                        ))
                  ] else if (currentChoice == "Centre") ...[
                    Expanded(
                        flex: 3,
                        child: FutureBuilder<List<Centre>>(
                          future: centerFuture,
                          builder: (context, centersSnapshot) {
                            if (centersSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: ListView(
                                children: const [
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ));
                            } else if (centersSnapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${centersSnapshot.error}'),
                              );
                            } else {
                              List<Centre> centers = centersSnapshot.data!;

                              if (centers.isEmpty) {
                                print('NOTHING');
                                return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 18,
                                        left: 18,
                                        top: 20,
                                        bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Container(
                                        height: 200,
                                        child: Card(
                                          elevation: 0.5,
                                          color: Colors.white,
                                          child: ListView(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20,
                                                    top: 10,
                                                    right: 50),
                                                child: Text(
                                                  'Acun Centre pour le moment',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.grey
                                                          .withOpacity(0.9),
                                                      letterSpacing: 2),
                                                ),
                                              ),
                                              const Opacity(
                                                opacity: 0.4,
                                                child: Divider(
                                                  thickness: 1,
                                                  indent: 20,
                                                  endIndent: 20,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const Spacer()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ));
                              }

                              return ListView.builder(
                                itemCount: centers.length,
                                itemBuilder: (context, index) {
                                  Centre centre = centers[index];

                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18, left: 18, bottom: 10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: Container(
                                          height: 200,
                                          child: Card(
                                            elevation: 0.5,
                                            color: Colors.white,
                                            child: Column(
                                              children: [
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 30),
                                                      child: Text(
                                                        '${centre.label}',
                                                        style: TextStyle(
                                                            letterSpacing: 2,
                                                            fontSize: 16,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.8)),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Column(
                                                      children: [
                                                        if (centre
                                                            .users.isEmpty) ...[
                                                          IconButton(
                                                              onPressed: () {
                                                                confirmSuppressionCentre(
                                                                    centre);
                                                              },
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .redAccent,
                                                              ))
                                                        ],
                                                        IconButton(
                                                            onPressed: () {
                                                              modifierCentre(
                                                                  centre);
                                                            },
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color: Colors
                                                                  .redAccent,
                                                            ))
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                const Opacity(
                                                  opacity: 0.4,
                                                  child: Divider(
                                                    thickness: 1,
                                                    indent: 20,
                                                    endIndent: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ));
                                },
                              );
                            }
                          },
                        ))
                  ] else if (currentChoice == "Medecin") ...[
                    Expanded(
                        flex: 3,
                        child: FutureBuilder<List<Medecin>>(
                          future: medecinsFuture,
                          builder: (context, medecinsSnapshot) {
                            if (medecinsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: ListView(
                                children: const [
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ));
                            } else if (medecinsSnapshot.hasError) {
                              return Center(
                                child:
                                    Text('Erreur: ${medecinsSnapshot.error}'),
                              );
                            } else {
                              List<Medecin> medecins = medecinsSnapshot.data!;

                              if (medecins.isEmpty) {
                                print('NOTHING');
                                return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 18,
                                        left: 18,
                                        top: 20,
                                        bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Container(
                                        height: 200,
                                        child: Card(
                                          elevation: 0.5,
                                          color: Colors.white,
                                          child: ListView(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20,
                                                    top: 10,
                                                    right: 50),
                                                child: Text(
                                                  'Merci de rechercher les médecins avec les options ci-dessus...',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.grey
                                                          .withOpacity(0.9),
                                                      letterSpacing: 2),
                                                ),
                                              ),
                                              const Opacity(
                                                opacity: 0.4,
                                                child: Divider(
                                                  thickness: 1,
                                                  indent: 20,
                                                  endIndent: 20,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const Spacer()
                                            ],
                                          ),
                                        ),
                                      ),
                                    ));
                              }

                              return ListView.builder(
                                itemCount: medecins.length,
                                itemBuilder: (context, index) {
                                  Medecin medecin = medecins[index];

                                  print(
                                      'APP MED: ${medecin.doctorAppointments}');

                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18, left: 18, bottom: 10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: Container(
                                          height: 200,
                                          child: Card(
                                            elevation: 0.5,
                                            color: Colors.white,
                                            child: Column(
                                              children: [
                                                const Spacer(),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                      child: Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(60),
                                                        ),
                                                        child: ((medecin.imageName !=
                                                                    null) &&
                                                                (File(medecin
                                                                        .imageName!)
                                                                    .existsSync()))
                                                            ? Image.file(File(
                                                                medecin
                                                                    .imageName!))
                                                            : Image.asset(
                                                                'assets/images/medecin.png',
                                                                fit:
                                                                    BoxFit.fill,
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    Column(
                                                      children: [
                                                        Text(
                                                          '${medecin.lastName[0]}.${abbreviateName(medecin.firstName)}',
                                                          style: const TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      1000,
                                                                      60,
                                                                      70,
                                                                      120),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ),
                                                        Text(
                                                          '${(medecin.speciality != null) ? medecin.speciality!.label : ""}',
                                                          style: const TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      1000,
                                                                      60,
                                                                      70,
                                                                      120),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300),
                                                        )
                                                      ],
                                                    ),
                                                    const Spacer(),
                                                    Column(
                                                      children: [
                                                        if ((medecin.doctorAppointments ==
                                                                null) ||
                                                            medecin
                                                                .doctorAppointments!
                                                                .isEmpty) ...[
                                                          IconButton(
                                                              onPressed: () {},
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .redAccent,
                                                              ))
                                                        ],
                                                        IconButton(
                                                            onPressed: () {
                                                              modifierMedecin(
                                                                  medecin);
                                                            },
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color: Colors
                                                                  .redAccent,
                                                            ))
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                const Opacity(
                                                  opacity: 0.4,
                                                  child: Divider(
                                                    thickness: 1,
                                                    indent: 20,
                                                    endIndent: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 15.0,
                                                            left: 10,
                                                            right: 10,
                                                            bottom: 15),
                                                    child: ElevatedButton(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStateProperty
                                                                .all(const Color
                                                                    .fromARGB(
                                                                    1000,
                                                                    60,
                                                                    70,
                                                                    120)),
                                                        shape:
                                                            MaterialStateProperty
                                                                .all(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0), // Définissez le rayon de la bordure ici
                                                          ),
                                                        ),
                                                        minimumSize:
                                                            MaterialStateProperty
                                                                .all(const Size(
                                                                    180.0,
                                                                    40.0)),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    MedecinDetails(
                                                                        user:
                                                                            medecin)));
                                                      },
                                                      child: const Text(
                                                        'Details',
                                                        textScaleFactor: 1.2,
                                                        style: TextStyle(
                                                          color: Color.fromARGB(
                                                              255,
                                                              253,
                                                              253,
                                                              253),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ));
                                },
                              );
                            }
                          },
                        ))
                  ]
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('CURRENT: $currentChoice');

            if (currentChoice == "Specialite") {
              AjouterSpecialite(context);
            } else if (currentChoice == "Centre") {
              AjouterCentre(context);
            } else {
              AjouterMedecin(context);
            }
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 35,
          ),
          backgroundColor: Colors.redAccent, //Color.fromARGB(230, 20, 20, 90),
        ),
      ),
    );
  }

  bool isClicked = false;
  FocusNode _focusNodeSpecDesc = FocusNode();
  FocusNode _focusNodeSpec = FocusNode();

  TextEditingController specController = TextEditingController();
  TextEditingController specDescController = TextEditingController();

  FocusNode _focusNodeCenterDesc = FocusNode();
  FocusNode _focusNodeCenter = FocusNode();

  TextEditingController centerController = TextEditingController();
  TextEditingController centerDescController = TextEditingController();

  TextEditingController modifCenterController = TextEditingController();
  TextEditingController modifCenterDescController = TextEditingController();

  void modifierCentre(Centre center) {
    modifCenterController.text = center.label;
    modifCenterDescController.text =
        (center.description != null) ? center.description! : "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Modifier un centre',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKeyUpdCenter,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Centre',
                    controller: modifCenterController,
                    focusNode: _focusNodeCenter,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer un nom de centre';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Description',
                    keyboardType: TextInputType.name,
                    controller: modifCenterDescController,
                    focusNode: _focusNodeCenterDesc,
                    validator: (value) {
                      // Ajoutez des validations supplémentaires si nécessaire
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_formKeyUpdCenter.currentState!.validate()) {
                              String nomCenter = modifCenterController.text;
                              String descCenter =
                                  modifCenterDescController.text;
                              if (nomCenter.isNotEmpty) {
                                Centre centre = Centre(
                                  id: center.id,
                                  type: 'Center',
                                  label: nomCenter,
                                  users: [],
                                  createdAt: DateTime.now(),
                                  description: descCenter,
                                );
                                updateCenter(centre);
                                Navigator.pop(context);
                              } else {
                                error("Veuillez compléter le champ 'Centre'. ");
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          scrollable: true,
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void AjouterCentre(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Ajouter un centre',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKeyAddCenter,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Centre',
                    controller: centerController,
                    keyboardType: TextInputType.text,
                    focusNode: _focusNodeCenter,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer un centre';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Description',
                    controller: centerDescController,
                    keyboardType: TextInputType.multiline,
                    focusNode: _focusNodeCenterDesc,
                    validator: (value) {
                      // Ajoutez des validations supplémentaires si nécessaire
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_formKeyAddCenter.currentState!.validate()) {
                              print('ADD CENTER');
                              String nomCenter = centerController.text;
                              String descCenter = centerDescController.text;
                              if (nomCenter.isNotEmpty) {
                                Centre centre = Centre(
                                  id: '',
                                  type: 'Center',
                                  label: nomCenter,
                                  users: [],
                                  createdAt: DateTime.now(),
                                  description: descCenter,
                                );
                                addCenter(centre);
                                Navigator.pop(context);
                                ReInitDataCenter();
                              } else {
                                error("Veuillez compléter le champ 'Centre'. ");
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          scrollable: true,
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void confirmSuppressionCentre(Centre centre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            'Confirmation',
            style: TextStyle(
                letterSpacing: 2,
                color: Colors.black.withOpacity(0.8),
                fontSize: 17),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Voulez-vous vraiment supprimer cette Centre: ${centre.label} ?',
            textScaleFactor: 1.5,
            style: TextStyle(color: Colors.black.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: Colors.redAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Confirmer',
                style: TextStyle(
                    color: Colors.green,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                deleteCenter(centre.id);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> deleteCenter(String idCenter) async {
    final url =
        Uri.parse("${baseUrl}api/centers/${extractLastNumber(idCenter)}");
    //final headers = {'Content-Type': 'application/merge-patch+json'};

    print('URL DELETE: $url');

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      final response = await http.delete(url, headers: headers);
      print(response.statusCode);
      print('RESP: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 204) {
          DeleteCenter();
        } else {
          // Gestion des erreurs HTTP
          error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  Future<void> addCenter(Centre centre) async {
    final url = Uri.parse("${baseUrl}api/centers");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(centre.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Centre déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          CreationCentre();
        } else {
          // Gestion des erreurs HTTP
          error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  Future<void> updateCenter(Centre centre) async {
    print('CENTER ID: ${centre.id}');

    final url =
        Uri.parse("${baseUrl}api/centers/${extractLastNumber(centre.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(centre.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Centre déja existant');
        } else {
          UpdateCenter();
        }
      } else {
        // Gestion des erreurs HTTP
        error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw e;
    }
  }

  void AjouterSpecialite(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Ajouter une spécialité',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKeyAddSpec,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Spécialité',
                    controller: specController,
                    keyboardType: TextInputType.text,
                    focusNode: _focusNodeSpec,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer une spécialité';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Description',
                    controller: specDescController,
                    keyboardType: TextInputType.multiline,
                    focusNode: _focusNodeSpecDesc,
                    validator: (value) {
                      // Ajoutez des validations supplémentaires si nécessaire
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_formKeyAddSpec.currentState!.validate()) {
                              print('ADD SPEC');
                              String nomSpec = specController.text;
                              String descSpec = specDescController.text;
                              if (nomSpec.isNotEmpty) {
                                Specialite newSpecialite = Specialite(
                                  id: '',
                                  type: "Speciality",
                                  label: nomSpec,
                                  description: descSpec,
                                  users: [],
                                  createdAt: DateTime.now(),
                                );
                                addSpecialite(newSpecialite);
                                Navigator.pop(context);
                                ReInitDataSpec();
                              } else {
                                error(
                                    "Veuillez compléter le champ 'Spécialité'. ");
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          scrollable: true,
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  TextEditingController modifSpecController = TextEditingController();
  TextEditingController modifSpecDescController = TextEditingController();

  void ModifierSpecialite(Specialite specialite) {
    modifSpecController.text = specialite.label;
    modifSpecDescController.text =
        (specialite.description != null) ? specialite.description! : "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Modifier une spécialité',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKeyUpdSpec,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Spécialité',
                    controller: modifSpecController,
                    keyboardType: TextInputType.text,
                    focusNode: _focusNodeSpec,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer une spécialité';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Description',
                    controller: modifSpecDescController,
                    keyboardType: TextInputType.multiline,
                    focusNode: _focusNodeSpecDesc,
                    validator: (value) {
                      // Ajoutez des validations supplémentaires si nécessaire
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_formKeyUpdSpec.currentState!.validate()) {
                              String nomSpec = modifSpecController.text;
                              String descSpec = modifSpecDescController.text;
                              if (nomSpec.isNotEmpty) {
                                Specialite newSpecialite = Specialite(
                                  id: specialite.id,
                                  type: "Speciality",
                                  label: nomSpec,
                                  users: [],
                                  description: descSpec,
                                  updatedAt: DateTime.now(),
                                );
                                updateSpecialite(newSpecialite);
                                Navigator.pop(context);

                              } else {
                                error(
                                    "Veuillez compléter le champ 'Spécialité'. ");
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          scrollable: true,
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void confirmSuppressionSpec(Specialite specialite) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            'Confirmation',
            style: TextStyle(
                letterSpacing: 2,
                color: Colors.black.withOpacity(0.8),
                fontSize: 17),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Voulez-vous vraiment supprimer cette specialité: ${specialite.label} ?',
            textScaleFactor: 1.5,
            style: TextStyle(color: Colors.black.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: Colors.redAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Confirmer',
                style: TextStyle(
                    color: Colors.green,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                deleteSpecialite(specialite.id);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> deleteSpecialite(String idSpec) async {
    final url =
        Uri.parse("${baseUrl}api/specialities/${extractLastNumber(idSpec)}");
    //final headers = {'Content-Type': 'application/merge-patch+json'};

    print('URL DELETE: $url');

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      final response = await http.delete(url, headers: headers);
      print(response.statusCode);
      print('RESP: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 204) {
          DeleteSpecialite();
        } else {
          // Gestion des erreurs HTTP
          error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  Future<void> addSpecialite(Specialite specialite) async {
    final url = Uri.parse("${baseUrl}api/specialities");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(specialite.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          CreationSpecialite();
        } else {
          // Gestion des erreurs HTTP
          error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;
      print('VAL: $val');
      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw const FormatException("Aucun nombre trouvé dans la chaîne.");
    }
  }

  Future<void> updateSpecialite(Specialite specialite) async {
    final url = Uri.parse(
        "${baseUrl}api/specialities/${extractLastNumber(specialite.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(specialite.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Specialite déja existant');
        } else {
          UpdateSpecialite();
        }
      } else {
        // Gestion des erreurs HTTP
        error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw e;
    }
  }

  void error(String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Error'),
          content: Text(
            '$description.',
            textScaleFactor: 1.5,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
      },
    );

    // Fermer la boîte de dialogue après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pop();
    });
  }

  FocusNode _focusNodenom = FocusNode();
  FocusNode _focusNodeprenom = FocusNode();
  FocusNode _focusNodemail = FocusNode();
  FocusNode _focusNodephone = FocusNode();
  FocusNode _focusNodeaddresse = FocusNode();
  FocusNode _focusNodeville = FocusNode();

  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addresseController = TextEditingController();
  TextEditingController villeController = TextEditingController();

  bool obscurepwd = true;
  bool obscureconfpwd = true;

  final _emailValidator =
      RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  /// Validation du format E-mail
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail.';
    } else if (!_emailValidator.hasMatch(email.trim())) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    return null;
  }





  Future<void> addMedecin(Utilisateur medecin) async {
    final url = Uri.parse("${baseUrl}api/users");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(medecin.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        CreationUtilisateur();

        if (jsonResponse.containsKey('error')) {
          error('Medecin déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          CreationUtilisateur();
        } else {
          print('REQU BODY: ${response.body}');
          // Gestion des erreurs HTTP
          error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }





  void AjouterMedecin(BuildContext context) {

    spec = null;


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Ajouter un medecin',
            style: TextStyle(
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Nom',
                    controller: nomController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodenom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Prenom',
                    controller: prenomController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeprenom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  buildDropdownButtonFormField(
                    label: 'Specialite',
                    value: spec,
                    focusNode: _focusNodeSpec,
                    items: listSpec.map((e) {
                      return DropdownMenuItem<Specialite>(
                        value: e,
                        child: Text('${e.label}'),
                      );
                    }).toList(),
                    onChanged: (Specialite? newval) {
                      setState(() {
                        spec = newval;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une spécialité';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'E-mail',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _focusNodemail,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre e-mail';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Telephone',
                    controller: phoneController,
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodephone,
                    max: 10,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Addresse',
                    controller: addresseController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeaddresse,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre adresse';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Ville',
                    controller: villeController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeville,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre ville';
                      }
                      return null;
                    },
                  ),
                  // Ajoutez d'autres champs au besoin...
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();

                            if (_formKey.currentState!.validate()) {
                              String? mail =
                                  _validateEmail(emailController.text);

                              if (mail == null) {
                                Utilisateur user = Utilisateur(
                                    id: '',
                                    lastName: nomController.text.trim(),
                                    roles: ['ROLE_USER'],
                                    firstName: prenomController.text.trim(),
                                    password: "doctor",
                                    userType: 'Doctor',
                                    speciality: spec!,
                                    phone: phoneController.text.trim(),
                                    email: emailController.text.trim(),
                                    imageName: "",
                                    address: addresseController.text.trim(),
                                    category: null,
                                    createdAt: DateTime.now(),
                                    city: villeController.text.trim());
                                addMedecin(user);
                                Navigator.of(context).pop();
                            ReInitDataMedecin();
                                if (mounted) {
                                  setState() {
                                    spec = null;
                                  }
                                }
                              } else {
                                // Gérez le cas où l'e-mail n'est pas valide
                                emailInvalide();
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ... (autres propriétés de l'AlertDialog)
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Vous pouvez ajouter d'autres boutons ici si nécessaire
          ],
        );
      },
    );
  }

  Future<void> updateMedecin(Utilisateur medecin) async {
    final url =
        Uri.parse("${baseUrl}api/users/${extractLastNumber(medecin.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonSpec = jsonEncode(medecin.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Specialite déja existant');
        } else {
          UpdateUtilisateur();
        }
      } else {
        // Gestion des erreurs HTTP

        print('REQ ERROR: ${response.body}');

        error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Gestion des erreurs autres que HTTP

      //error('Erreur de connexion ou voir ceci: $e');
      print('CATCH: $e,\n EXCPEPT: $stackTrace');
      throw e;
    }
  }

  TextEditingController modifNomController = TextEditingController();
  TextEditingController modifPrenomController = TextEditingController();
  TextEditingController modifEmailController = TextEditingController();
  TextEditingController modifPhoneController = TextEditingController();
  TextEditingController modifAddresseController = TextEditingController();
  TextEditingController modifVilleController = TextEditingController();

  Specialite? modifSpec;

// ... (importations et autres méthodes)

  void modifierMedecin(Medecin medecin) {
    final _formKey = GlobalKey<FormState>();

    modifNomController.text = medecin.lastName;
    modifPrenomController.text = medecin.firstName;
    modifEmailController.text = medecin.email;
    modifPhoneController.text = medecin.phone;
    modifAddresseController.text = medecin.address;
    modifVilleController.text = medecin.city;

    modifSpec = listSpec
        .firstWhere((element) => medecin.speciality!.label == element.label);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Text(
            'Modifier un medecin',
            style: TextStyle(
              letterSpacing: 2,
              color: Colors.black.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Form(
              key: _formKeyUpdMed,
              child: ListView(
                children: [
                  buildTextFormField(
                    label: 'Nom',
                    controller: modifNomController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodenom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Prenom',
                    controller: modifPrenomController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeprenom,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  buildDropdownButtonFormField(
                    label: 'Specialite',
                    value: modifSpec,
                    focusNode: _focusNodeSpec,
                    items: listSpec.map((e) {
                      return DropdownMenuItem<Specialite>(
                        value: e,
                        child: Text('${e.label}'),
                      );
                    }).toList(),
                    onChanged: (Specialite? newval) {
                      setState(() {
                        modifSpec = newval;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une spécialité';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'E-mail',
                    controller: modifEmailController,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _focusNodemail,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre e-mail';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Telephone',
                    controller: modifPhoneController,
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodephone,
                    max: 10,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Addresse',
                    controller: modifAddresseController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeaddresse,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre adresse';
                      }
                      return null;
                    },
                  ),
                  buildTextFormField(
                    label: 'Ville',
                    controller: modifVilleController,
                    keyboardType: TextInputType.name,
                    focusNode: _focusNodeville,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre ville';
                      }
                      return null;
                    },
                  ),
                  // Ajoutez d'autres champs au besoin...
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 40, right: 10),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();

                            if (_formKeyUpdMed.currentState!.validate()) {
                              String? mail =
                                  _validateEmail(modifEmailController.text);

                              if (mail == null) {
                                Utilisateur user = Utilisateur(
                                    id: medecin.id,
                                    lastName: modifNomController.text.trim(),
                                    roles: ['ROLE_USER'],
                                    firstName:
                                        modifPrenomController.text.trim(),
                                    password: "doctor",
                                    userType: 'Doctor',
                                    speciality: modifSpec!,
                                    phone: modifPhoneController.text.trim(),
                                    email: modifEmailController.text.trim(),
                                    imageName: "",
                                    address:
                                        modifAddresseController.text.trim(),
                                    category: null,
                                    updatedAt: DateTime.now(),
                                    city: modifVilleController.text.trim());
                                updateMedecin(user);
                                Navigator.of(context).pop();
                              } else {
                                // Gérez le cas où l'e-mail n'est pas valide
                                emailInvalide();
                              }
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color.fromARGB(230, 20, 20, 90),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ... (autres propriétés de l'AlertDialog)
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Vous pouvez ajouter d'autres boutons ici si nécessaire
          ],
        );
      },
    );
  }

  void emailInvalide() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Invalide!',
        message: 'E-mail invalide.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void ChampsIncomplets() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: 'Champs incomplets!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void UpdateCenter() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre modifié',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void UpdateUtilisateur() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Médecin modifié',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void UpdateSpecialite() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Specialité modifiée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationCentre() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationSpecialite() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Specialité crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void DeleteCenter() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre supprimé',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void DeleteSpecialite() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Succès!!',
        message: 'Specialité supprimée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationUtilisateur() {
    didChangeDependencies();
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,

      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Medecin crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void PasswordIsNotTheSame() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message:
            'Les champs du mot de passe et de confirmation ne correspondent pas.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget buildTextFormField(
      {required String label,
      required TextEditingController controller,
      required TextInputType keyboardType,
      required FocusNode focusNode,
      required FormFieldValidator<String> validator,
      int? max}) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 10, right: 10, bottom: 30),
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        maxLength: (max != null) ? max : null,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          hintStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
          ),
          labelText: label,
          hintText: 'Entrer votre $label',
          labelStyle: TextStyle(
            color: focusNode.hasFocus ? Colors.redAccent : Colors.black,
          ),
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          prefixIcon: const Icon(
            Icons.person_2_rounded,
            color: Color.fromARGB(1000, 60, 70, 120),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget buildDropdownButtonFormField({
    required String label,
    required Specialite? value,
    required FocusNode focusNode,
    required List<DropdownMenuItem<Specialite>> items,
    required ValueChanged<Specialite?> onChanged,
    required FormFieldValidator<Specialite?> validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 30),
      child: DropdownButtonFormField<Specialite>(
        focusNode: focusNode,
        icon: const Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: Colors.black,
        ),
        value: value,
        onChanged: onChanged,
        items: items,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          prefixIcon: const Icon(
            Icons.people,
            color: Color.fromARGB(1000, 60, 70, 120),
          ),
          labelStyle: TextStyle(
            color: focusNode.hasFocus ? Colors.redAccent : Colors.black,
          ),
          hintStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
          ),
          labelText: label,
          hintText: '-- Plus d\'options --',
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
