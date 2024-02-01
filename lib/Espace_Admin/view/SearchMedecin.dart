import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'dart:io';
import 'Agenda.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';

class SearchMedecin extends StatefulWidget {
  SearchMedecinState createState() => SearchMedecinState();
}

class SearchMedecinState extends State<SearchMedecin> {
  late Future<List<Medecin>> medecinsFuture;

  BaseRepository? baseRepository;
  Utilities? utilities;

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  bool dataLoaded = false;

  Future<void> getAllAsync() async {
    medecinsFuture = baseRepository!.getAllMedecin();
  }

  @override
  void initState() {
    super.initState();
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
    print('-- INIT SEARCH  --');
    WidgetsFlutterBinding.ensureInitialized();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('I GET OO');
      await getAllAsync();
      setState(() {
        dataLoaded = true;
        print('LOADED OO');
      });
    });
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

  FocusNode _focusNodeSearch = FocusNode();
  TextEditingController searchLastName = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: (dataLoaded)
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 30, right: 30, bottom: 20, top: 60),
                        child: TextFormField(
                          onChanged: (nom) {
                            if (nom.trim().isEmpty) {
                              setState(() {
                                searchLastName.text = "";
                                medecinsFuture = baseRepository!.getAllMedecin();
                              });
                            } else {
                              setState(() {
                                searchLastName.text = nom;
                                medecinsFuture = baseRepository!.searchAllMedecin(searchLastName.text);
                                print('LASTNAME: ${searchLastName.text}');
                              });
                            }
                          },
                          focusNode: _focusNodeSearch,
                          controller: searchLastName,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            focusColor: const Color.fromARGB(255, 20, 20, 100),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 0,
                                  color: Color.fromARGB(255, 20, 20, 100)),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            hintStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w300),

                            hintText: 'Rechercher un medecin ',
                            labelStyle: TextStyle(
                                color: _focusNodeSearch.hasFocus
                                    ? Colors.redAccent
                                    : Colors.black),
                            border: InputBorder
                                .none, // Utilisez InputBorder.none pour supprimer la bordure
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(width: 0, color: Colors.grey),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: Color.fromARGB(1000, 60, 70, 120)),
                          ),
                        ),
                      ),
                      Expanded(
                          flex: 3,
                          child: FutureBuilder<List<Medecin>>(
                            future: medecinsFuture,
                            builder: (context, medecinsSnapshot) {
                              if (medecinsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height/4),child:  Center(
                                  child: ListView(
                                    children: [
                                      Center(
                                        child: loadingWidget(),
                                      ),
                                      const SizedBox(
                                        height: 30,
                                      ),
                                      const Text(
                                        'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                                        textAlign: TextAlign.center,
                                      )
                                    ],
                                  ),
                                )
                                );
                              } else if (medecinsSnapshot.hasError) {
                                return Center(
                                  child:
                                      Text('Il y a une erreur d\'obtention des données',style: TextStyle(color: Colors.black.withOpacity(0.5)),textAlign: TextAlign.center,),
                                );
                              } else {
                                List<Medecin> medecins = medecinsSnapshot.data!;

                                if (medecins.isEmpty) {
                                  return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18,
                                          left: 18,
                                          top: 20,
                                          bottom: 10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: Container(
                                          height: 200,
                                          child: Card(
                                            elevation: 0.5,
                                            color: Colors.white,
                                            child: ListView(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 20,
                                                      top: 10,
                                                      right: 50),
                                                  child: Text(
                                                    'Medecin introuvable!\nMerci de rechercher les médecins avec la barre de recherche ci-dessus...',
                                                    style: TextStyle(
                                                        fontSize: 17,
                                                        color: Colors.grey
                                                            .withOpacity(0.9),
                                                        letterSpacing: 2),
                                                  ),
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
                                      ));
                                }

                                return ListView.builder(
                                  itemCount: medecins.length,
                                  itemBuilder: (context, index) {
                                    Medecin medecin = medecins[index];

                                    return Padding(
                                        padding: const EdgeInsets.only(
                                            right: 18, left: 18, bottom: 10),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          child: Container(
                                            height: 200,
                                            child: Card(
                                              elevation: 0.5,
                                              color: Colors.white,
                                              child: Column(
                                                children: [
                                                  const Spacer(),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      const SizedBox(
                                                        width: 20,
                                                      ),
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                        child: Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        60),
                                                          ),
                                                          child: ((medecin.imageName !=
                                                                      null) &&
                                                                  (File(medecin
                                                                          .imageName!)
                                                                      .existsSync()))
                                                              ? Image.file(File(
                                                                  medecin
                                                                      .imageName!))
                                                              : Image.asset(
                                                                  'assets/images/medecin.png',
                                                                  fit: BoxFit
                                                                      .fill,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Column(
                                                        children: [
                                                          Text(
                                                            '${medecin.lastName[0]}.${abbreviateName(medecin.firstName)}',
                                                            style: const TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        1000,
                                                                        60,
                                                                        70,
                                                                        120),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          ),
                                                          Text(
                                                            '${(medecin.speciality != null) ? medecin.speciality!.label : ""}',
                                                            style: const TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        1000,
                                                                        60,
                                                                        70,
                                                                        120),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300),
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
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                left: 30,
                                                                right: 10),
                                                        child: Image.asset(
                                                          'assets/images/date-limite.png',
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                      ),
                                                      const Text(
                                                        '5rdv/jour',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    1000,
                                                                    60,
                                                                    70,
                                                                    120)),
                                                      ),
                                                      const Spacer(),
                                                      const Icon(
                                                        Icons.watch_later,
                                                        color: Colors.redAccent,
                                                      ),
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 5,
                                                                right: 15),
                                                        child: Text(
                                                          'Disponible de 08:00',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      1000,
                                                                      60,
                                                                      70,
                                                                      120)),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Padding(
                                                      padding: const EdgeInsets.only(
                                                          top: 15.0,
                                                          left: 10,
                                                          right: 10,
                                                          bottom: 15),
                                                      child: ElevatedButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              MaterialStateProperty
                                                                  .all(const Color
                                                                      .fromARGB(
                                                                          1000,
                                                                          60,
                                                                          70,
                                                                          120)),
                                                          shape:
                                                              MaterialStateProperty
                                                                  .all(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0), // Définissez le rayon de la bordure ici
                                                            ),
                                                          ),
                                                          minimumSize:
                                                              MaterialStateProperty
                                                                  .all(const Size(
                                                                      180.0,
                                                                      40.0)),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      Agenda(),
                                                                  settings: RouteSettings(
                                                                      arguments:
                                                                          medecin)));
                                                        },
                                                        child: const Text(
                                                          'Voir Agenda',
                                                          textScaleFactor: 1.2,
                                                          style: TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    253,
                                                                    253,
                                                                    253),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ));
                                  },
                                );
                              }
                            },
                          ))
                    ],
                  )
                : loadingWidget()),);
  }




}
