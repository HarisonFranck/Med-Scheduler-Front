import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/main.dart';
import 'Agenda.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:med_scheduler_front/Espace_Client/view/AppointmentDetails.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';

class AppointmentDialog extends StatefulWidget {
  final Medecin medecin;

  AppointmentDialog({required this.medecin});

  @override
  _AppointmentDialogState createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  //DisablingAppointment? _disablingAppointment;
  late AuthProvider authProvider;
  late String token;

  BaseRepository? baseRepository;
  Utilities? utilities;

  String baseUrl = UrlBase().baseUrl;

  DateTime? currentJour;

  bool isLoaded = false;

  List<CustomAppointment> listAppointment = [];
  List<CustomAppointment> listUnavalaibleAppointment = [];
  List<CustomAppointment> appointsList = [];

  List<bool> isDisableIndex = List.generate(6, (index) => false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
  }

  bool isDayClicked(DateTime startAt) {
    bool val = DateFormat('yyyy-MM-dd').format(startAt) ==
        DateFormat('yyyy-MM-dd').format(currentJour!);

    return val;
  }

  Future<List<CustomAppointment>> filterDayClicked(
      Future<List<CustomAppointment>> appointmentFuture) async {
    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = await appointmentFuture;

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isDayClicked(appointment.startAt);
    }).toList();

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek);

    return filteredAppointments;
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

  Future<List<CustomAppointment>> getAllUnavalaibleAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${extractLastNumber(widget.medecin.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          authProvider.logout();
          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
            (route) => false,
          );
        }

        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      if (e is http.ClientException) {
        utilities!.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      throw e;
    }
  }

  List<CustomAppointment> getAllUnavalaibleByDate(
      List<CustomAppointment> list, DateTime dt) {
    List<CustomAppointment> filteredList = [];
    String formatDt = DateFormat('yyyy-MM-dd').format(dt);
    for (int val = 0; val < list.length; val++) {
      CustomAppointment appointment = list.elementAt(val);
      if (DateFormat('yyyy-MM-dd').format(appointment.startAt) == formatDt) {
        filteredList.add(appointment);
      }
    }

    return filteredList;
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    setState(() {
      isLoaded = false;
    });

    //_disablingAppointment = ModalRoute.of(context)?.settings.arguments as DisablingAppointment;

    currentJour = ModalRoute.of(context)?.settings.arguments as DateTime;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      listAppointment = (getAvailableAppointments(currentJour!,
                  await getAllUnavalaibleAppointment(), widget.medecin) !=
              null)
          ? getAvailableAppointments(currentJour!,
              await getAllUnavalaibleAppointment(), widget.medecin)!
          : [];
      listUnavalaibleAppointment = getAllUnavalaibleByDate(
          await getAllUnavalaibleAppointment(), currentJour!);
      setBoolDisabled(listAppointment);
      appointsList =
          await baseRepository!.getAllAppointmentByMedecin(widget.medecin);

      if (mounted) {
        setState(() {
          isLoaded = true;
        });
      }
    });
  }

  void setBoolDisabled(List<CustomAppointment> list) {
    for (int a = 0; a < listAppointment.length; a++) {
      CustomAppointment appointment = listAppointment.elementAt(a);
      if (appointment.appType == "Desactiver") {
        setState(() {
          isDisableIndex[a] = false;
        });
      } else {
        setState(() {
          isDisableIndex[a] = true;
        });
      }
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

  bool areAllAppointmentsDesactiver(List<CustomAppointment> appointments) {
    return appointments
        .every((appointment) => appointment.appType == "Desactiver");
  }

  List<CustomAppointment>? getAvailableAppointments(DateTime journeeCliquer,
      List<CustomAppointment> appointments, Medecin medecin) {
    List<CustomAppointment> tranchesDate = [];

    List<CustomAppointment> availableAppointments = [];

    List<String> defaultTimeSlots = [
      "08:00-09:00",
      "09:00-10:00",
      "10:00-11:00",
      "11:00-12:00",
      "14:00-15:00",
      "15:00-16:00"
    ];

    availableAppointments = defaultTimeSlots.map((timeSlot) {
      DateTime startTime = DateTime(journeeCliquer.year, journeeCliquer.month,
          journeeCliquer.day, int.parse(timeSlot.substring(0, 2)), 0);
      DateTime endTime = DateTime(journeeCliquer.year, journeeCliquer.month,
          journeeCliquer.day, int.parse(timeSlot.substring(6, 8)), 0);

      return CustomAppointment(
        id: "", // Vous devrez attribuer un identifiant unique ici
        type: "",
        medecin: medecin,
        patient: null,
        startAt: DateTime(
            journeeCliquer.year, journeeCliquer.month, journeeCliquer.day),
        timeStart: startTime,
        timeEnd: endTime,
        reason: "",
        createdAt: DateTime.now(),
        appType: "",
      );
    }).toList();

    //print('AV APPOINTS SIZE: ${availableAppointments.length}');
    //print('UNAV APPOINTS SIZE: ${appointments.length}');

    if (appointments.isNotEmpty) {
      for (int avIndex = 0; avIndex < availableAppointments.length; avIndex++) {
        CustomAppointment avAppointment =
            availableAppointments.elementAt(avIndex);

        bool hasMatch =
            false; // Drapeau pour vérifier s'il y a une correspondance

        for (int unavIndex = 0; unavIndex < appointments.length; unavIndex++) {
          CustomAppointment unavAppointment = appointments.elementAt(unavIndex);

          //print('UNAV DT: ${unavAppointment.startAt}, UNAV APPTYPE: ${unavAppointment.appType}');

          // Logique de comparaison
          if (unavAppointment.appType == "Desactiver") {
            if ((DateFormat('yyyy-MM-dd').format(avAppointment.startAt) ==
                    DateFormat('yyyy-MM-dd').format(unavAppointment.startAt)) &&
                (TimeOfDay.fromDateTime(avAppointment.timeStart) ==
                    TimeOfDay.fromDateTime(unavAppointment.timeStart)) &&
                (TimeOfDay.fromDateTime(avAppointment.timeEnd) ==
                    TimeOfDay.fromDateTime(unavAppointment.timeEnd)) &&
                ((avAppointment.medecin!.lastName ==
                        unavAppointment.medecin!.lastName) &&
                    (avAppointment.medecin!.firstName ==
                        unavAppointment.medecin!.firstName))) {
              tranchesDate.add(unavAppointment);
              hasMatch = true;
            }
          }
        }

        if (!hasMatch) {
          // Aucune correspondance trouvée, ajoutez avAppointment à tranchesDate
          tranchesDate.add(avAppointment);
        }
      }
    } else {
      tranchesDate = availableAppointments;
    }

    return tranchesDate.isNotEmpty ? tranchesDate : null;
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

    // Formater le jour de la semaine
    String jourSemaine = jours[dateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Construire la chaîne lisible
    String resultat = '$jourSemaine, $jour $nomMois $annee';

    return resultat;
  }

  String formatDateTimeAppointment(
      DateTime startAt, DateTime startDateTime, DateTime timeEnd) {
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$formatHeureStart - $formatHeureEnd';

    return resultat;
  }

  bool isDayDisabled = false;
  List<bool> switchEnfants = [];

  CustomAppointment? isInUnavalaiblePrise(
      List<CustomAppointment> listUnavalaibleAppointment,
      CustomAppointment appointment) {
    CustomAppointment? unavAppointFinded;

    for (int unavIndex = 0;
        unavIndex < listUnavalaibleAppointment.length;
        unavIndex++) {
      CustomAppointment unavAppoint =
          listUnavalaibleAppointment.elementAt(unavIndex);
      bool isEqualTime =
          unavAppoint.timeStart.hour == appointment.timeStart.hour &&
              unavAppoint.timeEnd.hour == appointment.timeEnd.hour;
      if (isEqualTime &&
          (unavAppoint.appType == "Pris" || unavAppoint.appType == "Prise")) {
        unavAppointFinded = unavAppoint;
      }
    }

    return unavAppointFinded;
  }

  CustomAppointment? isInUnavalaibleDesactiver(
      List<CustomAppointment> listUnavalaibleAppointment,
      CustomAppointment appointment) {
    CustomAppointment? unavAppointFinded;

    for (int unavIndex = 0;
        unavIndex < listUnavalaibleAppointment.length;
        unavIndex++) {
      CustomAppointment unavAppoint =
          listUnavalaibleAppointment.elementAt(unavIndex);
      bool isEqualTime =
          unavAppoint.timeStart.hour == appointment.timeStart.hour &&
              unavAppoint.timeEnd.hour == appointment.timeEnd.hour;
      if (isEqualTime && unavAppoint.appType == "Desactiver") {
        unavAppointFinded = unavAppoint;
      }
    }

    return unavAppointFinded;
  }

  CustomAppointment? getAppointmentDoctorPrise(CustomAppointment appointment) {
    CustomAppointment? appointmentFinded;
    for (int ap = 0; ap < appointsList.length; ap++) {
      CustomAppointment appoint = appointsList.elementAt(ap);
      bool isEqualTime = appoint.timeStart.hour == appointment.timeStart.hour &&
          appoint.timeEnd.hour == appointment.timeEnd.hour;
      bool isEqualPatient = appoint.patient!.id == appointment.patient!.id;

      if (isEqualPatient && isEqualTime) {
        appointmentFinded = appoint;
      }
    }
    return appointmentFinded;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
          body: (isLoaded)
              ? Padding(
                  padding: const EdgeInsets.only(
                      top: 60, left: 20, right: 20, bottom: 20),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Image.asset(
                              'assets/images/date-limite.png',
                              width: 35,
                            ),
                            const Spacer(),
                            Text(
                              '${formatDateTime(currentJour!)}',
                              textScaler: const TextScaler.linear(1.4),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                            const Spacer(),
                            Switch(
                              thumbColor: areAllAppointmentsDesactiver(
                                      getAvailableAppointments(currentJour!,
                                          listAppointment, widget.medecin)!)
                                  ? MaterialStateProperty.all(Colors.redAccent)
                                  : MaterialStateProperty.all(Colors.green),
                              activeColor: Colors.grey.withOpacity(0.3),
                              inactiveThumbColor: Colors.redAccent,
                              inactiveTrackColor:
                                  Colors.redAccent.withOpacity(0.3),
                              value: areAllAppointmentsDesactiver(
                                      getAvailableAppointments(currentJour!,
                                          listAppointment, widget.medecin)!)
                                  ? false
                                  : true,
                              onChanged: (val) {
                                /// Liste des appointment qui sont uniques(ne sont pas enregistrés)
                                List<CustomAppointment> appointsList = [];

                                setState(() {
                                  isLoaded = false;
                                  isDayDisabled = val;

                                  /// Si le switch devient false(desactivation)
                                  if (isDayDisabled == false) {
                                    /// On boucle tous les plages crées par défaut
                                    for (var appointment in listAppointment) {
                                      /// On initialise un variable boolean en isUnique = true a chaque appointment(par defaut activer)
                                      bool isUnique = true;

                                      /// On boucle tous les appointment qui ne sont plus disponible de type "Desactiver" du medecin en question et du date cliquer(enregistrés dans la base)
                                      for (var unavAppoint
                                          in listUnavalaibleAppointment) {
                                        /// Verification si l'appointment crée par defaut a desactiver est déja enregistrer(en se referent par la timeStart et timeEnd)
                                        bool isEqualTimeAndPrise = unavAppoint
                                                    .timeStart.hour ==
                                                appointment.timeStart.hour &&
                                            unavAppoint.timeEnd.hour ==
                                                appointment.timeEnd.hour &&
                                            (unavAppoint.appType == "Prise" ||
                                                unavAppoint.appType == "Pris");

                                        /// Si l'appointment a desactiver est unique, on affecte isUnique en false
                                        if (isEqualTimeAndPrise) {
                                          isUnique = false;
                                        }
                                      } // On sort du boucle de list Appointment

                                      if (isUnique == false) {
                                        if (isInUnavalaibleDesactiver(
                                                listUnavalaibleAppointment,
                                                appointment) ==
                                            null) {
                                          CustomAppointment? unavAppointFinded =
                                              isInUnavalaiblePrise(
                                                  listUnavalaibleAppointment,
                                                  appointment);
                                          if (unavAppointFinded != null) {
                                            CustomAppointment?
                                                appointmentPrise =
                                                getAppointmentDoctorPrise(
                                                    unavAppointFinded);

                                            ConfirmDisableAppointmentBoucle(
                                                appointmentPrise!);
                                          }

                                          /// On actualise l'état
                                          didChangeDependencies();
                                        }
                                      } else {
                                        if (isInUnavalaibleDesactiver(
                                                listUnavalaibleAppointment,
                                                appointment) ==
                                            null) {
                                          /// On ajoute l'appointment dans la liste a desctiver après
                                          appointsList.add(appointment);
                                        }
                                      }
                                    } // On sort de la boucle de appointment indisponible

                                    /// Maintenant qu'on a eu tous les appointments uniques, on boucle pour les desactiver un a un
                                    for (var appoint in appointsList) {
                                      /// On instancie appointment dans un nouveau variable d'appointment(customAppointment)
                                      CustomAppointment customAppointment =
                                          CustomAppointment(
                                        medecin: widget.medecin,
                                        id: appoint.id,
                                        type: appoint.type,
                                        startAt: currentJour!,
                                        timeStart: appoint.timeStart,
                                        timeEnd: appoint.timeEnd,
                                        reason: "",
                                        createdAt: appoint.createdAt,
                                        appType: 'Desactiver',
                                      );

                                      /// On cree l'appointment avec un type "Desactiver" vers le serveur(On desactive l'appointment)
                                      baseRepository!
                                          .createUnavalaibleAppointment(
                                              customAppointment);

                                      /// On actualise l'état
                                      didChangeDependencies();
                                    } // On sort du boucle

                                    /// Si le Switch est desactiver ou bien le jour est reactiver de nouveau
                                  } else {
                                    /// On boucle de nouveau les appointments par defaut crée
                                    for (var appointment in listAppointment) {
                                      CustomAppointment? unavAppointFinded =
                                          isInUnavalaiblePrise(
                                              listUnavalaibleAppointment,
                                              appointment);
                                      if (unavAppointFinded != null) {
                                        CustomAppointment? appointmentPrise =
                                            getAppointmentDoctorPrise(
                                                unavAppointFinded);
                                        if (appointmentPrise != null) {
                                          CustomAppointment
                                              appointmentPatchFalse =
                                              CustomAppointment(
                                                  id: appointmentPrise.id,
                                                  medecin:
                                                      appointmentPrise.medecin,
                                                  patient:
                                                      appointmentPrise.patient,
                                                  type: appointmentPrise.type,
                                                  startAt:
                                                      appointmentPrise.startAt,
                                                  timeStart: appointmentPrise
                                                      .timeStart,
                                                  timeEnd:
                                                      appointmentPrise.timeEnd,
                                                  reason:
                                                      appointmentPrise.reason,
                                                  updatedAt: DateTime.now(),
                                                  createdAt: appointmentPrise
                                                      .createdAt,
                                                  isDeleted: false);

                                          baseRepository!.patchAppointment(
                                              appointmentPatchFalse);

                                          baseRepository!
                                              .deleteUnavalaibleAppointment(
                                                  appointment);
                                        } else {
                                          /// On supprime l'appointment de type "Desactiver" dans la base de donnée(on reactive le plage horaire)
                                          baseRepository!
                                              .deleteUnavalaibleAppointment(
                                                  appointment);
                                        }
                                      } else {
                                        /// On supprime l'appointment de type "Desactiver" dans la base de donnée(on reactive le plage horaire)
                                        baseRepository!
                                            .deleteUnavalaibleAppointment(
                                                appointment);
                                      }

                                      /// On actualise l'état
                                      didChangeDependencies();
                                    }
                                  }
                                });
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Text(
                            'Les tranches horaires:',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black.withOpacity(0.6)),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 20),
                            color: Colors.transparent,
                            width: MediaQuery.of(context).size.width - 40,
                            height: MediaQuery.of(context).size.height / 3,
                            child: ListView.builder(
                              itemCount: listAppointment.length,
                              itemBuilder: (context, i) {
                                CustomAppointment appointment =
                                    listAppointment.elementAt(i);

                                CustomAppointment? unavAppointFinded =
                                    isInUnavalaiblePrise(
                                        listUnavalaibleAppointment,
                                        appointment);
                                CustomAppointment? unavAppointFindedDesactiver =
                                    isInUnavalaibleDesactiver(
                                        listUnavalaibleAppointment,
                                        appointment);

                                //CustomAppointment? appointmentPrise = getAppointmentDoctorPrise(unavAppointFinded!);

                                return Column(
                                  children: [
                                    (unavAppointFinded == null)
                                        ? Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 15),
                                                  child: Text(
                                                    '${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}',
                                                    style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            230, 20, 20, 90),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        letterSpacing: 1.5,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Switch(
                                                  thumbColor: (appointment
                                                              .appType ==
                                                          "Desactiver")
                                                      ? MaterialStateProperty
                                                          .all(Colors.redAccent)
                                                      : MaterialStateProperty
                                                          .all(Colors.green),
                                                  activeColor: Colors.grey
                                                      .withOpacity(0.3),
                                                  inactiveThumbColor:
                                                      Colors.redAccent,
                                                  inactiveTrackColor: Colors
                                                      .redAccent
                                                      .withOpacity(0.3),
                                                  value: (appointment.appType ==
                                                          null)
                                                      ? true
                                                      : ((appointment.appType ==
                                                              "Desactiver")
                                                          ? false
                                                          : true),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      isDisableIndex[i] = val;

                                                      if (isDisableIndex[i] ==
                                                          true) {
                                                        baseRepository!
                                                            .deleteUnavalaibleAppointment(
                                                                appointment);

                                                        didChangeDependencies();
                                                      } else {
                                                        CustomAppointment
                                                            appoint =
                                                            CustomAppointment(
                                                                medecin: widget
                                                                    .medecin,
                                                                id: '',
                                                                type: appointment
                                                                    .type,
                                                                startAt:
                                                                    currentJour!,
                                                                timeStart:
                                                                    appointment
                                                                        .timeStart,
                                                                timeEnd:
                                                                    appointment
                                                                        .timeEnd,
                                                                reason: "",
                                                                createdAt:
                                                                    appointment
                                                                        .createdAt,
                                                                appType:
                                                                    isDisableIndex[
                                                                            i]
                                                                        ? ""
                                                                        : "Desactiver");

                                                        baseRepository!
                                                            .createUnavalaibleAppointment(
                                                                appoint);
                                                        didChangeDependencies();
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AppointmentDetails(),
                                                      settings: RouteSettings(
                                                          arguments:
                                                              unavAppointFinded)));
                                            },
                                            child: Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                  color: (getAppointmentDoctorPrise(
                                                                      unavAppointFinded)!
                                                                  .isDeleted !=
                                                              null &&
                                                          getAppointmentDoctorPrise(
                                                                      unavAppointFinded)!
                                                                  .isDeleted ==
                                                              true)
                                                      ? Color.fromARGB(
                                                          1000, 238, 239, 244)
                                                      : Colors.redAccent
                                                          .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 15),
                                                    child: Text(
                                                      (getAppointmentDoctorPrise(
                                                                          unavAppointFinded)!
                                                                      .isDeleted !=
                                                                  null &&
                                                              getAppointmentDoctorPrise(
                                                                          unavAppointFinded)!
                                                                      .isDeleted ==
                                                                  true)
                                                          ? 'Rendez-vous annulé \n ${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}'
                                                          : ' Rendez-vous en cours \n ${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}',
                                                      style: const TextStyle(
                                                          color: Color.fromARGB(
                                                              230, 20, 20, 90),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          letterSpacing: 1.5,
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Switch(
                                                    thumbColor: (appointment
                                                                .appType ==
                                                            "Desactiver")
                                                        ? MaterialStateProperty
                                                            .all(Colors
                                                                .redAccent)
                                                        : MaterialStateProperty
                                                            .all(Colors.green),
                                                    activeColor: Colors.grey
                                                        .withOpacity(0.3),
                                                    inactiveThumbColor:
                                                        Colors.redAccent,
                                                    inactiveTrackColor: Colors
                                                        .redAccent
                                                        .withOpacity(0.3),
                                                    value: (appointment
                                                                .appType ==
                                                            null)
                                                        ? true
                                                        : ((appointment
                                                                    .appType ==
                                                                "Desactiver")
                                                            ? false
                                                            : true),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        isDisableIndex[i] = val;

                                                        if (isDisableIndex[i] ==
                                                            true) {
                                                          CustomAppointment?
                                                              appointmentPrise =
                                                              getAppointmentDoctorPrise(
                                                                  unavAppointFinded);

                                                          CustomAppointment appointmentPatchFalse = CustomAppointment(
                                                              id: appointmentPrise!
                                                                  .id,
                                                              medecin:
                                                                  appointmentPrise
                                                                      .medecin,
                                                              patient:
                                                                  appointmentPrise
                                                                      .patient,
                                                              type: appointmentPrise
                                                                  .type,
                                                              startAt:
                                                                  appointmentPrise
                                                                      .startAt,
                                                              timeStart:
                                                                  appointmentPrise
                                                                      .timeStart,
                                                              timeEnd:
                                                                  appointmentPrise
                                                                      .timeEnd,
                                                              reason:
                                                                  appointmentPrise
                                                                      .reason,
                                                              updatedAt: DateTime
                                                                  .now(),
                                                              createdAt:
                                                                  appointmentPrise
                                                                      .createdAt,
                                                              isDeleted: false);

                                                          baseRepository!
                                                              .patchAppointment(
                                                                  appointmentPatchFalse);

                                                          baseRepository!
                                                              .deleteUnavalaibleAppointment(
                                                                  unavAppointFindedDesactiver!);

                                                          didChangeDependencies();
                                                        } else {
                                                          CustomAppointment?
                                                              appointmentPrise =
                                                              getAppointmentDoctorPrise(
                                                                  unavAppointFinded);

                                                          ConfirmDisableAppointment(
                                                              appointmentPrise!);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                );
                              },
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Agenda(),
                                        settings: RouteSettings(
                                            arguments: widget.medecin)));
                              },
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    letterSpacing: 2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ))
              : loadingWidget()),
    );
  }

  Widget loadingWidget() {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          Container(
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
          ),
          Padding(
            padding: EdgeInsets.only(top: 30, left: 10, right: 10),
            child: Text(
              'Veuillez attendre pendant que les données sont récupérées.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.5), letterSpacing: 2),
            ),
          ),
          const Spacer()
        ],
      ),
    );
  }

  void ConfirmDisableAppointmentBoucle(CustomAppointment appointment) {
    AwesomeDialog(
      dialogBackgroundColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2,
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w500,
          fontSize: 16),
      context: context,
      autoDismiss: true,
      dialogType: DialogType.info,
      autoHide: Duration(seconds: 15),
      btnOkText: 'Confirmer',
      btnCancelText: 'Annuler',
      animType: AnimType.rightSlide,
      title: 'Confirmation',
      desc:
          'Confirmez-vous votre choix de désactiver cette plage horaire, qui inclut un rendez-vous prévu ?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        CustomAppointment appointPatch = CustomAppointment(
            medecin: widget.medecin,
            patient: appointment.patient,
            id: appointment.id,
            type: appointment.type,
            startAt: currentJour!,
            timeStart: appointment.timeStart,
            timeEnd: appointment.timeEnd,
            reason: appointment.reason,
            createdAt: appointment.createdAt,
            updatedAt: DateTime.now(),
            isDeleted: true);

        CustomAppointment appoint = CustomAppointment(
            medecin: widget.medecin,
            id: '',
            type: appointment.type,
            startAt: currentJour!,
            timeStart: appointment.timeStart,
            timeEnd: appointment.timeEnd,
            reason: "",
            createdAt: appointment.createdAt,
            appType: 'Desactiver');

        baseRepository!.patchAppointment(appointPatch);

        baseRepository!.createUnavalaibleAppointment(appoint);
        if (appointment.patient!.token != null) {
          baseRepository!.sendNotificationDisableAppointment(
              doctorName: appointment.medecin!.lastName,
              recipientToken: appointment.patient!.token!);
        }
        didChangeDependencies();
      },
    ).show();
  }

  void ConfirmDisableAppointment(CustomAppointment appointment) {
    AwesomeDialog(
      dialogBackgroundColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2,
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w500,
          fontSize: 16),
      context: context,
      autoDismiss: true,
      dialogType: DialogType.info,
      autoHide: Duration(seconds: 15),
      btnOkText: 'Confirmer',
      btnCancelText: 'Annuler',
      animType: AnimType.rightSlide,
      title: 'Confirmation',
      desc:
          'Confirmez-vous votre choix de désactiver cette plage horaire, qui inclut un rendez-vous prévu ?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        CustomAppointment appointPatch = CustomAppointment(
            medecin: widget.medecin,
            patient: appointment.patient,
            id: appointment.id,
            type: appointment.type,
            startAt: currentJour!,
            timeStart: appointment.timeStart,
            timeEnd: appointment.timeEnd,
            reason: appointment.reason,
            createdAt: appointment.createdAt,
            updatedAt: DateTime.now(),
            isDeleted: true);

        CustomAppointment appoint = CustomAppointment(
            medecin: widget.medecin,
            id: '',
            type: appointment.type,
            startAt: currentJour!,
            timeStart: appointment.timeStart,
            timeEnd: appointment.timeEnd,
            reason: "",
            createdAt: appointment.createdAt,
            appType: 'Desactiver');

        baseRepository!.patchAppointment(appointPatch);

        baseRepository!.createUnavalaibleAppointment(appoint);
        if (appointment.patient!.token != null) {
          baseRepository!.sendNotificationDisableAppointment(
              doctorName: appointment.medecin!.lastName,
              recipientToken: appointment.patient!.token!);
        }

        didChangeDependencies();
      },
    ).show();
  }
}
