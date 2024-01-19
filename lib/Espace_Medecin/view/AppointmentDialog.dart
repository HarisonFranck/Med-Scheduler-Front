import 'package:flutter/material.dart';
import 'package:med_scheduler_front/DisablingAppointment.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/main.dart';
import 'IndexAcceuilMedecin.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AppointmentDialog extends StatefulWidget {
  final Medecin medecin;

  AppointmentDialog({super.key, required this.medecin});

  @override
  _AppointmentDialogState createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  //DisablingAppointment? _disablingAppointment;
  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  DateTime? currentJour;

  bool isLoaded = false;

  List<CustomAppointment> listAppointment = [];
  List<CustomAppointment> listUnavalaibleAppointment = [];

  List<bool> isDisableIndex = List.generate(6, (index) => false);

  bool isDayClicked(DateTime startAt) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    bool val = DateFormat('yyyy-MM-dd').format(startAt) ==
        DateFormat('yyyy-MM-dd').format(currentJour!);

    return val;
  }

  Future<List<CustomAppointment>> filterDayClicked(
      Future<List<CustomAppointment>> appointmentFuture) async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = await appointmentFuture;

    print('APOOIIIINTS: ${appointments.length}');

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isDayClicked(appointment.startAt);
    }).toList();

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek);

    print('FILTERED APPOINTS: ${filteredAppointments.length}');

    return filteredAppointments;
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

  Future<List<CustomAppointment>> getAllAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${extractLastNumber(widget.medecin.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;


        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw e;
    }
  }


  Future<List<CustomAppointment>> getAllUnavalaibleAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    print('MED ID: ${widget.medecin.id}');
    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${extractLastNumber(widget.medecin.id)}");

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
      listAppointment = (getAvailableAppointments(
                  currentJour!, await getAllAppointment(), widget.medecin) !=
              null)
          ? getAvailableAppointments(
              currentJour!, await getAllAppointment(), widget.medecin)!
          : [];
      listUnavalaibleAppointment = getAllUnavalaibleByDate(
          await getAllUnavalaibleAppointment(), currentJour!);
      setBoolDisabled(listAppointment);

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
        print('MISY DISABLE: ${appointment.startAt}');
        setState(() {
          isDisableIndex[a] = true;
        });
      } else {
        setState(() {
          isDisableIndex[a] = false;
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

  Future<void> createUnavalaibleAppointment(
      CustomAppointment appointment) async {
    final url = Uri.parse("${baseUrl}api/unavailable_appointments");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonUser = jsonEncode(appointment.toJsonUnav());

      final response = await http.post(url, headers: headers, body: jsonUser);
      print('${response.statusCode} \n BODY: ${response.body} ');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Rendez-vous déja existant');
        } else {}
      } else {
        if (response.statusCode == 201) {
        } else {
          // Gestion des erreurs HTTP
          print('RESP ERROR: ${response.body}');
          error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> deleteUnavalaibleAppointment(
      CustomAppointment appointment) async {
    final url = Uri.parse(
        "${baseUrl}api/unavailable_appointments/${extractLastNumber(appointment.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {'Authorization': 'Bearer $token'};

    try {
      //print('Request Body: $jsonUser');
      final response = await http.delete(url, headers: headers);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Rendez-vous déja existant');
        } else {}
      } else {
        if (response.statusCode == 204) {
        } else {
          // Gestion des erreurs HTTP
          print('RESP ERROR: ${response.body}');
          error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw e;
    }
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

  bool isDayDisabled = false;
  List<bool> switchEnfants = [];




  bool isInUnavalaiblePrise(List<CustomAppointment> listUnavalaibleAppointment,CustomAppointment appointment){

    bool isUnique = true;

    for(int unavIndex=0;unavIndex<listUnavalaibleAppointment.length;unavIndex++){
      CustomAppointment unavAppoint = listUnavalaibleAppointment.elementAt(unavIndex);
      bool isDifferentTime =
          unavAppoint.timeStart.hour !=
              appointment.timeStart.hour &&
              unavAppoint.timeEnd.hour !=
                  appointment.timeEnd.hour;
      if(!isDifferentTime&&(unavAppoint.appType=="Pris"||unavAppoint.appType=="Prise")){
        isUnique = false;
      }
    }

    return isUnique;

  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
          body: (isLoaded)
              ? Padding(
                  padding: const EdgeInsets.only(top: 70, left: 20, right: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/date-limite.png',
                            width: 35,
                          ),
                          const Spacer(),
                          Text(
                            '${formatDateTime(currentJour!)}',
                            textScaler: const TextScaler.linear(1.4),
                            textAlign: TextAlign.start,
                            style:
                                TextStyle(color: Colors.black.withOpacity(0.7)),
                          ),
                          const Spacer(),
                          Switch(
                            activeColor: Colors.redAccent,
                            inactiveThumbColor: const Color.fromARGB(230, 20, 20, 90),
                            value: areAllAppointmentsDesactiver(
                                getAvailableAppointments(currentJour!,
                                    listAppointment, widget.medecin)!)
                                ? true
                                : false,
                            onChanged: (val) {

                              /// Liste des appointment qui sont uniques(ne sont pas enregistrés)
                              List<CustomAppointment> appointsList = [];

                              setState(() {
                                isLoaded = false;
                                isDayDisabled = val;

                                // Mettez à jour l'attribut "appType" de tous les rendez-vous du jour
                                if (isDayDisabled) {

                                  /// On boucle tous les plages crées par défaut
                                  for (var appointment in listAppointment) {

                                    /// On initialise un variable boolean en isUnique = false a chaque appointment
                                    bool isUnique = false;

                                    /// On boucle tous les appointment qui ne sont plus disponible de type "Desactiver" du medecin en question et du date cliquer(enregistrés dans la base)
                                    for (var unavAppoint in listUnavalaibleAppointment) {

                                      /// Verification si l'appointment crée par defaut a desactiver est déja enregistrer(en se referent par la timeStart et timeEnd)
                                      bool isDifferentTime =
                                          unavAppoint.timeStart.hour !=
                                              appointment.timeStart.hour &&
                                              unavAppoint.timeEnd.hour !=
                                                  appointment.timeEnd.hour;


                                      /// Si l'appointment a desactiver est unique, on affecte isUnique en true
                                      if (isDifferentTime) {
                                        isUnique = true;
                                      }
                                    } // On sort de la boucle de appointment indisponible


                                    /// On vérifie après si le boolean est unique pour cette appointment a desactiver
                                    if (isUnique) {

                                      /// On ajoute l'appointment dans la liste a desctiver après
                                      appointsList.add(appointment);


                                    }
                                  } // On sort du boucle de list Appointment

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
                                      appType:
                                      isDayDisabled ? 'Desactiver' : "",
                                    );

                                    bool uniqueVe = isInUnavalaiblePrise(listUnavalaibleAppointment, appoint);

                                    if(uniqueVe){
                                      /// On cree l'appointment avec un type "Desactiver" vers le serveur(On desactive l'appointment)
                                      createUnavalaibleAppointment(
                                          customAppointment);

                                      /// On actualise l'état
                                      didChangeDependencies();

                                    }else{

                                      /// On demande la confirmation de l'admin ou du medecin s'il veut vraiment desactiver cette plage horaire qui est deja prise en tant que rendez-vous
                                      ConfirmDisableAppointmentBoucle(customAppointment);

                                      /// On actualise l'état
                                      didChangeDependencies();

                                    }

                                  } // On sort du boucle

                                  /// Si le Switch est desactiver ou bien le jour est reactiver de nouveau
                                } else {

                                  /// On boucle de nouveau les appointments par defaut crée
                                  for (var appointment in listAppointment) {

                                    /// On supprime l'appointment de type "Desactiver" dans la base de donnée(on reactive le plage horaire)
                                    deleteUnavalaibleAppointment(appointment);

                                    /// On actualise l'état
                                    didChangeDependencies();
                                  }
                                }
                              });
                            },
                          ),
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
                          padding: const EdgeInsets.only(top: 20),
                          color: Colors.transparent,
                          width: MediaQuery.of(context).size.width - 40,
                          height: MediaQuery.of(context).size.height / 3,
                          child: ListView.builder(
                            itemCount: listAppointment.length,
                            itemBuilder: (context, i) {
                              CustomAppointment appointment =
                                  listAppointment.elementAt(i);

                              bool isUnique = isInUnavalaiblePrise(listUnavalaibleAppointment,appointment);
                              //print('APPOINT APPTYPE: ${appointment.appType}, START: ${appointment.timeStart}, END: ${appointment.timeEnd}');

                              return Column(
                                children: [
                                  Container(
                                    height:60,
                                    decoration: BoxDecoration(

                                      color: isUnique?Colors.transparent:Colors.redAccent.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6)
                                    ),
                                    child:  Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 15),
                                          child: Text(
                                            isUnique?'${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}':' Il y a un rendez-vous de \n ${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)}',

                                            style: TextStyle(
                                                color:const Color.fromARGB(
                                                    230, 20, 20, 90),
                                                fontWeight: isUnique?FontWeight.w400:FontWeight.w500,
                                                letterSpacing: 1.5,
                                                fontSize: 16),
                                          ),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          activeColor: Colors.redAccent,
                                          inactiveThumbColor:
                                          const Color.fromARGB(230, 20, 20, 90),
                                          value: (appointment.appType == null)
                                              ? false
                                              : ((appointment.appType ==
                                              "Desactiver")
                                              ? true
                                              : false),
                                          onChanged: (val) {
                                            setState(() {
                                              print('FIRST VAL: $val');

                                              isDisableIndex[i] = val;

                                              print(
                                                  'CHANGED: ${appointment.appType}');

                                              print(
                                                  'VAL $i: ${isDisableIndex[i]}');

                                              if (isDisableIndex[i] == false) {
                                                print('FALSE');
                                                deleteUnavalaibleAppointment(
                                                    appointment);

                                                didChangeDependencies();
                                              } else {
                                                print('TRUE');
                                                if(isUnique){

                                                  CustomAppointment appoint =
                                                  CustomAppointment(
                                                      medecin: widget.medecin,
                                                      id: '',
                                                      type: appointment.type,
                                                      startAt: currentJour!,
                                                      timeStart:
                                                      appointment.timeStart,
                                                      timeEnd:
                                                      appointment.timeEnd,
                                                      reason: "",
                                                      createdAt:
                                                      appointment.createdAt,
                                                      appType: isDisableIndex[i]
                                                          ? 'Desactiver'
                                                          : "");

                                                  createUnavalaibleAppointment(
                                                      appoint);
                                                  didChangeDependencies();

                                                }else{
                                                  ConfirmDisableAppointment(appointment,i);
                                                }


                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  const SizedBox(
                                    height: 20,
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
                                      builder: (context) => IndexAcceuilMedecin()));
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
                        height: 10,
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                )),
    );
  }


  void ConfirmDisableAppointmentBoucle(CustomAppointment appointment) {

    AwesomeDialog(
      dialogBackgroundColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      titleTextStyle: const TextStyle(letterSpacing: 2,color: Colors.white),
      descTextStyle: TextStyle(letterSpacing: 2,color: Colors.white.withOpacity(0.8),fontWeight: FontWeight.w500,fontSize: 16),
      context: context,
      autoDismiss: true,
      dialogType: DialogType.info,
      autoHide: Duration(seconds: 15),
      btnOkText: 'Confirmer',
      btnCancelText: 'Annuler',
      animType: AnimType.rightSlide,

      title: 'Confirmation',
      desc: 'Voulez-vous vraiment désactiver cette plage horaire contenant un rendez-vous ?',
      btnCancelOnPress: () {

      },
      btnOkOnPress: () {

        CustomAppointment appoint =
        CustomAppointment(
            medecin: widget.medecin,
            id: '',
            type: appointment.type,
            startAt: currentJour!,
            timeStart:
            appointment.timeStart,
            timeEnd:
            appointment.timeEnd,
            reason: "",
            createdAt:
            appointment.createdAt,
            appType: isDayDisabled
                ? 'Desactiver'
                : "");

        createUnavalaibleAppointment(
            appoint);
        didChangeDependencies();
      },
    ).show();

  }



  void ConfirmDisableAppointment(CustomAppointment appointment,int i) {

    AwesomeDialog(
      dialogBackgroundColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      titleTextStyle: const TextStyle(letterSpacing: 2,color: Colors.white),
      descTextStyle: TextStyle(letterSpacing: 2,color: Colors.white.withOpacity(0.8),fontWeight: FontWeight.w500,fontSize: 16),
      context: context,
      autoDismiss: true,
      dialogType: DialogType.info,
      autoHide: Duration(seconds: 15),
      btnOkText: 'Confirmer',
      btnCancelText: 'Annuler',
      animType: AnimType.rightSlide,

      title: 'Confirmation',
      desc: 'Voulez-vous vraiment désactiver cette plage horaire contenant un rendez-vous ?',
      btnCancelOnPress: () {

      },
      btnOkOnPress: () {

        CustomAppointment appoint =
        CustomAppointment(
            medecin: widget.medecin,
            id: '',
            type: appointment.type,
            startAt: currentJour!,
            timeStart:
            appointment.timeStart,
            timeEnd:
            appointment.timeEnd,
            reason: "",
            createdAt:
            appointment.createdAt,
            appType: isDisableIndex[i]
                ? 'Desactiver'
                : "");

        createUnavalaibleAppointment(
            appoint);
        didChangeDependencies();
      },
    ).show();

  }


}
