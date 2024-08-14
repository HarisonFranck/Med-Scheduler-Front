// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'Modification_MotdePasse.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Models/UtilisateurNewPassword.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';

class EmailValidation extends StatefulWidget {
  @override
  _EmailValidationState createState() => _EmailValidationState();
}

class _EmailValidationState extends State<EmailValidation> {
  bool isLoading = false;

  String baseUrl = UrlBase().baseUrl;

  Utilities? utilities;

  TextEditingController emailController = TextEditingController();

  FocusNode _focusNodemail = FocusNode();

  final GlobalKey<ScaffoldState> scafkey = GlobalKey<ScaffoldState>();

  final _emailValidator =
      RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
  }

  /// Validation du format E-mail
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail.';
    } else if (!_emailValidator.hasMatch(email.trim())) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    return null;
  }

  Future<void> getUser(String username) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${baseUrl}api/check-identifiant");

    final body = {"username": "$username"};

    try {
      final response = await http.post(url, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['user'] as dynamic;

        UtilisateurNewPassword user = UtilisateurNewPassword.fromJson(datas);
        setState(() {
          isLoading = false;
        });

        // ignore: use_build_context_synchronously
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Modification_MotdePasse(),
                settings: RouteSettings(arguments: user)));
      } else {
        if (response.statusCode == 422) {
          setState(() {
            isLoading = false;
          });
          if (!isLoading) {
            UserNotFound();
          }
        }
        // Gestion des erreurs HTTP
        if (response.statusCode == 401) {
          setState(() {
            isLoading = false;
          });
          if (!isLoading) {
            UserNotFound();
          }
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
      }

      print('Error: $e \nStack trace: $stackTrace');
      throw Exception('-- Failed to load data. Error: $e');
    }
  }

  Widget scafWithLoading() {
    return Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        key: scafkey,
        body: Stack(
          children: [
            ListView(
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
                    'Continuons,',
                    textScaler: TextScaler.linear(2.5),
                    style: TextStyle(
                        color: Color.fromARGB(1000, 60, 70, 120),
                        letterSpacing: 1.5),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.only(top: 40, bottom: 80, left: 40, right: 40),
                  child: Center(
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Text(
                        'Veuillez saisir l\'e-mail associé à votre compte Med Scheduler dans le champ ci-dessous. Assurez-vous d\'utiliser l\'adresse e-mail utilisée lors de votre inscription.',
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
                    focusNode: _focusNodemail,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      focusColor: const Color.fromARGB(255, 20, 20, 100),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 20, 20, 100))),
                      hintStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w300),
                      labelText: 'Adresse Email',
                      hintText: 'exemple@domaine.com',
                      labelStyle: TextStyle(
                          color: _focusNodemail.hasFocus
                              ? Colors.redAccent
                              : Colors.black),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      prefixIcon: const Icon(Icons.mail,
                          color: Color.fromARGB(1000, 60, 70, 120)),
                    ),
                  ),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(top: 40.0, left: 40, right: 40),
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
                        minimumSize:
                            MaterialStateProperty.all(const Size(260.0, 60.0)),
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();

                        /// Si les champs nouveau mot de passe et la confirmation mot de passe ne sont pas vide
                        if (emailController.text != "") {
                          String? mail = _validateEmail(emailController.text);

                          if (mail == null) {
                            getUser(emailController.text);
                          } else {
                            emailInvalide();
                          }
                        } else {}
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
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black.withOpacity(0.2),
            ),
            loadingWidget()
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: isLoading
          ? scafWithLoading()
          : Scaffold(
              backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
              key: scafkey,
              body: ListView(
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
                      'Continuons,',
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
                          'Veuillez saisir l\'e-mail associé à votre compte Med Scheduler dans le champ ci-dessous. Assurez-vous d\'utiliser l\'adresse e-mail utilisée lors de votre inscription.',
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
                      focusNode: _focusNodemail,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusColor: const Color.fromARGB(255, 20, 20, 100),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Adresse Email',
                        hintText: 'exemple@domaine.com',
                        labelStyle: TextStyle(
                            color: _focusNodemail.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        prefixIcon: const Icon(Icons.mail,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 40.0, left: 40, right: 40),
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
                          if (emailController.text != "") {
                            String? mail = _validateEmail(emailController.text);

                            if (mail == null) {
                              getUser(emailController.text);
                            } else {
                              emailInvalide();
                            }
                          } else {}
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
              ),
            ),
    );
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
        message: 'E-mail invalide.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

  void UserNotFound() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Introuvable!',
        message: 'Utilisateur introuvable.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
