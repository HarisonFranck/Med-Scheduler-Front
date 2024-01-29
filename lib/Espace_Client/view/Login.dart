import 'package:flutter/material.dart';
import 'Registration.dart';
import 'EmailValidation.dart';
import 'package:flutter/services.dart';
import 'package:med_scheduler_front/main.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'IndexAccueil.dart';
import 'package:med_scheduler_front/Espace_Medecin/view/IndexAcceuilMedecin.dart';
import 'package:med_scheduler_front/Espace_Admin/view/IndexAccueilAdmin.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isLoading = false;

  String baseUrl = UrlBase().baseUrl;

  BaseRepository? baseRepository;
  Utilities? utilities;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);
  }

  Future<void> getUserByUsernameAndPassword(
      String email, String password) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${baseUrl}api/login_check");
    final headers = {'Content-Type': 'application/json'};

    try {
      Map<String, String> requestData = {
        'username': email,
        'password': password
      };

      final jsonEncode = json.encode(requestData);

      final response = await http.post(url, headers: headers, body: jsonEncode);
      print(response.statusCode);

      if (response.statusCode == 200) {
        if (response.body == null || response.body.isEmpty) {
          setState(() {
            isLoading = false;
          });

          // Utilisateur non trouvé
          utilities!.error('Utilisateur introuvable');
        } else {
          String token = jsonDecode(response.body)['token'];

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.setToken(token);

          Map<String, dynamic> payload = Jwt.parseJwt(token);

          int idUser = payload['id'];
          print('ID USER INDEXED: $idUser');

          Utilisateur utilisateur =
              await baseRepository!.getUserById(idUser, token);

          setState(() {
            isLoading = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => utilisateur.userType == "Admin"
                  ? IndexAccueilAdmin()
                  : (utilisateur.userType == "Doctor"
                      ? IndexAcceuilMedecin()
                      : IndexAccueil()),
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        // Gestion des erreurs HTTP
        print('ERROR');
        utilities!.loginFailed();
        //throw Exception('-- Failed to get user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      setState(() {
        isLoading = false;
      });
      // Gestion des erreurs autres que HTTP
      print('ERROR CONNEXION');
      utilities!.ErrorConnexion();
      throw Exception('-- Failed to get user. Error: $e\n STACK: $stacktrace');
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print('DID OO: $isLoading');

    setState(() {
      isLoading = isLoading;
    });
    print('FARANY DID OO: $isLoading');
  }

  void errorConnexion(String description) {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: Colors.redAccent,
      dialogType: DialogType.info,
      btnCancelColor: Colors.grey,
      animType: AnimType.rightSlide,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2, color: Colors.white.withOpacity(0.8), fontSize: 16),
      title: 'Erreur de connexion',
      desc: '$description',
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
    ).show();
  }

  void error(String description) {
    AwesomeDialog(
      dialogBackgroundColor: Colors.redAccent,
      btnCancelColor: Colors.grey,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2, color: Colors.white.withOpacity(0.8), fontSize: 16),
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Erreur',
      desc: '$description',
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
    ).show();
  }

  TextEditingController passwordController = TextEditingController();
  TextEditingController identifiantController = TextEditingController();
  TextEditingController emailpasswordController = TextEditingController();

  bool isForget = false;
  bool obscurepwd = true;

  final _emailValidator =
      RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  /// Validation du format E-mail
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail.';
    } else if (!_emailValidator.hasMatch(email.trim())) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    return null;
  }

  final FocusNode _focusNodepass = FocusNode();
  final FocusNode _focusNodemail = FocusNode();

  Widget scafWithLoading() {
    return Stack(
      children: [
        ListView(
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
                              builder: (context) => const MyApp()));
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
                          "assets/images/logo2.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Center(
              child: Text(
                'Bienvenue,',
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
                    'Accédez à vos informations de santé en toute sécurité avec notre formulaire de connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color.fromARGB(1000, 60, 70, 120),
                        letterSpacing: 1.3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 35, right: 35, bottom: 35),
              child: TextFormField(
                focusNode: _focusNodemail,
                controller: identifiantController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusColor: const Color.fromARGB(255, 20, 20, 100),
                  focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 20, 20, 100))),
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
              padding: const EdgeInsets.only(left: 35, right: 35, bottom: 20),
              child: TextFormField(
                focusNode: _focusNodepass,
                controller: passwordController,
                obscureText: obscurepwd ? true : false,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 20, 20, 100))),
                  hintStyle: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w300),
                  labelText: 'Mot de passe',
                  hintText: 'Entrer votre mot de passe',
                  labelStyle: TextStyle(
                      color: _focusNodepass.hasFocus
                          ? Colors.redAccent
                          : Colors.black),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        obscurepwd = !obscurepwd;
                      });
                    },
                    child: Icon(
                      obscurepwd ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.password,
                      color: Color.fromARGB(1000, 60, 70, 120)),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 35, right: 35),
                child: Row(
                  children: [
                    TextButton(
                      child: const Text(
                        'Mot de passe oublié',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onPressed: () {
                        print('Inscription');

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EmailValidation()));
                      },
                    ),
                  ],
                )),
            Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 40, right: 40),
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

                    if (identifiantController.text != "" &&
                        passwordController.text != "") {
                      String? mail = _validateEmail(identifiantController.text);

                      if (mail == null) {
                        if (identifiantController.text == "Admin@gmail.com" &&
                            passwordController.text == "Admin") {
                          //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>IndexBottom()));
                        } else {
                          /// Validation du format E-Mail

                          if (mail == null) {
                            String email = identifiantController.text;
                            String motdepasse = passwordController.text;
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitDown,
                              DeviceOrientation.portraitUp
                            ]);

                            getUserByUsernameAndPassword(email, motdepasse);
                          } else {
                            utilities!.emailInvalide();
                          }
                        }
                      } else {
                    utilities!.emailInvalide();
                      }
                    } else {
                    utilities!.ChampsIncomplets();
                    }
                  },
                  child: const Text(
                    'Se connecter',
                    textScaleFactor: 1.5,
                    style: TextStyle(
                      color: Color.fromARGB(255, 253, 253, 253),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.only(
                  top: 15, left: 35, right: 35, bottom: 30),
              child: TextButton(
                child: const Text(
                  'Vous n\'avez pas de compte? S\'incrire',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () {
                  print('Inscription');

                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Registration()));
                },
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    print('LOADING IS: $isLoading');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        body: isLoading
            ? scafWithLoading()
            : ListView(
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
                                    builder: (context) => const MyApp()));
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
                                "assets/images/logo2.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Bienvenue,',
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
                          'Accédez à vos informations de santé en toute sécurité avec notre formulaire de connexion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color.fromARGB(1000, 60, 70, 120),
                              letterSpacing: 1.3),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 35),
                    child: TextFormField(
                      focusNode: _focusNodemail,
                      controller: identifiantController,
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
                        const EdgeInsets.only(left: 35, right: 35, bottom: 20),
                    child: TextFormField(
                      focusNode: _focusNodepass,
                      controller: passwordController,
                      obscureText: obscurepwd ? true : false,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Mot de passe',
                        hintText: 'Entrer votre mot de passe',
                        labelStyle: TextStyle(
                            color: _focusNodepass.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
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
                        prefixIcon: const Icon(Icons.password,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 35, right: 35),
                      child: Row(
                        children: [
                          TextButton(
                            child: const Text(
                              'Mot de passe oublié',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            onPressed: () {
                              print('Inscription');

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EmailValidation()));
                            },
                          ),
                        ],
                      )),
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
                        onPressed: Connecter,
                        child: const Text(
                          'Se connecter',
                          textScaleFactor: 1.5,
                          style: TextStyle(
                            color: Color.fromARGB(255, 253, 253, 253),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 15, left: 35, right: 35, bottom: 30),
                    child: TextButton(
                      child: const Text(
                        'Vous n\'avez pas de compte? S\'incrire',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onPressed: () {
                        print('Inscription');

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Registration()));
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  )
                ],
              ),
      ),
    );
  }

  void Connecter() {
    print('IS LOADING: $isLoading');
    FocusScope.of(context).unfocus();

    if (identifiantController.text != "" && passwordController.text != "") {
      String? mail = _validateEmail(identifiantController.text);

      if (mail == null) {
        if (identifiantController.text == "Admin@gmail.com" &&
            passwordController.text == "Admin") {
          //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>IndexBottom()));
        } else {
          /// Validation du format E-Mail

          if (mail == null) {
            String email = identifiantController.text;
            String motdepasse = passwordController.text;
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

            getUserByUsernameAndPassword(email, motdepasse);


            print('IS LOADING: $isLoading');
          } else {
            utilities!.emailInvalide();


            print('IS LOADING: $isLoading');
          }
        }
      } else {
        utilities!.emailInvalide();


        print('IS LOADING: $isLoading');
      }
    } else {
      utilities!.ChampsIncomplets();


      print('IS LOADING: $isLoading');
    }
  }



}
