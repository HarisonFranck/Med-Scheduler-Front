import 'package:flutter/material.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'dart:async';
import 'PriseDeRendezVous.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:med_scheduler_front/main.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ConfirmAppointment extends StatefulWidget {
  final CustomAppointment appointment;

  ConfirmAppointment({required this.appointment});

  _ConfirmAppointmentState createState() => _ConfirmAppointmentState();
}

class _ConfirmAppointmentState extends State<ConfirmAppointment> {
  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  Utilities? utilities;
  UserRepository? userRepository;

  bool isLoading = false;

  Future<void> addAppointment(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {
    setState(() {
      isLoading = true;
    });
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/appointments");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonUser = jsonEncode(appointment.toJson());
      print('Request Body: $jsonUser');
      final response = await http.post(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities!.error('Rendez-vous déja existant');
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        }
      } else {
        if (response.statusCode == 201) {
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        } else {
          setState(() {
            isLoading = false;
          });
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
            );
          } else {
            setState(() {
              isLoading = false;
            });
            utilities!.error(
                'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
          }

          // Gestion des erreurs HTTP
          //error('Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        isLoading = false;
      });
      if (e is http.ClientException) {
        utilities!.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }
      throw e;
    }
  }

  Future<void> addAppointmentUnavailable(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {
    setState(() {
      isLoading = true;
    });
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/unavailable_appointments");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonUser = jsonEncode(appointment.toJson());
      print('Request Body: $jsonUser');
      final response = await http.post(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          setState(() {
            isLoading = false;
          });
          utilities!.error('Rendez-vous déja existant');
        } else {
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (response.statusCode == 201) {
          utilities!.RdvValider();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        } else {
          setState(() {
            isLoading = false;
          });
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
            );
          }

          // Gestion des erreurs HTTP
          utilities!.error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        isLoading = false;
      });
      if (e is http.ClientException) {
        utilities!.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }
      throw e;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);
  }

  void success() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Succès'),
          content: Text(
            'Utilisateur créé avec succès.',
            textScaleFactor: 1.3,
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
      },
    );

    // Fermer la boîte de dialogue après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pop();
    });
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

  void CreationAppointment() {
    SnackBar snackBar = const SnackBar(
      backgroundColor: Colors.redAccent,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Rendez-vous creer!',
              textScaleFactor: 1.8,
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            color: Color.fromARGB(230, 20, 20, 90),
            size: 30,
          ),
        ],
      ),
      elevation: 4,
      duration: Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String abbreviateName(String fullName) {
    fullName = '$fullName En Art';
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else {
      // Si le nom contient plusieurs mots
      String firstName = nameParts.first;

      return '$firstName ...';
    }
  }

  String abbreviateFirstName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else {
      // Si le nom contient plusieurs mots
      String firstName = nameParts.first;

      return firstName;
    }
  }

  String abbreviateRaison(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else if (nameParts.length > 2) {
      // Si le nom contient plusieurs mots
      String first = nameParts[0];
      String second = nameParts[1];

      return "$first $second...";
    }
    return fullName;
  }

  String formatDateTimeAppointment(DateTime startDateTime, DateTime timeEnd) {
    // Liste des jours de la semaine
    final List<String> jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    // Liste des mois de l'année
    final List<String> mois = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    // Extraire les composants de la date et de l'heure
    int jour = startDateTime.day;
    int moisIndex = startDateTime.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startDateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$jourSemaine, $jour $nomMois $annee';

    return resultat;
  }

  String formatTimeAppointment(DateTime startDateTime, DateTime timeEnd) {
    // Liste des jours de la semaine
    final List<String> jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    // Liste des mois de l'année
    final List<String> mois = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    // Extraire les composants de la date et de l'heure
    int jour = startDateTime.day;
    int moisIndex = startDateTime.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startDateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$formatHeureStart - $formatHeureEnd';

    return resultat;
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    authProvider = Provider.of<AuthProvider>(context);
    token = authProvider.token;
  }

  TextEditingController raison = TextEditingController();

  bool isReady = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    Medecin medecin = ModalRoute.of(context)?.settings.arguments as Medecin;
    return PopScope(
      canPop: false,
        child: (!isLoading)? Scaffold(
                key: _scaffoldKey,
                backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
                body: ListView(children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_left,
                                size: 40,
                              ),
                              Text('Retour'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PriseDeRendezVous(
                                        patient: widget.appointment.patient!),
                                    settings:
                                        RouteSettings(arguments: medecin)));
                          },
                        ),
                        const Spacer(),
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            child: Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: Image.asset(
                                'assets/images/logo2.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(
                          top: 30, right: 15, left: 15, bottom: 20),
                      child: Card(
                          elevation: 0,
                          color: Colors.white,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, left: 30, bottom: 50),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(60),
                                          ),
                                          child: (medecin.imageName != null &&
                                                  File(medecin.imageName!)
                                                      .existsSync())
                                              ? Image.file(
                                                  File(medecin.imageName!),
                                                  fit: BoxFit.fill,
                                                )
                                              : Image.asset(
                                                  'assets/images/medecin.png')),
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    children: [
                                      Text(
                                        '${abbreviateFirstName(medecin.lastName)}',
                                        style: const TextStyle(
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        '${abbreviateFirstName(medecin.firstName)}',
                                        style: const TextStyle(
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 15),
                                        child: Text(
                                          '${abbreviateFirstName(medecin.speciality!.label)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16),
                                        ),
                                      ),
                                      if (medecin.speciality!.label
                                              .split(' ')
                                              .length >=
                                          2) ...[
                                        Text(
                                          '${abbreviateFirstName(medecin.speciality!.label.split(' ').last)}',
                                          style: const TextStyle(
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16),
                                        ),
                                      ]
                                    ],
                                  ),
                                  const Spacer()
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 20),
                                child: Text(
                                  'Confirmer votre rendez-vous:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      letterSpacing: 2,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Padding(
                                  padding:
                                      const EdgeInsets.only(top: 30, right: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          'Le:',
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  230, 20, 20, 90),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '  ${formatDateTimeAppointment(widget.appointment.startAt.toLocal(), widget.appointment.timeEnd.toLocal())}',
                                        style: const TextStyle(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  )),
                              Divider(
                                thickness: 1,
                                color: Colors.black.withOpacity(0.5),
                                indent: 10,
                                endIndent: 10,
                              ),
                              Padding(
                                  padding:
                                      const EdgeInsets.only(top: 20, right: 20),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          'De:',
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  230, 20, 20, 90),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${formatTimeAppointment(widget.appointment.timeStart, widget.appointment.timeEnd)}',
                                        style: const TextStyle(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  )),
                              Divider(
                                thickness: 1,
                                color: Colors.black.withOpacity(0.5),
                                indent: 10,
                                endIndent: 10,
                              ),
                              Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Text('Raison:'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          1.525,
                                      child: TextField(
                                        canRequestFocus: true,
                                        onChanged: (val) {
                                          if (val.length >= 1) {
                                            setState(() {
                                              isReady = true;
                                            });
                                          } else {
                                            setState(() {
                                              isReady = false;
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: const Color.fromARGB(
                                                      230, 20, 20, 90)
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                        controller: raison,
                                        readOnly: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 70,
                              ),
                              if (isReady) ...[
                                Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 40,
                                        right: 40,
                                        bottom: 40),
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                const Color.fromARGB(
                                                    1000, 60, 70, 120)),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                8.0), // Définissez le rayon de la bordure ici
                                          ),
                                        ),
                                        minimumSize: MaterialStateProperty.all(
                                            const Size(260.0, 60.0)),
                                      ),
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();

                                        if (raison.text.isEmpty) {
                                        } else {
                                          TimeOfDay timeOfDayStart =
                                              TimeOfDay.fromDateTime(
                                                  widget.appointment.timeStart);
                                          TimeOfDay timeOfDayEnd =
                                              TimeOfDay.fromDateTime(
                                                  widget.appointment.timeEnd);

                                          print(
                                              ' timeOfDayStart: $timeOfDayStart ');
                                          print(
                                              ' timeOfDayEnd: $timeOfDayEnd ');

                                          CustomAppointment newAppointment =
                                              CustomAppointment(
                                                  id: '',
                                                  type: '',
                                                  medecin: medecin,
                                                  patient: widget
                                                      .appointment.patient,
                                                  startAt: widget
                                                      .appointment.startAt,
                                                  timeStart: widget
                                                      .appointment.timeStart,
                                                  timeEnd: widget
                                                      .appointment.timeEnd,
                                                  reason: raison.text,
                                                  createdAt: DateTime.now());
                                          CustomAppointment
                                              newUnavailableAppointment =
                                              CustomAppointment(
                                                  id: '',
                                                  type: '',
                                                  appType: 'Pris',
                                                  medecin: medecin,
                                                  patient: widget
                                                      .appointment.patient,
                                                  startAt: widget
                                                      .appointment.startAt,
                                                  timeStart: widget
                                                      .appointment.timeStart,
                                                  timeEnd: widget
                                                      .appointment.timeEnd,
                                                  reason: raison.text,
                                                  createdAt: DateTime.now());

                                          addAppointment(newAppointment,
                                              widget.appointment);
                                          addAppointmentUnavailable(
                                              newUnavailableAppointment,
                                              widget.appointment);

                                          print('--- APPOINTMENT CREATED ---');
                                        }
                                      },
                                      child: const Text(
                                        'Confirmer',
                                        textScaleFactor: 1.5,
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 253, 253, 253),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10, bottom: 10),
                                  child: Center(
                                    child: Text(
                                      'Veuillez entrer la raison du rendez-vous.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          letterSpacing: 1.5,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.redAccent
                                              .withOpacity(0.8)),
                                    ),
                                  ),
                                )
                              ]
                            ],
                          )))
                ]))
            : scafWithLoading(medecin));
  }

  Widget scafWithLoading(Medecin medecin) {
    return Stack(
      children: [
        Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
            body: ListView(children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_left,
                            size: 40,
                          ),
                          Text('Retour'),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PriseDeRendezVous(
                                    patient: widget.appointment.patient!),
                                settings: RouteSettings(arguments: medecin)));
                      },
                    ),
                    const Spacer(),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          child: Image.asset(
                            'assets/images/logo2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(
                      top: 30, right: 15, left: 15, bottom: 20),
                  child: Card(
                      elevation: 0,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 20, left: 30, bottom: 50),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: (medecin.imageName != null &&
                                              File(medecin.imageName!)
                                                  .existsSync())
                                          ? Image.file(
                                              File(medecin.imageName!),
                                              fit: BoxFit.fill,
                                            )
                                          : Image.asset(
                                              'assets/images/medecin.png')),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Text(
                                    '${abbreviateFirstName(medecin.lastName)}',
                                    style: const TextStyle(
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    '${abbreviateFirstName(medecin.firstName)}',
                                    style: const TextStyle(
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(
                                      '${abbreviateFirstName(medecin.speciality!.label)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16),
                                    ),
                                  ),
                                  if (medecin.speciality!.label
                                          .split(' ')
                                          .length >=
                                      2) ...[
                                    Text(
                                      '${abbreviateFirstName(medecin.speciality!.label.split(' ').last)}',
                                      style: const TextStyle(
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16),
                                    ),
                                  ]
                                ],
                              ),
                              const Spacer()
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              'Confirmer votre rendez-vous:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  letterSpacing: 2,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 30, right: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      'Le:',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(230, 20, 20, 90),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '  ${formatDateTimeAppointment(widget.appointment.startAt.toLocal(), widget.appointment.timeEnd.toLocal())}',
                                    style: const TextStyle(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )),
                          Divider(
                            thickness: 1,
                            color: Colors.black.withOpacity(0.5),
                            indent: 10,
                            endIndent: 10,
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 20, right: 20),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      'De:',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(230, 20, 20, 90),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${formatTimeAppointment(widget.appointment.timeStart, widget.appointment.timeEnd)}',
                                    style: const TextStyle(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )),
                          Divider(
                            thickness: 1,
                            color: Colors.black.withOpacity(0.5),
                            indent: 10,
                            endIndent: 10,
                          ),
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Text('Raison:'),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.525,
                                  child: TextField(
                                    canRequestFocus: true,
                                    onChanged: (val) {
                                      if (val.length >= 1) {
                                        setState(() {
                                          isReady = true;
                                        });
                                      } else {
                                        setState(() {
                                          isReady = false;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color.fromARGB(
                                                  230, 20, 20, 90)
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    controller: raison,
                                    readOnly: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 70,
                          ),
                          if (isReady) ...[
                            Padding(
                                padding: const EdgeInsets.only(
                                    top: 20.0, left: 40, right: 40, bottom: 40),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color.fromARGB(
                                            1000, 60, 70, 120)),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Définissez le rayon de la bordure ici
                                      ),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                        const Size(260.0, 60.0)),
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();

                                    if (raison.text.isEmpty) {
                                    } else {
                                      TimeOfDay timeOfDayStart =
                                          TimeOfDay.fromDateTime(
                                              widget.appointment.timeStart);
                                      TimeOfDay timeOfDayEnd =
                                          TimeOfDay.fromDateTime(
                                              widget.appointment.timeEnd);

                                      print(
                                          ' timeOfDayStart: $timeOfDayStart ');
                                      print(' timeOfDayEnd: $timeOfDayEnd ');

                                      CustomAppointment newAppointment =
                                          CustomAppointment(
                                              id: '',
                                              type: '',
                                              medecin: medecin,
                                              patient:
                                                  widget.appointment.patient,
                                              startAt:
                                                  widget.appointment.startAt,
                                              timeStart:
                                                  widget.appointment.timeStart,
                                              timeEnd:
                                                  widget.appointment.timeEnd,
                                              reason: raison.text,
                                              createdAt: DateTime.now());
                                      CustomAppointment
                                          newUnavailableAppointment =
                                          CustomAppointment(
                                              id: '',
                                              type: '',
                                              appType: 'Pris',
                                              medecin: medecin,
                                              patient:
                                                  widget.appointment.patient,
                                              startAt:
                                                  widget.appointment.startAt,
                                              timeStart:
                                                  widget.appointment.timeStart,
                                              timeEnd:
                                                  widget.appointment.timeEnd,
                                              reason: raison.text,
                                              createdAt: DateTime.now());

                                      addAppointment(
                                          newAppointment, widget.appointment);
                                      addAppointmentUnavailable(
                                          newUnavailableAppointment,
                                          widget.appointment);

                                      print('--- APPOINTMENT CREATED ---');
                                    }
                                  },
                                  child: const Text(
                                    'Confirmer',
                                    textScaleFactor: 1.5,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 253, 253, 253),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, bottom: 10),
                              child: Center(
                                child: Text(
                                  'Veuillez entrer la raison du rendez-vous.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      letterSpacing: 1.5,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.redAccent.withOpacity(0.8)),
                                ),
                              ),
                            )
                          ]
                        ],
                      )))
            ])),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.2),
        ),
        loadingWidget()
      ],
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
