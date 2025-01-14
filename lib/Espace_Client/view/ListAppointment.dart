import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'AppointmentDetails.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListAppointment extends StatefulWidget {
  _ListAppointmentState createState() => _ListAppointmentState();
}

class _ListAppointmentState extends State<ListAppointment> {
  late AuthProviderUser authProviderUser;

  String baseUrl = UrlBase().baseUrl;

  UserRepository? userRepository;
  Utilities? utilities;

  Utilisateur? user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);
  }

  bool isToday(DateTime startAt, DateTime timeStart) {
    DateTime now = DateTime.now();
    bool isIt = false;
    bool val = DateFormat('yyyy-MM-dd').format(startAt) ==
        DateFormat('yyyy-MM-dd').format(now);
    if (val) {
      if (TimeOfDay.fromDateTime(now).hour >
          TimeOfDay.fromDateTime(timeStart).hour) {
        isIt = false;
      } else {
        isIt = true;
      }
    }

    return isIt;
  }

  bool isYesterday(DateTime startAt) {
    DateTime now = DateTime.now();
    bool isIt = false;
    isIt = now.isBefore(startAt);

    return isIt;
  }

  bool isFinished(DateTime startAt, DateTime startTime) {
    DateTime now = DateTime.now();
    bool isIt = false;

    if (DateFormat('yyyy-MM-dd').format(now) ==
        DateFormat('yyyy-MM-dd').format(startAt)) {
      if (TimeOfDay.fromDateTime(startTime).hour <
          TimeOfDay.fromDateTime(now).hour) {
        isIt = true;
      }
    } else {
      if (now.isAfter(startAt)) {
        isIt = true;
      }
    }

    return isIt;
  }

  Future<List<CustomAppointment>> filterToday(
      Future<List<CustomAppointment>> appointmentFuture) async {
    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = await appointmentFuture;

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isToday(appointment.startAt, appointment.timeStart);
    }).toList();

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek);

    return filteredAppointments;
  }

  Future<List<CustomAppointment>> filterNext(
      Future<List<CustomAppointment>> appointmentFuture) async {
    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = await appointmentFuture;

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isYesterday(appointment.startAt);
    }).toList();

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek);

    return filteredAppointments;
  }

  Future<List<CustomAppointment>> filterFinished(
      Future<List<CustomAppointment>> appointmentFuture) async {
    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = await appointmentFuture;

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isFinished(appointment.startAt, appointment.timeStart);
    }).toList();

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek);

    return filteredAppointments;
  }

  late Future<List<CustomAppointment>> listRdvJJ;
  late Future<List<CustomAppointment>> listRdvNext;
  late Future<List<CustomAppointment>> listRdvFinished;

  int idUser = 0;
  late AuthProvider authProvider;
  late String token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    authProvider = Provider.of<AuthProvider>(context);
    user = Provider.of<AuthProviderUser>(context).utilisateur;
    token = authProvider.token;

    Map<String, dynamic> payload = Jwt.parseJwt(token);

    idUser = payload['id'];

    listRdvJJ = filterToday(userRepository!.getAllAppointmentByPatient(user!));
    listRdvNext = filterNext(userRepository!.getAllAppointmentByPatient(user!));
    listRdvFinished =
        filterFinished(userRepository!.getAllAppointmentByPatient(user!));
  }

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;

      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw const FormatException("Aucun nombre trouvé dans la chaîne.");
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

      if (nameParts.length > 2) {
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

  String formatTimeAppointmentNow(
      DateTime startDateTime, DateTime timeStart, DateTime timeEnd) {
    // Extraire les composants de la date et de l'heure

    int heureStart = timeStart.hour;
    int minuteStart = timeStart.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = 'Ajourd\'hui  $formatHeureStart - $formatHeureEnd';

    return resultat;
  }

  String formatTimeAppointment(
      DateTime startDateTime, DateTime timeStart, DateTime timeEnd) {
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
    int heureStart = timeStart.hour;
    int minuteStart = timeStart.minute;
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

    String resultat = "";

    DateTime now = DateTime.now();
    if (DateFormat('yyyy-MM-dd').format(now) ==
        DateFormat('yyyy-MM-dd').format(startDateTime)) {
      resultat = 'Aujourd\'hui  de  $formatHeureStart - $formatHeureEnd';
    } else {
      resultat =
          '$jourSemaine, $jour $nomMois  $formatHeureStart - $formatHeureEnd';
    }

    return resultat;
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

  List<String> strChoice = [
    "Rendez-vous du jour",
    "Prochain Rendez-vous",
    "Rendez-vous terminer"
  ];

  String currentChoice = "Rendez-vous du jour";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: ChipsChoice<String>.single(
                    choiceStyle: C2ChipStyle(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      checkmarkColor: const Color.fromARGB(230, 20, 20, 90),
                      borderColor: const Color.fromARGB(230, 20, 20, 90),
                      borderOpacity: 1,
                      borderStyle: BorderStyle.solid,
                      borderWidth: 2,
                      foregroundColor: const Color.fromARGB(230, 20, 20, 90),
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
                    onChanged: (choice) {
                      setState(() {
                        currentChoice = choice;
                      });
                    }),
              ),
              if (currentChoice == "Rendez-vous du jour") ...[
                Expanded(
                  child: FutureBuilder<List<CustomAppointment>>(
                    future:
                        listRdvJJ, // Appelez votre fonction de récupération de données ici
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Affichez un indicateur de chargement pendant le chargement
                        return Center(child: loadingWidget());
                      } else if (snapshot.hasError) {
                        // Gérez les erreurs de requête ici
                        return const Center(
                            child: Text('Erreur de chargement des données'));
                      } else {
                        if (snapshot.data!.length == 0) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height / 2.4),
                            child: Center(
                                child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: Colors.white,
                                width: MediaQuery.of(context).size.width / 1.2,
                                height:
                                    MediaQuery.of(context).size.height / 4.2,
                                child: const Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Aucun rendez-vous pour aujourd\'hui',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              letterSpacing: 2,
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Icon(
                                            Icons.update,
                                            size: 30,
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                            )),
                          );
                        } else {
                          // Trier les appointments par startAt et timeStart
                          snapshot.data!.sort((a, b) {
                            // Compare les dates startAt
                            int dateComparison = a.startAt.compareTo(b.startAt);
                            if (dateComparison != 0) {
                              return dateComparison;
                            } else {
                              // Si les dates sont égales, compare les heures timeStart
                              return a.timeStart.compareTo(b.timeStart);
                            }
                          });

                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                top: 50, left: 20, right: 20),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              List<CustomAppointment> listRDV = snapshot.data!;
                              // Utilisez snapshot.data[index] pour accéder aux éléments de la liste

                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  '$baseUrl${utilities!.ajouterPrefixe(listRDV.elementAt(index).medecin!.imageName!)}',
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                color: Colors.redAccent,
                                              ), // Affiche un indicateur de chargement en attendant l'image
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Image.asset(
                                                'assets/images/medecin.png',
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              ), // Affiche une icône d'erreur si le chargement échoue
                                            ),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Dr ${listRDV.elementAt(index).medecin!.lastName[0]}.${abbreviateName(listRDV.elementAt(index).medecin!.firstName)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${abbreviateRaison(listRDV.elementAt(index).reason)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w300),
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/date-limite.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          '${formatTimeAppointmentNow(listRDV.elementAt(index).startAt, listRDV.elementAt(index).timeStart, listRDV.elementAt(index).timeEnd)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  1000, 60, 70, 120)),
                                        )
                                      ],
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15.0,
                                            left: 10,
                                            right: 10,
                                            bottom: 20),
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
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                    const Size(250.0, 40.0)),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AppointmentDetails(),
                                                    settings: RouteSettings(
                                                        arguments:
                                                            listRDV.elementAt(
                                                                index))));
                                          },
                                          child: const Text(
                                            'Details',
                                            textScaleFactor: 1.5,
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 253, 253, 253),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        // Construisez votre ListView avec les données obtenues
                      }
                    },
                  ),
                )
              ] else if (currentChoice == "Prochain Rendez-vous") ...[
                Expanded(
                  child: FutureBuilder<List<CustomAppointment>>(
                    future:
                        listRdvNext, // Appelez votre fonction de récupération de données ici
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Affichez un indicateur de chargement pendant le chargement
                        return Center(child: loadingWidget());
                      } else if (snapshot.hasError) {
                        // Gérez les erreurs de requête ici
                        return const Center(
                            child: Text('Erreur de chargement des données'));
                      } else {
                        if (snapshot.data!.length == 0) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height / 2.4),
                            child: Center(
                                child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: Colors.white,
                                width: MediaQuery.of(context).size.width / 1.2,
                                height:
                                    MediaQuery.of(context).size.height / 4.2,
                                child: const Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Aucun rendez-vous prochainement',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              letterSpacing: 2,
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Icon(
                                            Icons.update,
                                            size: 30,
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                            )),
                          );
                        } else {
                          // Trier les appointments par startAt et timeStart
                          snapshot.data!.sort((a, b) {
                            // Compare les dates startAt
                            int dateComparison = a.startAt.compareTo(b.startAt);
                            if (dateComparison != 0) {
                              return dateComparison;
                            } else {
                              // Si les dates sont égales, compare les heures timeStart
                              return a.timeStart.compareTo(b.timeStart);
                            }
                          });

                          // Construisez votre ListView avec les données obtenues
                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                top: 50, left: 20, right: 20),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              List<CustomAppointment> listNextRdv =
                                  snapshot.data!;
                              // Utilisez snapshot.data[index] pour accéder aux éléments de la liste
                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  '$baseUrl${utilities!.ajouterPrefixe(listNextRdv.elementAt(index).medecin!.imageName!)}',
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                color: Colors.redAccent,
                                              ), // Affiche un indicateur de chargement en attendant l'image
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Image.asset(
                                                'assets/images/medecin.png',
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              ), // Affiche une icône d'erreur si le chargement échoue
                                            ),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Dr ${listNextRdv.elementAt(index).medecin!.lastName[0]}.${abbreviateName(listNextRdv.elementAt(index).medecin!.firstName)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${abbreviateRaison(listNextRdv.elementAt(index).reason)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w300),
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/date-limite.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          '${formatTimeAppointment(listNextRdv.elementAt(index).startAt, listNextRdv.elementAt(index).timeStart, listNextRdv.elementAt(index).timeEnd)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  1000, 60, 70, 120)),
                                        )
                                      ],
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15.0,
                                            left: 10,
                                            right: 10,
                                            bottom: 20),
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
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                    const Size(250.0, 40.0)),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AppointmentDetails(),
                                                    settings: RouteSettings(
                                                        arguments: listNextRdv
                                                            .elementAt(
                                                                index))));
                                          },
                                          child: const Text(
                                            'Details',
                                            textScaleFactor: 1.5,
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 253, 253, 253),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                )
              ] else if (currentChoice == "Rendez-vous terminer") ...[
                Expanded(
                  child: FutureBuilder<List<CustomAppointment>>(
                    future:
                        listRdvFinished, // Appelez votre fonction de récupération de données ici
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Affichez un indicateur de chargement pendant le chargement
                        return Center(child: loadingWidget());
                      } else if (snapshot.hasError) {
                        // Gérez les erreurs de requête ici
                        return const Center(
                            child: Text('Erreur de chargement des données'));
                      } else {
                        if (snapshot.data!.length == 0) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height / 2.4),
                            child: Center(
                                child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: Colors.white,
                                width: MediaQuery.of(context).size.width / 1.2,
                                height:
                                    MediaQuery.of(context).size.height / 4.2,
                                child: const Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Aucun rendez-vous terminer',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              letterSpacing: 2,
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Icon(
                                            Icons.update,
                                            size: 30,
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                            )),
                          );
                        } else {
                          // Trier les appointments par startAt et timeStart
                          snapshot.data!.sort((a, b) {
                            // Compare les dates startAt
                            int dateComparison = b.startAt.compareTo(a.startAt);
                            if (dateComparison != 0) {
                              return dateComparison;
                            } else {
                              // Si les dates sont égales, compare les heures timeStart
                              return b.timeStart.compareTo(a.timeStart);
                            }
                          });

                          // Construisez votre ListView avec les données obtenues
                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                top: 50, left: 20, right: 20),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              List<CustomAppointment> listFinished =
                                  snapshot.data!;
                              // Utilisez snapshot.data[index] pour accéder aux éléments de la liste
                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  '$baseUrl${utilities!.ajouterPrefixe(listFinished.elementAt(index).medecin!.imageName!)}',
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(
                                                color: Colors.redAccent,
                                              ), // Affiche un indicateur de chargement en attendant l'image
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Image.asset(
                                                'assets/images/medecin.png',
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              ), // Affiche une icône d'erreur si le chargement échoue
                                            ),
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Dr ${listFinished.elementAt(index).medecin!.lastName[0]}.${abbreviateName(listFinished.elementAt(index).medecin!.firstName)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${abbreviateRaison(listFinished.elementAt(index).reason)}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      1000, 60, 70, 120),
                                                  fontWeight: FontWeight.w300),
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/date-limite.png',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          '${formatTimeAppointment(listFinished.elementAt(index).startAt, listFinished.elementAt(index).timeStart, listFinished.elementAt(index).timeEnd)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  1000, 60, 70, 120)),
                                        )
                                      ],
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15.0,
                                            left: 10,
                                            right: 10,
                                            bottom: 20),
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
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                    const Size(250.0, 40.0)),
                                          ),
                                          onPressed: () {
                                            print(
                                                'FINISHED APPOINT: ${listFinished.elementAt(index).medecin!.imageName}');
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AppointmentDetails(),
                                                    settings: RouteSettings(
                                                        arguments: listFinished
                                                            .elementAt(
                                                                index))));
                                          },
                                          child: const Text(
                                            'Details',
                                            textScaleFactor: 1.5,
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 253, 253, 253),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                )
              ],
            ],
          )),
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
