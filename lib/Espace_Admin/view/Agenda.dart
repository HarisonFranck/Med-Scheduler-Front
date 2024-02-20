import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/CustomAppointmentDataSource.dart';
import 'dart:io';
import 'IndexAccueilAdmin.dart';
import 'AppointmentDialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/AuthProviderUser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class Agenda extends StatefulWidget {
  AgendaState createState() => AgendaState();
}

class AgendaState extends State<Agenda> {
  late AuthProvider authProvider;
  late String token;
  late AuthProviderUser authProviderUser;

  bool _isPageActive = true;

  BaseRepository? baseRepository;
  Utilities? utilities;

  double AppointWidth = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _isPageActive = false;
    super.dispose();

    print('--- DESTRUCTION PAGE ---');
  }

  List<CustomAppointment> listAppointment = [];
  List<CustomAppointment> listUnavalaibleAppointment = [];

  String baseUrl = UrlBase().baseUrl;

  Medecin? medecinClicked;

  bool dataLoaded = false;

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
    print('FETCH DEPENDENCIES');
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    medecinClicked = ModalRoute.of(context)?.settings.arguments as Medecin;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await getAllAsync();

      listAppointment =
          await baseRepository!.getAllAppointmentByMedecin(medecinClicked!);
      listUnavalaibleAppointment =
          await baseRepository!.getAllUnavalaibleAppointment(medecinClicked!);
      if (listAppointment.isEmpty) {
        print('EMPTY O');
        setState(() {
          dataLoaded = true;
        });
      }
      setState(() {
        dataLoaded = true;
      });
    });
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

  bool dateIsAllDisabled(DateTime date) {
    return (getAvailableAppointments(
            date, listAppointment, medecinClicked!, listUnavalaibleAppointment)!
        .isEmpty);
  }

  bool isAppointment = false;
  bool istoAddAppointment = false;
  bool isPaste = false;

  List<CustomAppointment> AlltheAppoint = [];
  DateTime dtCliquer = DateTime.now();

  @override
  Widget build(BuildContext context) {
    AppointWidth = MediaQuery.of(context).size.width / 1.40;
    print('AppointWidth: $AppointWidth');

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                      authProviderUser.logout();
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
                  child: Container(
                    height: 95,
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
                                        '$baseUrl${utilities!.ajouterPrefixe(medecinClicked!.imageName!)}',
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
                                    ' Dr ${abbreviateName(medecinClicked!.lastName)}.${abbreviateName(medecinClicked!.firstName)}',
                                    style: const TextStyle(
                                        color:
                                            Color.fromARGB(1000, 60, 70, 120),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        letterSpacing: 2),
                                  ),
                                  Text(
                                    '${(medecinClicked!.speciality != null) ? medecinClicked!.speciality!.label : ''}',
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
                )),
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
                                        listAppointment.forEach((element) {
                                          print(
                                              'APPOINTMENT : ${element.timeStart.hour}, ${element.reason} ');
                                        });

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
                                      todayHighlightColor:
                                          (DateTime.now().hour > 15)
                                              ? Colors.transparent
                                              : Colors.redAccent,
                                      todayTextStyle: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.6,
                                        color: Colors.white,
                                      ),
                                      blackoutDates: blackoutDates,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Expanded(
                                      child: ListView(
                                    physics: BouncingScrollPhysics(),
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
                                            Container(
                                              width: 60,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
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
                                                          Size(AppointWidth,
                                                              40.0)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AppointmentDialog(
                                                                  medecin:
                                                                      medecinClicked!),
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
                                            Spacer(),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 20,
                                        )
                                      ],
                                      if (istoAddAppointment) ...[
                                        Row(
                                          children: [
                                            Container(
                                              width: 60,
                                            ),
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
                                                          Size(AppointWidth,
                                                              40.0)),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AppointmentDialog(
                                                                  medecin:
                                                                      medecinClicked!),
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

  Widget showAppointment(CustomAppointment appoint, DateTime clickedDt) {
    return Column(
      children: [
        GestureDetector(
            onTap: () {
              DetailsAppointment(appoint);
            },
            child: Row(
              children: [
                Container(
                  width: 60,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 10),
                        child: Text(
                          '${clickedDt.day}',
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.4),
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 10),
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
                  width: AppointWidth,
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
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 60,
            ),
            GestureDetector(
                onTap: () {
                  DetailsAppointment(appoint);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Container(
                    width: AppointWidth,
                    height:
                        (appoint.isDeleted != null && appoint.isDeleted == true)
                            ? 75
                            : 55,
                    // ajustez la taille du point en fonction de vos besoins

                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                      color: (appoint.isDeleted != null &&
                              appoint.isDeleted == true)
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
                )),
            Spacer(),
          ],
        ),
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
                                      '$baseUrl${utilities!.ajouterPrefixe(appointment.patient!.imageName!)}',
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                        color: Colors.redAccent,
                                      ), // Affiche un indicateur de chargement en attendant l'image
                                  errorWidget: (context, url, error) => Icon(
                                        Icons.account_circle,
                                        size: 120,
                                        color: Colors.black.withOpacity(0.6),
                                      ) // Affiche une icône d'erreur si le chargement échoue
                                  ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${abbreviateName(appointment.patient!.lastName)} \n ${abbreviateName(appointment.patient!.firstName)}',
                                style: const TextStyle(fontSize: 20),
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
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                'Raison:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Text(
                                '${appointment.reason}',
                                style: const TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
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
                        padding: const EdgeInsets.only(top: 30, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                'Le:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(
                              width: 50,
                            ),
                            Text(
                              '${DateTimeFormatAppointment(appointment.startAt, appointment.timeEnd)}',
                              style: const TextStyle(
                                  color: Color.fromARGB(230, 20, 20, 90),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            Spacer()
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
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                'De:',
                                style: TextStyle(
                                    color: Color.fromARGB(230, 20, 20, 90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(
                              width: 43,
                            ),
                            Text(
                              '${formatDateTimeAppointment(appointment.startAt.toLocal(), appointment.timeStart, appointment.timeEnd.toLocal())}',
                              style: const TextStyle(
                                  color: Color.fromARGB(230, 20, 20, 90),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            Spacer()
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
    SnackBar snackBar = const SnackBar(
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
      surfaceTintColor: const Color.fromARGB(230, 20, 20, 90),
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
      surfaceTintColor: const Color.fromARGB(230, 20, 20, 90),
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
