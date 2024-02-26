import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'IndexAccueil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationPatient extends StatefulWidget {
  _NotificationPatientState createState() => _NotificationPatientState();
}

class _NotificationPatientState extends State<NotificationPatient> {
  UserRepository? userRepository;
  Utilities? utilities;

  Utilisateur? user;

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
  }

  Future<List<CustomAppointment>> filterAppointments(
      Future<List<CustomAppointment>> appointmentsFuture) async {

    List<CustomAppointment> allAppointments = await appointmentsFuture;

    // Filtrer les rendez-vous avec startAt égal à DateTime.now()
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
                padding: const EdgeInsets.only(
                    top: 10, bottom: 20, right: 5, left: 5),
                child: FutureBuilder<List<CustomAppointment>>(
                  future: filterAppointments(userRepository!
                      .getAllAppointmentByPatient(
                          user!)), // Appelez votre fonction de récupération de données ici
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
                      if (snapshot.data!.length == 0) { return Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              color: Colors.transparent,
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
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.white,
                                        ),
                                        height: 130,
                                        width: MediaQuery.of(context).size.width -
                                            90,
                                        child: const Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                          children: [

                                            Padding(
                                              padding: EdgeInsets.only(top: 30,bottom: 10),
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
                                              color: Color.fromARGB(
                                                  230, 20, 20, 90),
                                            ),
                                          ],
                                        ),
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
                                color: Colors.transparent,
                              ),
                              width: MediaQuery.of(context).size.width / 1.2,
                              height: MediaQuery.of(context).size.height / 1.4,
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
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.redAccent,
                                                          letterSpacing: 2),
                                                    ),
                                                    Spacer()
                                                  ],
                                                )),
                                          ),
                                        ),
                                        Expanded(
                                            child: ListView.builder(
                                              physics: BouncingScrollPhysics(),
                                          padding:
                                              const EdgeInsets.only(top: 30),
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            List<CustomAppointment> listRDV =
                                                snapshot.data!;
                                            // Utilisez snapshot.data[index] pour accéder aux éléments de la liste

                                            return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15,
                                                    left: 5,
                                                    right: 5),
                                                child: Container(
                                                    width: 440,
                                                    height: 220,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Card(
                                                      elevation: 0,
                                                      color: Colors.white,
                                                      child: Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 10,
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
                                                                            50),
                                                                child:
                                                                    Container(
                                                                  width: 60,
                                                                  height: 60,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(5),
                                                                  ),
                                                                  child:
                                                                      CachedNetworkImage(
                                                                    imageUrl:
                                                                        '$baseUrl${utilities!.ajouterPrefixe(listRDV.elementAt(index).medecin!.imageName!)}',
                                                                    placeholder:
                                                                        (context,
                                                                                url) =>
                                                                            const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .redAccent,
                                                                    ), // Affiche un indicateur de chargement en attendant l'image
                                                                    errorWidget: (context,
                                                                            url,
                                                                            error) =>
                                                                        Icon(
                                                                      Icons
                                                                          .account_circle,
                                                                      size: 60,
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.6),
                                                                    ), // Affiche une icône d'erreur si le chargement échoue
                                                                  ),
                                                                ),
                                                              ),
                                                              Column(
                                                                children: [
                                                                  Text(
                                                                    'Dr ${listRDV.elementAt(index).medecin!.lastName[0]}.${abbreviateName(listRDV.elementAt(index).medecin!.firstName)}',
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
                                                          Row(children: [
                                                            const SizedBox(
                                                                width: 25),
                                                            Expanded(
                                                                child: Text(
                                                                    'Vous avez un rendez-vous prévu avec le Dr ${listRDV.elementAt(index).medecin!.lastName} ${abbreviateName(listRDV.elementAt(index).medecin!.firstName)}.',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.5)))),
                                                            const SizedBox(
                                                                width: 25),
                                                          ]),
                                                          const Spacer(),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Spacer(),
                                                              Image.asset(
                                                                'assets/images/date-limite.png',
                                                                width: 20,
                                                                height: 20,
                                                              ),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Text(
                                                                '${utilities!.formatTimeAppointmentNotif(listRDV.elementAt(index).startAt, listRDV.elementAt(index).timeStart, listRDV.elementAt(index).timeEnd)}',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            1000,
                                                                            60,
                                                                            70,
                                                                            120)),
                                                              ),
                                                              const Spacer(),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
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
