import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'IndexAccueil.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/CustomAppointmentDataSource.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/Patient.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'dart:io';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:intl/intl.dart';
import 'ConfirmAppointment.dart';
import 'package:med_scheduler_front/UnavalaibleAppointment.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'MedecinDetails.dart';

class PriseDeRendezVous extends StatefulWidget {
  final Patient patient;

  PriseDeRendezVous({required this.patient});

  _PriseDeRendezVousState createState() => _PriseDeRendezVousState();
}

class _PriseDeRendezVousState extends State<PriseDeRendezVous> {
  UserRepository? userRepository;
  Utilities? utilities;

  Future<void> initializeCalendar() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Indian/Antananarivo'));

    DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
    var calendars = await deviceCalendarPlugin.retrieveCalendars();

    if (calendars.data!.isEmpty) {
      return;
    }

    var defaultCalendarId = calendars.data!.first.id;

    try {
      List<CustomAppointment> appoints = await getProcheRendezVous(
          await userRepository!.getAllAppointmentByUserPatient(widget.patient));

      if (appoints.isNotEmpty) {
        appoints.forEach((element) async {
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
          }
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
      throw const FormatException("Aucun nombre trouvé dans la chaîne.");
    }
  }

  Future<List<CustomAppointment>> InitierAppointment(Medecin medecin) async {
    DateTime now = DateTime.now();
    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }
    try {
      List<CustomAppointment> appointmentList =
          await userRepository!.getAllAppointmentByUserPatient(widget.patient);
      List<CustomAppointment> AppointmentList = [];
      for (int a = 0; a < appointmentList.length; a++) {
        CustomAppointment appointment = appointmentList.elementAt(a);

        if ((appointment.medecin!.firstName == medecin.firstName) &&
            (appointment.medecin!.lastName == medecin.lastName) &&
            (appointment.startAt.year >= now.year &&
                appointment.startAt.month >= now.month &&
                appointment.startAt.isAfter(now.subtract(Duration(days: 1))))) {
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
    calculateBlackoutDates();
    medecinCliked = ModalRoute.of(context)?.settings.arguments as Medecin;
    initializeCalendar();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await getAllAsync();
      listAppointment = await InitierAppointment(medecinCliked!);
      if (mounted) {
        listUnavalaibleAppointment =
            await userRepository!.getAllUnavalaibleAppointment(medecinCliked!);
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

  late Future<List<UnavalaibleAppointment>> futureAppointmentList;

  @override
  void initState() {
    super.initState();
    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);

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
                const SizedBox(
                  width: 10,
                ),
                Text(
                  '${formatDateTime(dtClicker)}',
                  textScaler: const TextScaler.linear(0.7),
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.black.withOpacity(0.7)),
                )
              ]),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Listes des tranches horaires disponibles',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color.fromARGB(230, 20, 20, 90)),
                textScaler: TextScaler.linear(0.7),
              )
            ],
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
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
                              padding: const EdgeInsets.only(left: 15),
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
                  child: const Text('Confirmer'),
                ),
              ),
            ] else ...[
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
      firstDayOfMonth = firstDayOfMonth.add(const Duration(days: 2));
    } else if (firstDayOfMonth.weekday == DateTime.sunday) {
      firstDayOfMonth = firstDayOfMonth.add(const Duration(days: 1));
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

  bool isSunday(DateTime dt) {
    if (dt.weekday == 7) {
      return true;
    } else {
      return false;
    }
  }

  List<DateTime> blackoutDates = [];
  List<DateTime> getSundayDates() {
    List<DateTime> sundays = [];
    DateTime startDate = DateTime(DateTime.now().year, 1, 1);
    DateTime endDate = DateTime(DateTime.now().year, 12, 31);

    for (DateTime date = startDate;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.sunday) {
        sundays.add(date);
      }
    }

    return sundays;
  }

  void calculateBlackoutDates() {
    DateTime currentDate = DateTime.now().subtract(const Duration(days: 1));
    blackoutDates.addAll(List.generate(
        365, (index) => currentDate.subtract(Duration(days: index))));

    for (int dtIndex = 0; dtIndex < getSundayDates().length; dtIndex++) {
      DateTime dt = getSundayDates().elementAt(dtIndex);
      if (!blackoutDates.contains(dt)) {
        blackoutDates.add(dt);
      }
    }

    if (DateTime.now().hour > 15) {
      if (!blackoutDates.contains(DateTime.now())) {
        blackoutDates.add(DateTime.now());
      }
    }
  }


  String desc = '';

  String showDesc(String desc){
    List<String> listDesc = desc.split(" ");

    if(listDesc.length>3){
      return '${listDesc[0]} ${listDesc[1]} ${listDesc[2]}...';
    }else if(listDesc.length==1){
      return listDesc.first;
    }else if(listDesc.length==0){
      return "";
    }else{
      return listDesc[0];
    }

  }

  bool dateIsAllDisabled(DateTime date) {
    return (getAvailableAppointments(date, listAppointment, medecinCliked!,
            widget.patient, listUnavalaibleAppointment)!
        .isEmpty);
  }

  bool isAppointment = false;
  bool istoAddAppointment = false;
  bool isPaste = false;

  CustomAppointment? theAppoint;
  DateTime dtCliquer = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => IndexAccueil()));
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
                padding: const EdgeInsets.only(right: 18, left: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: GestureDetector(
                    onTap: (){
                      print('${medecinCliked!.lastName}');
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>MedecinDetails(user: medecinCliked!)));
                    },
                    child:  Container(
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
                            child: CachedNetworkImage(
                                imageUrl:
                                '$baseUrl${utilities!.ajouterPrefixe(medecinCliked!.imageName!)}',
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
                      Column(
                        children: [
                          Text(
                            ' Dr ${abbreviateName(medecinCliked!.lastName)}.${abbreviateName(medecinCliked!.firstName)}',
                            overflow: TextOverflow.fade,
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
                      const Spacer()
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
                  )
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
                          ? ListView(
                              children: [
                                Container(
                                    height:
                                        MediaQuery.of(context).size.height / 2,
                                    child: SfCalendar(
                                      minDate: DateTime.now(),
                                      dataSource: CustomAppointmentDataSource(
                                          listAppointment),
                                      blackoutDatesTextStyle: TextStyle(
                                          color: Colors.grey.withOpacity(0.3)),
                                      view: CalendarView.month,
                                      todayHighlightColor: (DateTime.now().hour>15)?Colors.transparent:Colors.redAccent,
                                      onTap: (CalendarTapDetails details) {
                                        bool dt = blackoutDates.any((element) =>
                                            element == details.date);

                                        bool isAllDisabled =
                                            dateIsAllDisabled(details.date!);
                                        print('IS ALL: $isAllDisabled');

                                        if (dt == false) {
                                          isAllDisabled
                                              ? blackoutDates.add(details.date!)
                                              : null;
                                        }

                                        bool isBlackoutDate = isInBlackOutDay(
                                            blackoutDates, details.date!);


                                        setState(() {
                                          dtCliquer = details.date!;
                                        });
                                        if (isBlackoutDate) {

                                          setState(() {

                                            isAppointment = false;
                                            istoAddAppointment = false;
                                          });
                                          jourDisable();
                                        } else {
                                          List<CustomAppointment> list =
                                              listAppointment
                                                  .where((element) =>
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(element
                                                              .startAt) ==
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(
                                                              details.date!))
                                                  .toList();
                                          if (list.length == 1) {
                                            CustomAppointment appoint =
                                                list.first;
                                            setState(() {
                                              istoAddAppointment = false;
                                              isAppointment = true;
                                              theAppoint = appoint;
                                            });
                                          } else if (list.length > 1) {

                                          } else {
                                            String dtClick =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(details.date!);
                                            String now =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(DateTime.now());
                                            DateTime dt =
                                                DateTime.parse(dtClick);
                                            DateTime dtNow =
                                                DateTime.parse(dtClick);
                                            if (dt.isBefore(dtNow)) {
                                              jourDisable();
                                            } else {
                                              setState(() {
                                                istoAddAppointment = true;
                                                isAppointment = false;
                                              });
                                            }
                                          }
                                        }
                                      },
                                      blackoutDates: blackoutDates,
                                    )),
                                const SizedBox(
                                  height: 40,
                                ),
                                if (isAppointment) ...[
                                  showAppointment(theAppoint!, dtCliquer),
                                ],
                                if (istoAddAppointment) ...[
                                  addAppointment(dtCliquer),
                                ] else if (!isAppointment &&
                                    !istoAddAppointment) ...[
                                  showNothing()
                                ]
                              ],
                            )
                          : loadingWidget(),
                    ))),
          ],
        ),
      ),
    );
  }

  Widget showNothing() {
    return Column(
      children: [
        GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20),
                  child: Text(
                    'Veuillez choisir une date',
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        letterSpacing: 3,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                )
              ],
            )),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Divider(
            thickness: 2,
            color: Colors.grey.withOpacity(0.5),
            indent: 20,
            endIndent: 20,
          ),
        ),
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

  Widget addAppointment(DateTime dt) {
    return Row(children: [
      Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Text(
                '${dt.day}',
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Text(
                '${formatDT(dt)}',
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            )
          ],
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () {
          print('ADD');
          AjouterRDV(
              context, dt, medecinCliked!, widget.patient, listAppointment);
        },
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.redAccent
                .withOpacity(0.7), // utilisez la couleur de l'appointment
          ),
          child: const Icon(
            Icons.add,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(
        width: 20,
      )
    ]);
  }

  Widget showAppointment(CustomAppointment appoint, DateTime clickedDt) {
    return GestureDetector(
        onTap: () {
          DetailsAppointment(appoint);
        },
        child: Row(
          children: [
            Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      '${clickedDt.day}',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      '${formatDT(clickedDt)}',
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.30,
              height: (appoint.isDeleted != null && appoint.isDeleted == true)
                  ? 95
                  : 55,
              // ajustez la taille du point en fonction de vos besoins

              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(6),
                color: (appoint.isDeleted != null && appoint.isDeleted == true)
                    ? Color.fromARGB(1000, 238, 239, 244)
                    : Colors.redAccent.withOpacity(
                        0.7), // utilisez la couleur de l'appointment
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          textAlign: TextAlign.start,
                          '${abreviateRaison(appoint.reason)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              fontSize: 15,
                              color: (appoint.isDeleted != null &&
                                      appoint.isDeleted == true)
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          textAlign: TextAlign.start,
                          '${formatDateTimeAppointment(appoint.startAt, appoint.timeStart, appoint.timeEnd)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              letterSpacing: 2,
                              color: (appoint.isDeleted != null &&
                                      appoint.isDeleted == true)
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (appoint.isDeleted != null &&
                      appoint.isDeleted == true) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            textAlign: TextAlign.start,
                            maxLines: 3,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            'Rendez-vous annulé \nVeuillez contacter votre médecin',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 2,
                                color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ));
  }

  String formatDT(DateTime Date) {
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
      'JAN',
      'FEV',
      'MAR',
      'AVR',
      'MAI',
      'JUI',
      'JUI',
      'AOU',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];

    // Extraire les composants de la date et de l'heure
    int jour = Date.day;
    int moisIndex = Date.month;
    int annee = Date.year;

    // Formater le jour de la semaine
    String jourSemaine = jours[Date.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Construire la chaîne lisible
    String resultat = '$nomMois';

    return resultat;
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
            contentPadding: const EdgeInsets.all(0),
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
                          padding: const EdgeInsets.only(
                              top: 20, left: 20, bottom: 50),
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
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Dr ${abbreviateName(appointment.medecin!.lastName)} \n ${abbreviateName(appointment.medecin!.firstName)}',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black.withOpacity(0.6)),
                                textAlign: TextAlign.start,
                                maxLines:
                                    2, // Nombre maximal de lignes avant de tronquer
                                overflow: TextOverflow
                                    .ellipsis, // Que faire en cas de dépassement des lignes maximales
                                softWrap:
                                    true, // Permettre le retour à la ligne automatique
                              ),
                              Text(
                                '${abbreviateName(appointment.medecin!.speciality!.label)}',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black.withOpacity(0.5)),
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
                              '${DateTimeFormatAppointment(appointment.startAt, appointment.timeEnd)}',
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
                              ' ${formatDateTimeAppointment(appointment.startAt.toLocal(), appointment.timeStart, appointment.timeEnd.toLocal())}',
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
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            right: 10,
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Fermer',
                              style: TextStyle(
                                letterSpacing: 2,
                                color: Color.fromARGB(230, 20, 20, 90),
                              ),
                            ),
                          ),
                        )
                      ],
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
      surfaceTintColor: const Color.fromARGB(230, 20, 20, 90),
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
