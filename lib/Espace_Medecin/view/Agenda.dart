import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/CustomAppointmentDataSource.dart';
import 'dart:io';
import 'AppointmentDialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_calendar/device_calendar.dart';
import 'package:med_scheduler_front/main.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/MedecinRepository.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/AuthProviderUser.dart';


class Agenda extends StatefulWidget {


  @override
  AgendaState createState() => AgendaState();
}

class AgendaState extends State<Agenda> {
  late AuthProvider authProvider;
  late String token;

  MedecinRepository? medecinRepository;
  BaseRepository? baseRepository;
  Utilities? utilities;

  Utilisateur? user;
  Medecin? widgetMedecin;


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
      List<CustomAppointment> appoints =
          await getProcheRendezVous(await medecinRepository!.getAllAppointmentMedecin(widgetMedecin!));

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
                ? '${element.reason.toUpperCase()} avec le patient ${element.patient!.lastName} ${element.patient!.firstName}.'
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    medecinRepository = MedecinRepository(context: context, utilities: utilities!);
    baseRepository = BaseRepository(context: context, utilities: utilities!);

  }

  List<CustomAppointment> listAppointment = [];
  List<CustomAppointment> listUnavalaibleAppointment = [];

  String baseUrl = UrlBase().baseUrl;

  bool dataLoaded = false;

  List<CustomAppointment> getAllAppointmentAfterToday(
      List<CustomAppointment> appoints) {
    List<CustomAppointment> appointments = [];
    for (int a = 0; a < appoints.length; a++) {
      CustomAppointment appoint = appoints.elementAt(a);
      if (appoint.startAt.year >= DateTime.now().year &&
          appoint.startAt.month >= DateTime.now().month &&
          appoint.startAt.day >= DateTime.now().day) {
        appointments.add(appoint);
      }
    }
    return appointments;
  }

  List<CustomAppointment> getAllUnavalaibleDesactivateByDateAndMedecin(
      List<CustomAppointment> list, DateTime dt) {
    List<CustomAppointment> filteredList = [];
    String formatDt = DateFormat('yyyy-MM-dd').format(dt);
    for (int val = 0; val < list.length; val++) {
      CustomAppointment appointment = list.elementAt(val);
      if ((appointment.appType == "Desactiver") &&
          (DateFormat('yyyy-MM-dd').format(appointment.startAt) == formatDt)) {
        filteredList.add(appointment);
      }
    }

    return filteredList;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    calculateBlackoutDates();

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    user = Provider.of<AuthProviderUser>(context).utilisateur;
    widgetMedecin = Medecin(id: user!.id, roles: user!.roles, speciality: user!.speciality, lastName: user!.lastName, firstName: user!.firstName, userType: user!.userType, phone: user!.phone, email: user!.email, address: user!.address, center: user!.center, createdAt: user!.createdAt, city: user!.city);
    token = authProvider.token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await getAllAsync();

      listAppointment = await medecinRepository!.getAllAppointmentMedecin(widgetMedecin!);
      listUnavalaibleAppointment = await baseRepository!.getAllUnavalaibleAppointment(widgetMedecin!);
      if (listAppointment.isEmpty) {
        setState(() {
          dataLoaded = true;
        });
      }
      setState(() {
        dataLoaded = true;
      });
    });
  }

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;
      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw FormatException("Aucun nombre trouvé dans la chaîne.");
    }
  }





  CalendarController controller = CalendarController();

  List<DateTime> blackoutDates = [];

  List<CustomAppointment>? getAvailableAppointments(
    DateTime journeeCliquer,
    List<CustomAppointment> appointments,
    Medecin medecin,
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
                patient: null,
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
                patient: null,
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
              patient: null,
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
    print('START HOUR PARSED: $startHour');
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

  DateTime? isSunday(DateTime dt) {
    if (dt.weekday == 7) {
      return dt;
    } else {
      return null;
    }
  }

  List<DateTime> getSundayDates() {
    List<DateTime> sundays = [];
    DateTime startDate = DateTime(DateTime.now().year, 1, 1);
    DateTime endDate = DateTime(DateTime.now().year, 12, 31);

    for (DateTime date = startDate;
        date.isBefore(endDate);
        date = date.add(Duration(days: 1))) {
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

  bool dateIsAllDisabled(DateTime date) {
    return (getAvailableAppointments(
            date, listAppointment, widgetMedecin!, listUnavalaibleAppointment)!
        .isEmpty);
  }

  bool isAppointment = false;
  bool istoAddAppointment = false;
  bool isPaste = false;

  List<CustomAppointment> AlltheAppoint = [];
  DateTime dtCliquer = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: Color.fromARGB(1000, 238, 239, 244),
          body: ListView(children: [
            Row(
              children: [
                Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        const Opacity(
                          opacity: 0.5,
                          child: Text(
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.linear(1.3),
                            'Bonjour,',
                            style: TextStyle(
                                letterSpacing: 2, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.center,
                          textScaler: const TextScaler.linear(1.45),
                          'Dr ${widgetMedecin!.firstName ?? 'Chargement...'}',
                          style: const TextStyle(
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
                padding: const EdgeInsets.only(
                    top: 10, right: 10, left: 10, bottom: 10),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white),
                        width: MediaQuery.of(context).size.width - 45,
                        height: MediaQuery.of(context).size.height / 1.38,
                        child: (dataLoaded)
                            ? Column(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.height /
                                        2.2,
                                    child: SfCalendar(
                                      blackoutDatesTextStyle: TextStyle(
                                          color: Colors.grey.withOpacity(0.3)),
                                      minDate: DateTime(DateTime.now().year,
                                          DateTime.now().month, 01),
                                      controller: controller,
                                      dataSource: CustomAppointmentDataSource(
                                          listAppointment),
                                      view: CalendarView.month,
                                      monthViewSettings:
                                          const MonthViewSettings(
                                        appointmentDisplayCount: 3,
                                      ),
                                      scheduleViewSettings:
                                          const ScheduleViewSettings(
                                              appointmentTextStyle: TextStyle(
                                                  letterSpacing: 2,
                                                  color: Colors.green)),
                                      onTap: (CalendarTapDetails details) {
                                        setState(() {
                                          dtCliquer = details.date!;
                                        });
                                        if (details.date!.weekday != 7) {
                                          if ((details.date!.year <=
                                                  DateTime.now().year) &&
                                              (details.date!.month <=
                                                  DateTime.now().month) &&
                                              (details.date!.day <
                                                  DateTime.now().day)) {
                                            jourDisable();
                                          } else {
                                            //Navigator.push(context, MaterialPageRoute(builder: (context)=>AppointmentDialog(medecin: medecinClicked!),settings: RouteSettings(arguments: details.date)));
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
                                            if (list.length >= 1) {
                                              CustomAppointment appoint =
                                                  list.first;
                                              setState(() {
                                                istoAddAppointment = false;
                                                isAppointment = true;
                                                AlltheAppoint = list;
                                              });
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
                                        } else {
                                          jourSundayDisable();
                                        }
                                      },
                                      todayHighlightColor: Colors.redAccent,
                                      todayTextStyle: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.6,
                                        color: Colors.white,
                                      ),
                                      blackoutDates: blackoutDates,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Expanded(
                                      child: ListView(
                                    children: [
                                      if (isAppointment) ...[
                                        for (int ap = 0;
                                            ap < AlltheAppoint.length;
                                            ap++) ...[
                                          if (ap == 0) ...[
                                            showAppointment(
                                                AlltheAppoint.elementAt(ap),
                                                dtCliquer),
                                          ] else ...[
                                            showAppointmentAfterFirst(
                                                AlltheAppoint.elementAt(ap),
                                                dtCliquer)
                                          ]
                                        ],
                                        Row(
                                          children: [
                                            Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10,
                                                  right: 16,
                                                  bottom: 10),
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          const Color.fromARGB(
                                                              1000,
                                                              60,
                                                              70,
                                                              120)),
                                                  shape:
                                                      MaterialStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.0), // Définissez le rayon de la bordure ici
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      MaterialStateProperty.all(
                                                          const Size(
                                                              300.0, 40.0)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AppointmentDialog(
                                                                  medecin:widgetMedecin!),
                                                          settings: RouteSettings(
                                                              arguments:
                                                                  dtCliquer)));
                                                },
                                                child: const Text(
                                                  'Voir tranches horaires',
                                                  textAlign: TextAlign.start,
                                                  textScaleFactor: 1.2,
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 253, 253, 253),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                      if (istoAddAppointment) ...[
                                        Row(
                                          children: [
                                            Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10,
                                                  right: 16,
                                                  bottom: 10),
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          const Color.fromARGB(
                                                              1000,
                                                              60,
                                                              70,
                                                              120)),
                                                  shape:
                                                      MaterialStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.0), // Définissez le rayon de la bordure ici
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      MaterialStateProperty.all(
                                                          const Size(
                                                              300.0, 40.0)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AppointmentDialog(
                                                                  medecin: widgetMedecin!),
                                                          settings: RouteSettings(
                                                              arguments:
                                                                  dtCliquer)));
                                                },
                                                child: const Text(
                                                  'Voir tranches horaires',
                                                  textAlign: TextAlign.start,
                                                  textScaleFactor: 1.2,
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 253, 253, 253),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ] else if (!isAppointment &&
                                          !istoAddAppointment) ...[
                                        showNothing()
                                      ]
                                    ],
                                  ))
                                ],
                              )
                            : loadingWidget()))),
          ])),
    );
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

  Widget showNothing() {
    return Column(
      children: [
        GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20, top: 20),
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
          padding: EdgeInsets.only(top: 5),
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

  Widget showAppointment(CustomAppointment appoint, DateTime clickedDt) {
    print('ISDELETED: ${appoint.isDeleted} ');

    return Column(
      children: [
        GestureDetector(
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
                  height:
                      (appoint.isDeleted != null && appoint.isDeleted == true)
                          ? 75
                          : 55,
                  // ajustez la taille du point en fonction de vos besoins

                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                    color:
                        (appoint.isDeleted != null && appoint.isDeleted == true)
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
                                'Rendez-vous annulé',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
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

  Widget showAppointmentAfterFirst(
      CustomAppointment appoint, DateTime clickedDt) {
    print('ISDELETED: ${appoint.isDeleted} ');

    return Column(
      children: [
        GestureDetector(
            onTap: () {
              DetailsAppointment(appoint);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Container(
                width: MediaQuery.of(context).size.width / 1.30,
                height: 55,
                // ajustez la taille du point en fonction de vos besoins

                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  color:
                      (appoint.isDeleted != null && appoint.isDeleted == true)
                          ? Colors.black.withOpacity(0.3)
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                                fontSize: 15,
                                color: Colors.white),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 2,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
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

  void RdvDesactiver() {
    SnackBar snackBar = SnackBar(
      content: Flex(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        direction: Axis.horizontal,
        children: [
          Text(
            'Rendez-vous desctiver',
            textScaleFactor: 1.4,
            style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                letterSpacing: 4),
            textAlign: TextAlign.center,
          ),
          Icon(
            Icons.check,
            color: Colors.green,
          )
        ],
      ),
      elevation: 4,
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        message: 'Cette  n\'est plus disponible.',

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

  void jourSundayDisable() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      surfaceTintColor: Color.fromARGB(230, 20, 20, 90),
      content: AwesomeSnackbarContent(
        title: 'Aide!!',
        message: 'Dimanche n\'est pas disponible.',

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
}
