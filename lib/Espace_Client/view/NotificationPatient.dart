import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'IndexAccueil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:med_scheduler_front/Models/AuthProviderNotif.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPatient extends StatefulWidget {
  _NotificationPatientState createState() => _NotificationPatientState();
}

class _NotificationPatientState extends State<NotificationPatient> {
  UserRepository? userRepository;
  Utilities? utilities;

  Utilisateur? user;

  String title = "";
  String body = "";
  String sentTime = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);
  }

  late AuthProvider authProvider;
  late String token;
  String baseUrl = UrlBase().baseUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    user = Provider.of<AuthProviderUser>(context).utilisateur;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      String? message = sharedPreferences.getString('notificationPatient');
      if (message != "" && message != null) {
        List<String> notifSplitted = message.split(",");
        setState(() {
          title = notifSplitted.first;
          body = notifSplitted[1];
          sentTime = notifSplitted[2];
        });
      }
    });
  }

  Future<List<CustomAppointment>> filterAppointments(
      Future<List<CustomAppointment>> appointmentsFuture) async {
    List<CustomAppointment> allAppointments = await appointmentsFuture;

    // Filtrer les rendez-vous avec startAt égal à DateTime.now() et timeStart inferieur à now.hour
    List<CustomAppointment> filteredAppointments = allAppointments
        .where((appointment) =>
            utilities!.isToday(appointment.startAt, appointment.timeStart))
        .toList();

    return filteredAppointments;
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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50, left: 10),
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
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: Center(
                  child: Container(
                      width: MediaQuery.of(context).size.width - 90,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent, width: 1),
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
                                color: Colors.redAccent, letterSpacing: 2),
                          ),
                          Spacer()
                        ],
                      )),
                ),
              ),
              if (title != "" && body != "") ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 90,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(children: [
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.only(top: 10, right: 10),
                              child: Text(
                                  '${utilities!.formatRelativeTime(DateTime.parse(sentTime))}'),
                            ),
                          ]),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(
                                top: 10, left: 10, right: 10, bottom: 10),
                            child: Text(
                              textAlign: TextAlign.center,
                              '$title',
                              style: TextStyle(
                                  letterSpacing: 2,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            indent: 50,
                            endIndent: 50,
                            color: Colors.black.withOpacity(0.2),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 20, right: 20, top: 20, bottom: 10),
                            child: Text(
                              '$body',
                              style: TextStyle(letterSpacing: 2, fontSize: 15),
                            ),
                          ),
                          const Spacer()
                        ],
                      ),
                    ),
                  ),
                )
              ] else ...[
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 40, right: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    height: 130,
                    width: 400,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 30, bottom: 10),
                          child: Text(
                            'Aucune notification récente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                letterSpacing: 2,
                                color: Colors.black,
                                fontSize: 15),
                          ),
                        ),
                        Icon(
                          Icons.update,
                          size: 30,
                          color: Color.fromARGB(230, 20, 20, 90),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer()
              ],
              const Spacer()
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
