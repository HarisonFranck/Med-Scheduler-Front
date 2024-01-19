import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/main.dart';
import 'IndexAccueilAdmin.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class MedecinDetails extends StatefulWidget {
  _MedecinDetailsState createState() => _MedecinDetailsState();
  final Medecin user;

  MedecinDetails({required this.user});
}

class _MedecinDetailsState extends State<MedecinDetails> {
  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController villeController = TextEditingController();
  TextEditingController specController = TextEditingController();

  File? profilImage;

  late Medecin utilisateur;

  @override
  void initState() {
    super.initState();
    print('INIT ZAO');
    utilisateur = widget.user;

    profilImage =
        (utilisateur.imageName != null) ? File(utilisateur.imageName!) : null;
    nomController.text = utilisateur.firstName;
    prenomController.text = utilisateur.lastName;
    phoneController.text = utilisateur.phone;
    emailController.text = utilisateur.email;
    villeController.text = utilisateur.city;
    specController.text =
        (utilisateur.speciality != null) ? utilisateur.speciality!.label : "";
  }

  bool dataLoaded = false;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
                  padding:
                      const EdgeInsets.only(top: 30, right: 15, left: 15, bottom: 20),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, left: 30, bottom: 50),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: ((profilImage != null) &&
                                            profilImage!.existsSync())
                                        ? Image.file(
                                            profilImage!,
                                            fit: BoxFit.fill,
                                          )
                                        : Stack(
                                            children: [
                                              Icon(
                                                Icons.account_circle,
                                                size: 100,
                                                color: Colors.black
                                                    .withOpacity(0.6),
                                              ),
                                            ],
                                          )),
                              ),
                            ),
                            const Spacer()
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 50),
                              child: Text('Nom:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: nomController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 25),
                              child: Text('Prenom:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: prenomController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text('Specialite:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: specController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 40),
                              child: Text('Email:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: emailController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Text('Telephone:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: phoneController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 50),
                              child: Text('Ville:'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.8,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(230, 20, 20, 90),
                                      ),
                                    ),
                                  ),
                                  controller: villeController,
                                  readOnly: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: SizedBox(
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )),);
  }

  void ModificationUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Modification succès',

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

  void ModificationError(String errorDesc) {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: '$errorDesc',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void emailInvalide() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Invalide!',
        message: 'E-mail invalide!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void CreationUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Medecin crée',

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
