import 'package:flutter/material.dart';
import 'Login.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:med_scheduler_front/Models/UtilisateurNewPassword.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:med_scheduler_front/Models/main.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';

class Modification_MotdePasse extends StatefulWidget {
  @override
  _Modification_MotdePasseState createState() =>
      _Modification_MotdePasseState();
}

class _Modification_MotdePasseState extends State<Modification_MotdePasse> {
  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  bool isLoading = false;

  UserRepository? userRepository;
  Utilities? utilities;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);
  }

  TextEditingController newmdpController = TextEditingController();

  TextEditingController confirmnewmdpController = TextEditingController();

  bool obscurepwd = true;
  bool obscureconfirmpwd = true;

  final GlobalKey<ScaffoldState> scafkey = GlobalKey<ScaffoldState>();

  Future<void> patchUserPassword(int id, String newPassword) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${baseUrl}api/change-password/$id");

    final body = {"password": "$newPassword"};

    try {
      final response = await http.patch(url, body: jsonEncode(body));

      if (response.statusCode == 200) {
        utilities!.modifPasswordValider();
        await Future.delayed(const Duration(seconds: 4));

        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) => Login()), (route) => false);
        setState(() {
          isLoading = false;
        });
      } else {
        // Gestion des erreurs HTTP
        setState(() {
          isLoading = false;
        });
        if (response.statusCode == 401) {
          authProvider.logout();
          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
            (route) => false,
          );
        }
        throw Exception('ANOTHER ERROR');
      }
    } catch (e, stackTrace) {
      setState(() {
        isLoading = false;
      });
      if (e is http.ClientException) {
        utilities!.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      } else {
        // Gérer d'autres exceptions
      }
      throw Exception('-- Failed to load data. Error: $e');
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

  @override
  Widget build(BuildContext context) {
    UtilisateurNewPassword user =
        ModalRoute.of(context)?.settings.arguments as UtilisateurNewPassword;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        key: scafkey,
        body: (!isLoading)
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => Login()));
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_left,
                            size: 40,
                          ),
                          const Text('Retour'),
                          Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width - 170),
                            child: Center(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'En cours...',
                      textScaler: TextScaler.linear(2.5),
                      style: TextStyle(
                          color: Color.fromARGB(1000, 60, 70, 120),
                          letterSpacing: 1.5),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                        top: 40, bottom: 80, left: 40, right: 40),
                    child: Center(
                      child: Card(
                        color: Colors.transparent,
                        elevation: 0,
                        child: Text(
                          'Créez votre nouvelle clé de sécurité en utilisant notre formulaire de modification du mot de passe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color.fromARGB(1000, 60, 70, 120),
                              letterSpacing: 1.3),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      controller: newmdpController,
                      obscureText: obscurepwd ? true : false,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintStyle: const TextStyle(color: Colors.black),
                        labelText: 'Nouveau mot de passe',
                        hintText: 'Entrer votre nouveau mot de passe',
                        labelStyle: const TextStyle(color: Colors.black),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              obscurepwd = !obscurepwd;
                            });
                          },
                          child: Icon(
                            obscurepwd
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon:
                            const Icon(Icons.password, color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      controller: confirmnewmdpController,
                      obscureText: obscureconfirmpwd ? true : false,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintStyle: const TextStyle(color: Colors.black),
                        labelText: 'Confirmation mot de passe',
                        hintText: 'Confirmer votre mot de passe',
                        labelStyle: const TextStyle(color: Colors.black),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              obscureconfirmpwd = !obscureconfirmpwd;
                            });
                          },
                          child: Icon(
                            obscureconfirmpwd
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon:
                            const Icon(Icons.password, color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 20.0, left: 40, right: 40),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromARGB(1000, 60, 70, 120)),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Définissez le rayon de la bordure ici
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all(
                              const Size(260.0, 60.0)),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();

                          /// Si les champs nouveau mot de passe et la confirmation mot de passe ne sont pas vide
                          if (newmdpController.text != "" &&
                              confirmnewmdpController.text != "") {
                            /// Si les champs nouveau mot de passe et la confirmation mot de passe sont les mêmes
                            if (newmdpController.text ==
                                confirmnewmdpController.text) {
                              patchUserPassword(user.id, newmdpController.text);
                            } else {
                              /// Quand le nouveau mot de passe et confirmation mot de passe ne sont pas les memes
                              Correspondance();
                            }
                          } else {
                            /// Quand les champs sont vides
                            ChampsIncomplets();
                          }
                        },
                        child: const Text(
                          'Valider',
                          textScaleFactor: 1.5,
                          style: TextStyle(
                            color: Color.fromARGB(255, 253, 253, 253),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                  const SizedBox(
                    height: 20,
                  )
                ],
              )
            : loadingWidget(),
      ),
    );
  }

  void Correspondance() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: 'Les mots de passe ne correspondent pas.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void ChampsIncomplets() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: 'Champs incomplets!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
