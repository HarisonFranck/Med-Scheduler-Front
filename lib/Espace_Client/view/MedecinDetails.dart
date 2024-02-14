import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:med_scheduler_front/AuthProviderUser.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';

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

  String baseUrl = UrlBase().baseUrl;

  Utilities? utilities;

  File? profilImage;

  late Medecin utilisateur;

  late AuthProviderUser authProviderUser;

  @override
  void initState() {
    utilities = Utilities(context: context);
    super.initState();
    print('INIT ZAO');
    utilisateur = widget.user;

    profilImage =
    (utilisateur.imageName != null) ? File(utilisateur.imageName!) : null;
    nomController.text = utilisateur.firstName;
    prenomController.text = utilisateur.lastName;
    phoneController.text = utilities!.formatPhoneNumber(utilisateur.phone);
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
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);
    utilities = Utilities(context: context);
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

                      Navigator.pop(context);
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
                    child: CachedNetworkImage(
                        imageUrl:
                        '$baseUrl${utilities!.ajouterPrefixe(utilisateur.imageName!)}',
                    placeholder: (context,
                        url) =>
                    const CircularProgressIndicator(
                      color: Colors
                          .redAccent,
                    ), // Affiche un indicateur de chargement en attendant l'image
                    errorWidget: (context,
                        url,
                        error) =>
                        Image.asset(
                          'assets/images/medecin.png',
                          fit: BoxFit
                              .cover,
                          width: 50,
                          height: 50,
                        ), // Affiche une icône d'erreur si le chargement échoue
                  ),
                ),
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
