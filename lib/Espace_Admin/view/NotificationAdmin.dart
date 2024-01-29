import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'dart:io';
import 'IndexAccueilAdmin.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';

class NotificationAdmin extends StatefulWidget {
  final Utilisateur user;

  NotificationAdmin({required this.user});

  _NotificationAdminState createState() => _NotificationAdminState();
}

class _NotificationAdminState extends State<NotificationAdmin> {
  late AuthProvider authProvider;
  late String token;
  String baseUrl = UrlBase().baseUrl;

  BaseRepository? baseRepository;
  Utilities? utilities;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  bool isToday(DateTime startAt, DateTime timeStart) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
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

  Future<List<CustomAppointment>> filterAppointments(
      Future<List<CustomAppointment>> appointmentsFuture) async {
    print('FILTER');
    List<CustomAppointment> allAppointments = await appointmentsFuture;

    print('ALL APPOINTS: ${allAppointments.length}');
    print('DATE: ${DateFormat('yyyy-MM-dd').format(DateTime(1970, 1, 26))}');

    // Filtrer les rendez-vous avec startAt égal à DateTime.now()
    List<CustomAppointment> filteredAppointments = allAppointments
        .where((appointment) =>
            isToday(appointment.startAt, appointment.timeStart))
        .toList();
    print('SIZE FILTER: ${filteredAppointments.length}');

    return filteredAppointments;
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
    int annee = startDateTime.year;
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

    // Construire la chaîne lisible
    String resultat = 'Ajourd\'hui  $formatHeureStart - $formatHeureEnd';

    return resultat;
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

  String abreviateRaison(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    }
    if (nameParts.length > 1) {
      // Si le prénom contient plus de deux mots, utiliser seulement le premier mot
      return "${nameParts[0]}...";
    } else {
      return fullName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, bottom: 10),
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
                                  builder: (context) => IndexAccueilAdmin()));
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
                  padding:
                      const EdgeInsets.only(top: 20, bottom: 20, right: 5, left: 5),
                  child: FutureBuilder<List<CustomAppointment>>(
                    future: filterAppointments(
                        baseRepository!.getAllAppointment()), // Appelez votre fonction de récupération de données ici
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Affichez un indicateur de chargement pendant le chargement
                        return Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 3),
                          child: Center(child: loadingWidget()),
                        );
                      } else if (snapshot.hasError) {
                        // Gérez les erreurs de requête ici
                        return const Center(
                            child: Text('Erreur de chargement des données'));
                      } else {
                        if (snapshot.data!.length == 0) {
                          return Center(
                              child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              color: Colors.white,
                              width: MediaQuery.of(context).size.width / 1.2,
                              height: MediaQuery.of(context).size.height / 1.4,
                              child: Card(
                                  color: Colors.transparent,
                                  elevation: 0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 20, top: 10),
                                        child: Center(
                                          child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  90,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: Colors.redAccent,
                                                    width: 1),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.notifications,
                                                    color: Colors.redAccent,
                                                  ),
                                                  Spacer(),
                                                  Text(
                                                    'Historique des notifications',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Colors.redAccent,
                                                        letterSpacing: 2),
                                                  ),
                                                  Spacer()
                                                ],
                                              )),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 10),
                                        child: Icon(
                                          Icons.update,
                                          size: 30,
                                          color:
                                              Color.fromARGB(230, 20, 20, 90),
                                        ),
                                      ),
                                      const Text(
                                        'Aucune notification récente.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            letterSpacing: 2,
                                            color: Colors.black,
                                            fontSize: 16),
                                      ),
                                      const Spacer()
                                    ],
                                  )),
                            ),
                          ));
                        } else {
                          return Center(
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                                width: MediaQuery.of(context).size.width / 1.2,
                                height:
                                    MediaQuery.of(context).size.height / 1.4,
                                child: Card(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 20, top: 10),
                                            child: Center(
                                              child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      90,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: Border.all(
                                                        color: Colors.redAccent,
                                                        width: 1),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.notifications,
                                                        color: Colors.redAccent,
                                                      ),
                                                      Spacer(),
                                                      Text(
                                                        'Historique des notifications',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                            letterSpacing: 2),
                                                      ),
                                                      Spacer()
                                                    ],
                                                  )),
                                            ),
                                          ),
                                          Expanded(
                                              child: ListView.builder(
                                            padding: const EdgeInsets.only(top: 30),
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              List<CustomAppointment> listRDV =
                                                  snapshot.data!;
                                              // Utilisez snapshot.data[index] pour accéder aux éléments de la liste

                                              return Padding(
                                                  padding: const EdgeInsets.only(
                                                    bottom: 40,
                                                  ),
                                                  child: Container(
                                                      width: 410,
                                                      height: 200,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              Colors.redAccent,
                                                          width: 1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Card(
                                                        elevation: 0,
                                                        color: Colors.white,
                                                        child: Column(
                                                          children: [
                                                            const SizedBox(
                                                              height: 20,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                  child:
                                                                      Container(
                                                                    width: 60,
                                                                    height: 60,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              6),
                                                                    ),
                                                                    child: ((listRDV.elementAt(index).medecin!.imageName !=
                                                                                null) &&
                                                                            (File(listRDV.elementAt(index).medecin!.imageName!)
                                                                                .existsSync()))
                                                                        ? Image.file(File(listRDV
                                                                            .elementAt(
                                                                                index)
                                                                            .medecin!
                                                                            .imageName!))
                                                                        : Image
                                                                            .asset(
                                                                            'assets/images/medecin.png',
                                                                            fit:
                                                                                BoxFit.fill,
                                                                          ),
                                                                  ),
                                                                ),
                                                                Column(
                                                                  children: [
                                                                    Text(
                                                                      '${listRDV.elementAt(index).medecin!.lastName[0]}.${abbreviateName(listRDV.elementAt(index).medecin!.firstName)}',
                                                                      style: const TextStyle(
                                                                          color: Color.fromARGB(
                                                                              1000,
                                                                              60,
                                                                              70,
                                                                              120),
                                                                          fontWeight:
                                                                              FontWeight.w500),
                                                                    ),
                                                                    Text(
                                                                      '${abreviateRaison(listRDV.elementAt(index).reason)}',
                                                                      style: const TextStyle(
                                                                          color: Color.fromARGB(
                                                                              1000,
                                                                              60,
                                                                              70,
                                                                              120),
                                                                          fontWeight:
                                                                              FontWeight.w300),
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
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            Expanded(
                                                                child: Text(
                                                                    'Il y a un rendez-vous du Dr ${listRDV.elementAt(index).medecin!.lastName} ${abbreviateName(listRDV.elementAt(index).medecin!.firstName)} avec un patient :',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.5)))),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Image.asset(
                                                                  'assets/images/date-limite.png',
                                                                  width: 20,
                                                                  height: 20,
                                                                ),
                                                                const Spacer(),
                                                                Text(
                                                                  '${formatTimeAppointment(listRDV.elementAt(index).startAt, listRDV.elementAt(index).timeStart, listRDV.elementAt(index).timeEnd)}',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                      color: Color.fromARGB(
                                                                          1000,
                                                                          60,
                                                                          70,
                                                                          120)),
                                                                ),
                                                                const Spacer(),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      )));
                                            },
                                          )),
                                        ]))),
                          );
                        }
                        // Construisez votre ListView avec les données obtenues
                      }
                    },
                  ),
                ),
              ],
            )),);
  }

  Widget loadingWidget(){
    return Center(
        child:Container(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [

              LoadingAnimationWidget.hexagonDots(
                  color: Colors.redAccent,
                  size: 120),

              Image.asset('assets/images/logo2.png',width: 80,height: 80,fit: BoxFit.cover,)
            ],
          ),
        ));
  }


}
