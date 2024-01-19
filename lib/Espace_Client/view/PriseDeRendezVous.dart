import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'IndexAccueil.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/CustomAppointmentDataSource.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/Patient.dart';
import 'dart:convert';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:intl/intl.dart';
import 'ConfirmAppointment.dart';
import 'package:med_scheduler_front/UnavalaibleAppointment.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class PriseDeRendezVous extends StatefulWidget {
  final Patient patient;

  PriseDeRendezVous({required this.patient});

  _PriseDeRendezVousState createState() => _PriseDeRendezVousState();
}

class _PriseDeRendezVousState extends State<PriseDeRendezVous> {

  Future<void> initializeCalendar() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Indian/Antananarivo'));

    DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
    var calendars = await deviceCalendarPlugin.retrieveCalendars();

    if (calendars.data!.isEmpty) {
      print('NULL ILAY CALENDAR');
      return;
    }

    var defaultCalendarId = calendars.data!.first.id;

    try {
      List<CustomAppointment> appoints =
          await getProcheRendezVous(await getAllAppointment());

      if (appoints.isNotEmpty) {
        appoints.forEach((element) async {
          print('THE APPOINT ${element.reason}');

          print(
              'APPOINT TZTIME: ${tz.TZDateTime.from(element.timeStart, tz.local)}');
          TZDateTime startTZ = TZDateTime(
              tz.getLocation('Indian/Antananarivo'),
              element.startAt.year,
              element.startAt.month,
              element.startAt.day,
              element.timeStart.hour,
              element.timeStart.minute,
              element.timeStart.second);
          TZDateTime endTZ = TZDateTime(
              tz.getLocation('Indian/Antananarivo'),
              element.startAt.year,
              element.startAt.month,
              element.startAt.day,
              element.timeEnd.hour,
              element.timeEnd.minute,
              element.timeEnd.second);

          print('StartTZ: ${startTZ}');
          print('EndTZ: ${endTZ}');

          Event event = Event(
            defaultCalendarId,
            title: 'Prochain Rendez-vous: ${element.reason.toUpperCase()}',
            description: (element.medecin != null)
                ? '${element.reason.toUpperCase()} avec le Dr ${element.medecin!.lastName} ${element.medecin!.firstName}.'
                : element.reason,
            start: startTZ,
            end: endTZ,
            status: EventStatus.Confirmed,
            reminders: [
              Reminder(minutes: 15),
              Reminder(minutes: 30),
              Reminder(minutes: 60)
            ],
          );

          print('EVENT DESC: ${event.description}');

          // Utiliser RetrieveEventsParams
          var params = RetrieveEventsParams(
              startDate: startTZ.subtract(const Duration(minutes: 1)),
              endDate: endTZ.add(const Duration(minutes: 1)));
          var existingEvents = await deviceCalendarPlugin.retrieveEvents(
              defaultCalendarId, params);

          var eventExists = existingEvents.data!.any((existingEvent) =>
                  existingEvent.title == event.title &&
                  existingEvent.description == event.description &&
                  existingEvent.start == startTZ &&
                  existingEvent.end == endTZ) ??
              false;

          if (!eventExists) {
            final result =
                await deviceCalendarPlugin.createOrUpdateEvent(event);
            print('RSULTAT ERRORS: ${result!.errors}');
            print('RSULTAT SUCCES: ${result.data}');
          }

          print('-- FINISHED --');
        });
      }
    } catch (e, stackTrace) {
      print(' -- ERROR E: $e \n -- STACK: $stackTrace');
    }
  }



  List<CustomAppointment> getProcheRendezVous(
      List<CustomAppointment> rendezVousList) {
    List<CustomAppointment> rdvProche = [];

    // Implémentez ici la logique pour récupérer un rendez-vous proche
    // par rapport à la date actuelle
    DateTime now = DateTime.now();


    for (int i = 0; i < rendezVousList.length; i++) {
      CustomAppointment appointment = rendezVousList.elementAt(i);
      DateTime startDate = DateTime(
          appointment.startAt.year,
          appointment.startAt.month,
          appointment.startAt.day,
          appointment.timeStart.hour,
          appointment.timeStart.minute,
          appointment.timeStart.second);
      DateTime endDate = DateTime(
          appointment.startAt.year,
          appointment.startAt.month,
          appointment.startAt.day,
          appointment.timeEnd.hour,
          appointment.timeEnd.minute,
          appointment.timeEnd.second);

      if (startDate.isAfter(now) &&
          isInCurrentWeek(startDate, rendezVousList.elementAt(i).timeStart)) {

        rdvProche.add(appointment);
      }
    }
    return rdvProche;
  }

  String extractApiPath(String fullPath) {
    const String apiPrefix = '/med_scheduler_api/public/api/specialities/';
    if (fullPath.startsWith(apiPrefix)) {
      return fullPath.substring(apiPrefix.length);
    } else {
      // La chaîne ne commence pas par le préfixe attendu
      return fullPath;
    }
  }

  bool isInCurrentWeek(DateTime startAt, DateTime timeStart) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day, now.hour);
    DateTime endOfWeek = startOfWeek.add(Duration(days: 7 - now.weekday));
    bool isIt = false;
    DateTime formatedStartAt =
    DateTime.parse(DateFormat('yyyy-MM-dd').format(startAt));
    DateTime formatedStartOfWeek =
    DateTime.parse(DateFormat('yyyy-MM-dd').format(startOfWeek));
    DateTime formatedEndOfWeek =
    DateTime.parse(DateFormat('yyyy-MM-dd').format(endOfWeek));
    DateTime TimeDtStart =
    DateTime(startAt.year, startAt.month, startAt.day, timeStart.hour);

    if ((formatedStartAt.isBefore(formatedEndOfWeek)) &&
        (now.isBefore(TimeDtStart))) {
      isIt = true;
    }

    return isIt;
  }




  bool _isPageActive = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _isPageActive = false;
    super.dispose();

    print('--- DESTRUCTION PAGE ---');
  }

  String baseUrl = UrlBase().baseUrl;
  late AuthProvider authProvider;
  late String token;
  late int idUser = 0;
  bool dataLoaded = false;

  CustomAppointmentDataSource? customAppointmentDataSource;

  List<CustomAppointment> listAppointment = [];
  List<CustomAppointment> listUnavalaibleAppointment = [];

  String formatDateTimeAppointment(
      DateTime startAt, DateTime startDateTime, DateTime timeEnd) {
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

    int jour = startAt.day;
    int moisIndex = startAt.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startAt.weekday - 1];

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

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;
      print('VAL: $val');
      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw FormatException("Aucun nombre trouvé dans la chaîne.");
    }
  }

  Future<List<CustomAppointment>> getAllUnavalaibleAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }

    print('MED ID: ${medecinCliked!.id}');
    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${extractLastNumber(medecinCliked!.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        print('DATS UNAVALAIBLE SIZE: ${datas.length}');

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        print('RESP ERROR UNAV: ${response.body}');
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw e;
    }
  }

  Future<List<CustomAppointment>> InitierAppointment(Medecin medecin) async {
    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }
    try {
      List<CustomAppointment> appointmentList = await getAllAppointment();
      List<CustomAppointment> AppointmentList = [];
      for (int a = 0; a < appointmentList.length; a++) {
        CustomAppointment appointment = appointmentList.elementAt(a);
        if ((appointment.medecin!.firstName == medecin.firstName) &&
            (appointment.medecin!.lastName == medecin.lastName)) {
          print('TENA IZY A');

            setState(() {
              AppointmentList.add(appointment);
            });


        }
      }

      print('APOINTS TENA IZY SIZE: ${AppointmentList.length}');

      return AppointmentList;
    } catch (e) {
      print('Error initializing appointments: $e');
      return [];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    medecinCliked = ModalRoute.of(context)?.settings.arguments as Medecin;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await getAllAsync();
      listAppointment = await InitierAppointment(medecinCliked!);
      listUnavalaibleAppointment = await getAllUnavalaibleAppointment();
      if(mounted){
        if (listAppointment.isEmpty) {
          setState(() {
            dataLoaded = true;
          });
        }
        setState(() {
          dataLoaded = true;
        });
      }

    });
  }

  Future<List<CustomAppointment>> getAllAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }

    final url = Uri.parse(
        "${baseUrl}api/patients/appointments/${extractLastNumber(widget.patient.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw e;
    }
  }

  late Future<List<UnavalaibleAppointment>> futureAppointmentList;

  @override
  void initState() {
    super.initState();
    initializeCalendar();
  }

  Medecin? medecin;

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

  Medecin? medecinCliked;

  String DateTimeFormatAppointment(DateTime startDateTime, DateTime timeEnd) {
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

  String formatDateTime(DateTime dateTime) {
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
    int jour = dateTime.day;
    int moisIndex = dateTime.month;
    int annee = dateTime.year;
    int heure = dateTime.hour;
    int minute = dateTime.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[dateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeure =
        '${heure.toString().padLeft(2, '0')}h:${minute.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$jourSemaine, $jour $nomMois $annee';

    return resultat;
  }

  bool isClicked = false;

  void AjouterRDV(BuildContext context, DateTime dtClicker, Medecin medecin,
      Patient patient, List<CustomAppointment> appoints) {
    print('APPOINTMENTS LENGTH: ${appoints.length}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Image.asset(
                  'assets/images/date-limite.png',
                  width: 30,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  '${formatDateTime(dtClicker)}',
                  textScaler: TextScaler.linear(0.7),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.black.withOpacity(0.7)),
                )
              ]),
              SizedBox(
                height: 20,
              ),
              Text(
                'Listes des tranches horaires disponibles',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color.fromARGB(230, 20, 20, 90)),
                textScaler: TextScaler.linear(0.7),
              )
            ],
          ),
          content: Container(
            padding: EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: ListView.builder(
                itemCount: (getAvailableAppointments(dtClicker, appoints,
                            medecin, patient, listUnavalaibleAppointment) !=
                        null)
                    ? getAvailableAppointments(dtClicker, appoints, medecin,
                            patient, listUnavalaibleAppointment)!
                        .length
                    : 0,
                itemBuilder: (context, i) {
                  CustomAppointment appointment = getAvailableAppointments(
                          dtClicker,
                          appoints,
                          medecin,
                          patient,
                          listUnavalaibleAppointment)!
                      .elementAt(i);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPageActive = false;
                      });

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ConfirmAppointment(appointment: appointment),
                            settings: RouteSettings(arguments: medecin)),
                        (route) => false,
                      );
                    },
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Text(
                                '${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}',
                                style: const TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.5,
                                    fontSize: 16),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.watch_later,
                              color: Colors.redAccent,
                            )
                          ],
                        ),
                        const Divider(
                          thickness: 1,
                          color: Colors.grey,
                          indent: 10,
                          endIndent: 10,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  );
                }),
          ),
          scrollable: true,
          actions: [
            if (isClicked) ...[
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 20, right: 20),
                child: TextField(),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    isClicked = false;
                  },
                  child: Text('Confirmer'),
                ),
              ),
            ] else ...[
              TextButton(
                child: Text(
                  'Annuler',
                  style: TextStyle(
                      color: Colors.redAccent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ],
        );
      },
    );
  }

  List<CustomAppointment>? getAvailableAppointments(
    DateTime journeeCliquer,
    List<CustomAppointment> appointments,
    Medecin medecin,
    Patient patient,
    List<CustomAppointment> listUnavalaibleAppointment,
  ) {
    /// Verification si la date cliquer en contient déja ou a deja été selectionnée(il y a une tranche déja enregistrée)

    bool isDayAlreadySelected = appointments.any((appointment) =>
        (appointment.startAt.day == journeeCliquer.day) &&
        (appointment.startAt.year == journeeCliquer.year) &&
        (appointment.startAt.month == journeeCliquer.month) &&
        ((appointment.medecin != null &&
                appointment.medecin!.lastName == medecin.lastName) &&
            (appointment.medecin != null &&
                appointment.medecin!.firstName == medecin.firstName)));

    if (!isDayAlreadySelected) {
      List<String> defaultTimeSlots = [
        "08:00-09:00",
        "09:00-10:00",
        "10:00-11:00",
        "11:00-12:00",
        "14:00-15:00",
        "15:00-16:00"
      ];

      DateTime now = DateTime.now();

      if (journeeCliquer.day > now.day) {
        List<CustomAppointment> availableAppointments = defaultTimeSlots
            .map((timeSlot) {
              DateTime startTime = DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
                int.parse(timeSlot.substring(0, 2)),
                0,
              );
              DateTime endTime = DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
                int.parse(timeSlot.substring(6, 8)),
                0,
              );

              return CustomAppointment(
                id: "", // Vous devrez attribuer un identifiant unique ici
                type: "",
                medecin: medecin,
                patient: patient,
                startAt: DateTime(
                  journeeCliquer.year,
                  journeeCliquer.month,
                  journeeCliquer.day,
                ),
                timeStart: startTime,
                timeEnd: endTime,
                reason: "",
                createdAt: DateTime.now(),
                appType: "",
              );
            })
            .where((avalaible) => !listUnavalaibleAppointment.any(
                  (unavalaible) => isUnavalaible(unavalaible, avalaible),
                ))
            .toList();

        return availableAppointments;
      } else {
        List<CustomAppointment> availableAppointments = defaultTimeSlots
            .where((timeSlot) {
              int startHour = int.parse(timeSlot.substring(0, 2));
              DateTime startTime = DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
                startHour,
                0,
              );

              return startTime.isAfter(now) || startTime.hour == now.hour;
            })
            .map((timeSlot) {
              int startHour = int.parse(timeSlot.substring(0, 2));
              DateTime startTime = DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
                startHour,
                0,
              );

              DateTime endTime = DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
                int.parse(timeSlot.substring(6, 8)),
                0,
              );

              return CustomAppointment(
                id: "",
                type: "",
                medecin: medecin,
                patient: patient,
                startAt: DateTime(
                  journeeCliquer.year,
                  journeeCliquer.month,
                  journeeCliquer.day,
                ),
                timeStart: startTime,
                timeEnd: endTime,
                reason: "",
                createdAt: DateTime.now(),
                appType: "",
              );
            })
            .where((avalaible) => !listUnavalaibleAppointment.any(
                  (unavalaible) => isUnavalaible(unavalaible, avalaible),
                ))
            .toList();

        return availableAppointments;
      }
    } else {
      List<String> defaultTimeSlots = [
        "08:00-09:00",
        "09:00-10:00",
        "10:00-11:00",
        "11:00-12:00",
        "14:00-15:00",
        "15:00-16:00"
      ];
      List<CustomAppointment> availableAppointments = defaultTimeSlots
          .map((timeSlot) {
            DateTime startTime = DateTime(
              journeeCliquer.year,
              journeeCliquer.month,
              journeeCliquer.day,
              int.parse(timeSlot.substring(0, 2)),
              0,
            );
            DateTime endTime = DateTime(
              journeeCliquer.year,
              journeeCliquer.month,
              journeeCliquer.day,
              int.parse(timeSlot.substring(6, 8)),
              0,
            );

            return CustomAppointment(
              id: "", // Vous devrez attribuer un identifiant unique ici
              type: "",
              medecin: medecin,
              patient: patient,
              startAt: DateTime(
                journeeCliquer.year,
                journeeCliquer.month,
                journeeCliquer.day,
              ),
              timeStart: startTime,
              timeEnd: endTime,
              reason: "",
              createdAt: DateTime.now(),
              appType: "",
            );
          })
          .where((avalaible) => !appointments.any(
                (toExclude) => isUnavalaible(toExclude, avalaible),
              ))
          .toList();

      return availableAppointments.isNotEmpty ? availableAppointments : null;
    }
  }

  DateTime parseTimeSlot(DateTime startAt, String timeSlot) {
    int startHour = int.parse(timeSlot.substring(0, 2));

    return DateTime(startAt.year, startAt.month, startAt.day, startHour, 0);
  }

  bool isUnavalaible(
      CustomAppointment unavAppointment, CustomAppointment avAppointment) {
    return (DateFormat('yyyy-MM-dd').format(avAppointment.startAt) ==
            DateFormat('yyyy-MM-dd').format(unavAppointment.startAt)) &&
        (TimeOfDay.fromDateTime(avAppointment.timeStart) ==
            TimeOfDay.fromDateTime(unavAppointment.timeStart)) &&
        (TimeOfDay.fromDateTime(avAppointment.timeEnd) ==
            TimeOfDay.fromDateTime(unavAppointment.timeEnd)) &&
        ((avAppointment.medecin?.lastName ==
                unavAppointment.medecin?.lastName) &&
            (avAppointment.medecin?.firstName ==
                unavAppointment.medecin?.firstName));
  }

  CalendarController controller = CalendarController();

  List<DateTime> getWeekdaysInMonth(int year, int month) {
    List<DateTime> weekdays = [];

    // Calculer le premier jour du mois
    DateTime firstDayOfMonth = DateTime(year, month, 1);

    // Si le premier jour est un week-end, trouver le premier jour de la semaine suivante
    if (firstDayOfMonth.weekday == DateTime.saturday) {
      firstDayOfMonth = firstDayOfMonth.add(Duration(days: 2));
    } else if (firstDayOfMonth.weekday == DateTime.sunday) {
      firstDayOfMonth = firstDayOfMonth.add(Duration(days: 1));
    }

    // Calculer le dernier jour du mois
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

    // Parcourir tous les jours du mois
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      DateTime currentDay = firstDayOfMonth.add(Duration(days: i));

      // Exclure les samedis et dimanches (7 correspond à dimanche, 6 à samedi)
      if (currentDay.weekday != DateTime.saturday &&
          currentDay.weekday != DateTime.sunday) {
        weekdays.add(currentDay);
      }
    }
    weekdays.forEach((element) {
      print('DAY: $element');
    });
    return weekdays;
  }

  List<CustomAppointment> list = [];

  bool isDisabled(List<CustomAppointment> listAppointment) {
    bool isDisabled = false;
    listAppointment.forEach((element) {
      if (element.appType == "Desactiver") {
        isDisabled = true;
      } else {
        isDisabled = false;
      }
    });
    return isDisabled;
  }

  bool isInBlackOutDay(List<DateTime> listBlackOut, DateTime day) {
    bool isIn = false;
    for (int d = 0; d < listBlackOut.length; d++) {
      if ((DateFormat('yyyy-MM-dd').format(day)) ==
          DateFormat('yyyy-MM-dd').format(listBlackOut.elementAt(d))) {
        isIn = true;
      }
    }

    return isIn;
  }

  DateTime? isSunday(DateTime dt) {
    if (dt.weekday == 7) {
      return dt;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> blackoutDates = [];

    DateTime currentDate = DateTime.now().subtract(Duration(days: 1));

    blackoutDates.addAll(List.generate(
        365, (index) => currentDate.subtract(Duration(days: index))));
    //blackoutDates.addAll(List.generate(365, (index) => isSunday(currentDate.add(Duration(days: index)))!));

    if (DateTime.now().hour > 15) {
      blackoutDates.add(DateTime.now());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: Color.fromARGB(1000, 238, 239, 244),
          body: ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, left: 10),
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
                                builder: (context) => IndexAccueil()));
                      },
                    ),
                    Spacer(),
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          child: Image.asset(
                            "assets/images/logo2.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(right: 18, left: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Container(
                      height: 100,
                      child: Card(
                        elevation: 0.5,
                        color: Colors.white,
                        child: Column(
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child:
                                        ((medecinCliked!.imageName != null) &&
                                                (File(medecinCliked!.imageName!)
                                                    .existsSync()))
                                            ? Image.file(
                                                File(medecinCliked!.imageName!))
                                            : Image.asset(
                                                'assets/images/medecin.png',
                                                fit: BoxFit.fill,
                                              ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      ' Dr ${abbreviateName(medecinCliked!.lastName)}.${abbreviateName(medecinCliked!.firstName)}',
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(1000, 60, 70, 120),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          letterSpacing: 2),
                                    ),
                                    Text(
                                      '${medecinCliked!.speciality!.label}',
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(1000, 60, 70, 120),
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 2,
                                          fontSize: 16),
                                    )
                                  ],
                                ),
                                Spacer()
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
                          ],
                        ),
                      ),
                    ),
                  )),
              Padding(
                  padding: const EdgeInsets.only(
                      top: 20, right: 10, left: 10, bottom: 30),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white),
                        width: MediaQuery.of(context).size.width - 45,
                        height: MediaQuery.of(context).size.height / 1.4,
                        child: (dataLoaded)
                            ? SfCalendar(
                                controller: controller,
                                dataSource: CustomAppointmentDataSource(
                                    listAppointment),
                                view: CalendarView.month,
                                scheduleViewSettings:
                                    const ScheduleViewSettings(
                                        appointmentTextStyle: TextStyle(
                                            letterSpacing: 2,
                                            color: Colors.green)),
                                monthCellBuilder: (BuildContext context,
                                    MonthCellDetails details) {
                                  // Personnalisez le contenu de la cellule ici

                                  bool isSundayOrPastDate =
                                      (details.date.weekday == 7) ||
                                          (details.date.isBefore(DateTime.now()
                                              .subtract(Duration(days: 1))));
                                  bool isAllDisabled =
                                      (getAvailableAppointments(
                                              details.date,
                                              listAppointment,
                                              medecinCliked!,
                                              widget.patient,
                                              listUnavalaibleAppointment)!
                                          .isEmpty);

                                  bool dt = blackoutDates.any(
                                      (element) => element == details.date);

                                  if (dt == false) {
                                    isAllDisabled
                                        ? blackoutDates.add(details.date)
                                        : null;
                                  }
                                  if (isSunday(details.date) != null) {
                                    blackoutDates.add(details.date);
                                  }

                                  bool isBlackoutDate = isInBlackOutDay(
                                      blackoutDates, details.date);

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isBlackoutDate
                                          ? Colors.grey.withOpacity(0.3)
                                          : Colors.transparent,
                                      border: Border.all(
                                          width: 0.3, color: Colors.grey),
                                    ),
                                    child: Column(
                                      children: [
                                        Center(
                                          child: Text(
                                            details.date.day.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 1.6,
                                              color: isBlackoutDate
                                                  ? Colors.grey.withOpacity(0.3)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        // Exclure l'affichage des rendez-vous pour les blackoutDates
                                        if (!isBlackoutDate &&
                                            !isSundayOrPastDate)
                                          ...listAppointment
                                              .where((appointment) =>
                                                  appointment.startAt.year ==
                                                      details.date.year &&
                                                  appointment.startAt.month ==
                                                      details.date.month &&
                                                  appointment.startAt.day ==
                                                      details.date.day)
                                              .map((appointment) =>
                                                  buildAppointmentWidget(
                                                      appointment)),
                                      ],
                                    ),
                                  );
                                },
                                onTap: (CalendarTapDetails details) {
                                  bool foundMatchingAppointment = false;

                                  for (int a = 0;
                                      a < listAppointment.length;
                                      a++) {
                                    CustomAppointment myAppointment =
                                        listAppointment.elementAt(a);

                                    if (DateFormat('yyyy-MM-dd')
                                            .format(myAppointment.startAt) ==
                                        DateFormat('yyyy-MM-dd')
                                            .format(details.date!)) {
                                      DetailsAppointment(myAppointment);
                                      foundMatchingAppointment = true;
                                      break;
                                    }
                                  }

                                  if (isInBlackOutDay(
                                          blackoutDates, details.date!) ==
                                      false) {
                                    if (!foundMatchingAppointment) {
                                      AjouterRDV(
                                          context,
                                          details.date!,
                                          medecinCliked!,
                                          widget.patient,
                                          listAppointment);
                                    }
                                  } else {
                                    jourDisable();
                                  }
                                },
                                todayTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.6,
                                  color: Color.fromARGB(230, 20, 20, 90),
                                ),
                                blackoutDates: blackoutDates,
                              )
                            : Center(child: CircularProgressIndicator()),
                      ))),
            ],
          )),
    );
  }

  Widget buildAppointmentWidget(CustomAppointment appointment) {
    return Container(
        // Personnalisez le widget en fonction des propriétés de l'objet CustomAppointment
        child: Expanded(
            child: Container(
      width: 15, // ajustez la taille du point en fonction de vos besoins
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appointment.color
            .withOpacity(0.7), // utilisez la couleur de l'appointment
      ),
    )));
  }

  String DateTimeAppointmentFormat(
      DateTime startAt, DateTime startDateTime, DateTime timeEnd) {
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

    int jour = startAt.day;
    int moisIndex = startAt.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startAt.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat =
        '$jourSemaine, $jour $nomMois  $formatHeureStart-$formatHeureEnd';

    return resultat;
  }

  void DetailsAppointment(CustomAppointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: EdgeInsets.all(0),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: MediaQuery.of(context).size.width - 10,
                height: 600,
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.only(top: 20, left: 20, bottom: 50),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                                width: 100,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: ((appointment.medecin!.imageName !=
                                            null) &&
                                        (File(appointment.medecin!.imageName!)
                                            .existsSync()))
                                    ? Image.file(
                                        File(appointment.medecin!.imageName!),
                                        fit: BoxFit.fill,
                                      )
                                    : Image.asset('assets/images/medecin.png')),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Dr ${abbreviateName(appointment.medecin!.lastName)} \n ${abbreviateName(appointment.medecin!.firstName)}',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.start,
                                maxLines:
                                    2, // Nombre maximal de lignes avant de tronquer
                                overflow: TextOverflow
                                    .ellipsis, // Que faire en cas de dépassement des lignes maximales
                                softWrap:
                                    true, // Permettre le retour à la ligne automatique
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    Padding(
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
                        padding: EdgeInsets.only(top: 20, right: 20),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Raison:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                '${appointment.reason}',
                                style: TextStyle(
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
                        padding: EdgeInsets.only(top: 30, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Le:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Spacer(),
                            Text(
                              '  ${formatDateTimeAppointment(appointment.startAt.toLocal(), appointment.timeStart, appointment.timeEnd.toLocal())}',
                              style: TextStyle(
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
                        padding: EdgeInsets.only(top: 20, right: 20),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'De:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${DateTimeFormatAppointment(appointment.startAt, appointment.timeEnd)}',
                              style: TextStyle(
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
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 200,
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Fermer',
                          style: TextStyle(
                            letterSpacing: 2,
                            color: Color.fromARGB(230, 20, 20, 90),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ));
      },
    );
  }

  void jourDisable() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      surfaceTintColor: Color.fromARGB(230, 20, 20, 90),
      content: AwesomeSnackbarContent(
        title: 'Aide!!',
        message: 'Cette date n\'est plus disponible!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.help,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void RdvValider() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Rendez-vous enregistré',

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
}
