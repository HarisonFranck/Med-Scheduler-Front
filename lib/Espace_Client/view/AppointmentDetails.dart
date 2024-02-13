import 'package:flutter/material.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'Dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';

class AppointmentDetails extends StatefulWidget {
  @override
  _AppointmentDetailsState createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {

  Utilities? utilities;

  String baseUrl = UrlBase().baseUrl;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);

  }

  String abbreviateName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else {
      // Si le nom contient plusieurs mots
      String firstName = nameParts.first;
      String firstChar = firstName[0];

      return firstChar;
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
  Widget build(BuildContext context) {
    CustomAppointment appointment =
        ModalRoute.of(context)?.settings.arguments as CustomAppointment;

    return Scaffold(
      backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
      body: ListView(
        children: [
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
                    Navigator.of(context).pop();
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
          const SizedBox(
            height: 30,
          ),
          Padding(
              padding: const EdgeInsets.only(
                  top: 20, right: 15, left: 15, bottom: 20),
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
                              child: CachedNetworkImage(
                                imageUrl:
                                    '$baseUrl${utilities!.ajouterPrefixe(appointment.medecin!.imageName!)}',
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(
                                  color: Colors.redAccent,
                                ), // Affiche un indicateur de chargement en attendant l'image
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/images/medecin.png',
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ), // Affiche une icône d'erreur si le chargement échoue
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                          children: [
                            Text(
                              textAlign: TextAlign.start,
                              'Dr.${abbreviateName(appointment.medecin!.lastName)} \n ${abbreviateFirstName(appointment.medecin!.firstName)}',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            if (appointment.medecin!.speciality != null) ...[
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  textAlign: TextAlign.start,
                                  '${appointment.medecin!.speciality!.label}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black.withOpacity(0.6)),
                                ),
                              )
                            ]
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                    const Padding(
                        padding:
                            EdgeInsets.only(top: 20, right: 20, bottom: 20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Text(
                                'Rendez-vous',
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500),
                              ),
                            )
                          ],
                        )),
                    Padding(
                        padding: const EdgeInsets.only(top: 20, right: 20),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Raison:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Text(
                                '${appointment.reason}',
                                style: const TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            )
                          ],
                        )),
                    Divider(
                      thickness: 1,
                      color: Colors.black.withOpacity(0.5),
                      indent: 10,
                      endIndent: 10,
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 30, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Le:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '  ${formatDateTimeAppointment(appointment.startAt.toLocal(), appointment.timeEnd.toLocal())}',
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
                        padding: const EdgeInsets.only(top: 20, right: 20),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'De:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${formatTimeAppointment(appointment.timeStart, appointment.timeEnd)}',
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
                    const SizedBox(height: 150)
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
