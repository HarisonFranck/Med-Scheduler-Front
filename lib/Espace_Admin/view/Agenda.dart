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
import 'package:med_scheduler_front/main.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/CustomAppointmentDataSource.dart';
import 'dart:io';
import 'IndexAccueilAdmin.dart';
import 'AppointmentDialog.dart';
import 'package:med_scheduler_front/DisablingAppointment.dart';

class Agenda extends StatefulWidget {
  final bool disconnect;


  Agenda({required this.disconnect});

  AgendaState createState() => AgendaState();
}

class AgendaState extends State<Agenda> {
  late AuthProvider authProvider;
  late String token;

  bool _isPageActive = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.disconnect){
        print('DECOONECTTTTT');
      dispose();
    }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(widget.disconnect==false){
      print('FETCH DEPENDECIES');
      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      medecinClicked = ModalRoute.of(context)?.settings.arguments as Medecin;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //await getAllAsync();

        listAppointment = await getAllAppointment();
        listUnavalaibleAppointment = await getAllUnavalaibleAppointment();
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



  Future<List<CustomAppointment>> getAllUnavalaibleAppointment() async {


    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }

    print('MED ID: ${medecinClicked!.id}');
    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${extractLastNumber(medecinClicked!.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;


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



  Future<List<CustomAppointment>> getAllAppointment() async {

    if (!_isPageActive) {
      return []; // Page n'est plus active, on retourne une liste vide.
    }

    final url = Uri.parse(
        "${baseUrl}api/doctors/appointments/${extractLastNumber(medecinClicked!.id)}");

    final headers = {'Authorization': 'Bearer $token'};



    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGNENDAAA: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;


        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        // Gestion des erreurs HTTP
        throw Exception(
            '-- TOKEN EXPIRED.');
      }
    } catch (e) {
      //print('Error: $e \nStack trace: $stackTrace');
      throw Exception(
          '-- Erreur de connexion.\n Veuillez vérifier votre connexion internet !');
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


  @override
  Widget build(BuildContext context) {


    DateTime currentDate = DateTime.now().subtract(Duration(days: 1));


    blackoutDates.addAll(List.generate(365, (index) => currentDate.subtract(Duration(days: index))));

    if(DateTime.now().hour>15){

      blackoutDates.add(DateTime.now());
    }

    return PopScope(canPop: false,child: Scaffold(
        backgroundColor: Color.fromARGB(1000, 238, 239, 244),
        body: ListView(children:[
          Padding(
            padding: EdgeInsets.only(top: 10, left: 10),
            child: Row(
              children: [
                GestureDetector(
                  child: Row(
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
                            SizedBox(
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
                                child: ((medecinClicked!.imageName != null) &&
                                    (File(medecinClicked!.imageName!)
                                        .existsSync()))
                                    ? Image.file(
                                    File(medecinClicked!.imageName!))
                                    : Image.asset(
                                  'assets/images/medecin.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  ' Dr ${abbreviateName(medecinClicked!.lastName)}.${abbreviateName(medecinClicked!.firstName)}',
                                  style: TextStyle(
                                      color:
                                      Color.fromARGB(1000, 60, 70, 120),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      letterSpacing: 2),
                                ),
                                Text(
                                  '${medecinClicked!.speciality!.label}',
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
              padding:
              const EdgeInsets.only(top: 20, right: 10, left: 10, bottom: 10),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white),
                    width: MediaQuery.of(context).size.width - 45,
                    height: MediaQuery.of(context).size.height /1.4,
                    child: (dataLoaded)
                        ? SfCalendar(
                      controller: controller,
                      dataSource:
                      CustomAppointmentDataSource(listAppointment),
                      view: CalendarView.month,
                      scheduleViewSettings: const ScheduleViewSettings(
                          appointmentTextStyle: TextStyle(
                              letterSpacing: 2, color: Colors.green)),
                      monthCellBuilder:
                          (BuildContext context, MonthCellDetails details) {
                        // Personnalisez le contenu de la cellule ici

                        bool isSundayOrPastDate = (details.date.weekday ==
                            7) ||
                            (details.date.isBefore(
                                DateTime.now().subtract(Duration(days: 1))));


                        bool isAllDisabled =
                          (getAvailableAppointments(
                              details.date,
                              listAppointment,
                              medecinClicked!,
                              listUnavalaibleAppointment)!.isEmpty);

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
                                :Colors.transparent,
                            border:
                            Border.all(width: 0.3, color: Colors.grey),
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
                        if (!isBlackoutDate && !isSundayOrPastDate)
                        ...listAppointment
                            .where((appointment) =>
                        appointment.startAt.year ==
                        details.date.year &&
                        appointment.startAt.month ==
                        details.date.month &&
                        appointment.startAt.day ==
                        details.date.day)
                            .map((appointment) =>
                        buildAppointmentWidget(appointment)),
                        ],
                        ),
                        );
                      },
                      onTap: (CalendarTapDetails details) {


                         Navigator.push(context, MaterialPageRoute(builder: (context)=>AppointmentDialog(medecin: medecinClicked!),settings: RouteSettings(arguments: details.date)));

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
        ])
    ),);
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


}



