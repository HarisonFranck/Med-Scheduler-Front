import 'package:flutter/material.dart';
import 'Login.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:med_scheduler_front/Models/Categorie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/Models/main.dart';
import 'dart:async';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:uuid/uuid.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:flutter/services.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final TextEditingController phoneNumberController = TextEditingController();

  BaseRepository? baseRepository;

  String baseUrl = UrlBase().baseUrl;

  bool isLoading = false;

  Utilities? utilities;

  late AuthProviderUser authProviderUser;
  late AuthProvider authProvider;
  late String token;

  TextEditingController path = TextEditingController();
  StreamController<bool> _permissionStatusController = StreamController<bool>();

  Stream<bool> get permissionStatusStream => _permissionStatusController.stream;

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);
  }

  List<Categorie> listCategorie = [];

  //Fonction pour stocker les categories trouvés
  void getAll() {
    baseRepository!.getAllCategorie().then((value) => {
          setState(() {
            listCategorie = value;
          })
        });
  }

  void formatPhoneNumberText() {
    final unformattedText =
        phoneNumberController.text.replaceAll(RegExp(r'\D'), '');

    String formattedText = '';
    int index = 0;
    final groups = [2, 2, 3, 2];

    for (final group in groups) {
      final endIndex = index + group;
      if (endIndex <= unformattedText.length) {
        formattedText += unformattedText.substring(index, endIndex);
        if (endIndex < unformattedText.length) {
          formattedText += ' ';
        }
        index = endIndex;
      } else {
        formattedText += unformattedText.substring(index);
        break;
      }
    }

    phoneNumberController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  @override
  void initState() {
    super.initState();
    phoneNumberController.addListener(formatPhoneNumberText);
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);

    getAll();
  }

  @override
  void dispose() {
    phoneNumberController.removeListener(formatPhoneNumberText);
    phoneNumberController.dispose();
    super.dispose();
  }

  void success() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Succès'),
          content: Text(
            'Utilisateur créé avec succès.',
            textScaleFactor: 1.3,
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        );
      },
    );

    // Fermer la boîte de dialogue après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pop();
    });
  }

  Future<void> addUser(Utilisateur utilisateur) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("${baseUrl}api/users");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {'Content-Type': 'application/ld+json'};

    try {
      String jsonUser = jsonEncode(utilisateur.toJson());

      final response = await http.post(url, headers: headers, body: jsonUser);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('error')) {
          setState(() {
            isLoading = false;
          });

          utilities!.error('Utilisateur déja existant');
        } else {
          setState(() {
            isLoading = false;
          });

          CreationUtilisateur();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Login()));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        // Gestion des erreurs HTTP
        utilities!.ErrorConnexion();
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      utilities!.ErrorConnexion();

      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController imageController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addresseController = TextEditingController();
  TextEditingController villeController = TextEditingController();

  bool obscurepwd = true;
  bool obscureconfpwd = true;

  Categorie? categorie;

  final _emailValidator =
      RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  FocusNode _focusNodenom = FocusNode();
  FocusNode _focusNodeprenom = FocusNode();
  FocusNode _focusNodemail = FocusNode();
  FocusNode _focusNodephone = FocusNode();
  FocusNode _focusNodecategorie = FocusNode();
  FocusNode _focusNodepass = FocusNode();
  FocusNode _focusNodeconfpass = FocusNode();
  FocusNode _focusNodeaddresse = FocusNode();
  FocusNode _focusNodeville = FocusNode();

  /// Validation du format E-mail
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail.';
    } else if (!_emailValidator.hasMatch(email.trim())) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    return null;
  }

  String generateUniqueImageName() {
    // Générer un jeton UUID (Universally Unique Identifier)
    var uuid = const Uuid();

    return uuid
        .v4()
        .substring(0, 6); // Utilisez les 6 premiers caractères du UUID
  }

  final GlobalKey<ScaffoldState> scafkey = GlobalKey<ScaffoldState>();

  String? cat;

  Widget scafWithLoading() {
    return Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        key: scafkey,
        body: (listCategorie.isNotEmpty)
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyApp()));
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
                      'Commençons,',
                      textScaler: TextScaler.linear(2.5),
                      style: TextStyle(
                          color: Color.fromARGB(1000, 60, 70, 120),
                          letterSpacing: 1.5),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                        top: 40, bottom: 20, left: 40, right: 40),
                    child: Center(
                      child: Card(
                        color: Colors.transparent,
                        elevation: 0,
                        child: Text(
                          'Accédez à notre application de planification de rendez-vous médical avec notre formulaire d’inscription',
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
                        top: 30, left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodenom,
                      controller: nomController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Nom',
                        hintText: 'Entrer votre nom',
                        labelStyle: TextStyle(
                            color: _focusNodenom.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.person_2_rounded,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodeprenom,
                      controller: prenomController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Prenom',
                        hintText: 'Entrer votre prenom',
                        labelStyle: TextStyle(
                            color: _focusNodeprenom.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.person_2_rounded,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodemail,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'E-mail',
                        hintText: 'exemple@domaine.com',
                        labelStyle: TextStyle(
                            color: _focusNodemail.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.mail,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodephone,
                      controller: phoneNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black),
                      maxLength: 12,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9)
                      ],
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Telephone',
                        hintText: 'ex: 38 00 200 20',
                        prefixText: '+261 ',
                        prefixStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.7)),
                        labelStyle: TextStyle(
                            color: _focusNodephone.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 30.0, right: 35, left: 35),
                    child: DropdownButtonFormField<Categorie>(
                      focusNode: _focusNodecategorie,
                      icon: const Icon(
                        Icons.arrow_drop_down_circle_outlined,
                        color: Colors.black,
                      ),
                      value: categorie,
                      onChanged: (Categorie? newval) {
                        setState(() {
                          categorie = newval;
                        });
                      },
                      items: listCategorie.map((e) {
                        return DropdownMenuItem<Categorie>(
                          value: e,
                          child: Text('${e.title}'),
                        );
                      }).toList(),
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 20, 20, 100))),
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)),
                          prefixIcon: const Icon(
                            Icons.people,
                            color: Color.fromARGB(1000, 60, 70, 120),
                          ),
                          labelStyle: TextStyle(
                              color: _focusNodecategorie.hasFocus
                                  ? Colors.redAccent
                                  : Colors.black),
                          hintStyle: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w300),
                          labelText: 'Categorie Patient',
                          hintText: '-- Plus d\'options --',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0))),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodeaddresse,
                      controller: addresseController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Addresse',
                        hintText: 'Entrer votre addresse',
                        labelStyle: TextStyle(
                            color: _focusNodeprenom.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.location_on,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodeville,
                      controller: villeController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Ville',
                        hintText: 'Entrer votre ville',
                        labelStyle: TextStyle(
                            color: _focusNodeprenom.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(Icons.location_city,
                            color: Color.fromARGB(1000, 60, 70, 120)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextFormField(
                      focusNode: _focusNodepass,
                      controller: passwordController,
                      obscureText: obscurepwd ? true : false,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
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
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 20),
                    child: TextFormField(
                      focusNode: _focusNodeconfpass,
                      controller: confirmPasswordController,
                      obscureText: obscureconfpwd ? true : false,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 20, 20, 100))),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        labelText: 'Confirmer Mot de passe',
                        hintText: 'Confirmer votre mot de passe',
                        labelStyle: TextStyle(
                            color: _focusNodeconfpass.hasFocus
                                ? Colors.redAccent
                                : Colors.black),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              obscureconfpwd = !obscureconfpwd;
                            });
                          },
                          child: Icon(
                            obscureconfpwd
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
                    padding:
                        const EdgeInsets.only(left: 35, right: 35, bottom: 30),
                    child: TextButton(
                      child: const Text(
                        'Vous avez déjà un compte? S\'authentifier ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Login()));
                      },
                    ),
                  ),
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 10.0, left: 50, right: 50),
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
                              MaterialStateProperty.all(const Size(50.0, 60.0)),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();

                          print(
                              '+261${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}');

                          if (passwordController.text ==
                              confirmPasswordController.text) {
                            if (nomController.text != "" &&
                                prenomController.text != "" &&
                                emailController.text != "" &&
                                phoneNumberController.text != "" &&
                                passwordController.text != "" &&
                                confirmPasswordController.text != "" &&
                                categorie != null &&
                                addresseController.text != "" &&
                                villeController.text != "") {
                              String? mail =
                                  _validateEmail(emailController.text);

                              if (mail == null) {
                                String phone =
                                    '${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}';
                                if (phone.length != 9) {
                                  if (phone.startsWith('32') ||
                                      phone.startsWith('33') ||
                                      phone.startsWith('34') ||
                                      phone.startsWith('38') ||
                                      phone.startsWith('37')) {
                                    String number =
                                        "+261${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}";
                                    Utilisateur user = Utilisateur(
                                        id: '',
                                        lastName: nomController.text.trim(),
                                        roles: ['ROLE_USER'],
                                        firstName: prenomController.text.trim(),
                                        password:
                                            passwordController.text.trim(),
                                        userType: 'Patient',
                                        phone: number,
                                        email: emailController.text.trim(),
                                        imageName: (path.text != "")
                                            ? path.text.trim()
                                            : "",
                                        category: utilities!
                                            .extractApiPath(categorie!.id),
                                        address: addresseController.text.trim(),
                                        createdAt: DateTime.now(),
                                        city: villeController.text.trim());
                                    addUser(user);
                                  } else {
                                    utilities!.ModificationError(
                                        'Veuillez inserer un numero valide');
                                  }
                                } else {
                                  utilities!.ModificationError(
                                      'Veuillez inserer un numero valide');
                                }
                              } else {
                                //print('MAIL NON VALIDE');
                                emailInvalide();
                              }
                            } else {
                              ChampsIncomplets();
                            }
                          } else {
                            PasswordIsNotTheSame();
                          }
                        },
                        child: const Text(
                          'Enregistrer',
                          textScaleFactor: 1.5,
                          style: TextStyle(
                            color: Color.fromARGB(255, 253, 253, 253),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                  const SizedBox(
                    height: 50,
                  )
                ],
              )
            : Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  loadingWidget(),
                  SizedBox(
                    height: 30,
                  ),
                  Text(
                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                    textAlign: TextAlign.center,
                  )
                ],
              )));
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
              body: (listCategorie.isNotEmpty)
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MyApp()));
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
                                      left: MediaQuery.of(context).size.width -
                                          170),
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
                            'Commençons,',
                            textScaler: TextScaler.linear(2.5),
                            style: TextStyle(
                                color: Color.fromARGB(1000, 60, 70, 120),
                                letterSpacing: 1.5),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(
                              top: 40, bottom: 20, left: 40, right: 40),
                          child: Center(
                            child: Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: Text(
                                'Accédez à notre application de planification de rendez-vous médical avec notre formulaire d’inscription',
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
                              top: 30, left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodenom,
                            controller: nomController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Nom',
                              hintText: 'Entrer votre nom',
                              labelStyle: TextStyle(
                                  color: _focusNodenom.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.person_2_rounded,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodeprenom,
                            controller: prenomController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Prenom',
                              hintText: 'Entrer votre prenom',
                              labelStyle: TextStyle(
                                  color: _focusNodeprenom.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.person_2_rounded,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodemail,
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'E-mail',
                              hintText: 'exemple@domaine.com',
                              labelStyle: TextStyle(
                                  color: _focusNodemail.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.mail,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodephone,
                            controller: phoneNumberController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            maxLength: 12,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9)
                            ],
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Telephone',
                              hintText: 'ex: 38 00 200 20',
                              prefixText: '+261 ',
                              prefixStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withOpacity(0.7)),
                              labelStyle: TextStyle(
                                  color: _focusNodephone.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 30.0, right: 35, left: 35),
                          child: DropdownButtonFormField<Categorie>(
                            focusNode: _focusNodecategorie,
                            icon: const Icon(
                              Icons.arrow_drop_down_circle_outlined,
                              color: Colors.black,
                            ),
                            value: categorie,
                            onChanged: (Categorie? newval) {
                              setState(() {
                                categorie = newval;
                              });
                            },
                            items: listCategorie.map((e) {
                              return DropdownMenuItem<Categorie>(
                                value: e,
                                child: Text('${e.title}'),
                              );
                            }).toList(),
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 20, 20, 100))),
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey)),
                                prefixIcon: const Icon(
                                  Icons.people,
                                  color: Color.fromARGB(1000, 60, 70, 120),
                                ),
                                labelStyle: TextStyle(
                                    color: _focusNodecategorie.hasFocus
                                        ? Colors.redAccent
                                        : Colors.black),
                                hintStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300),
                                labelText: 'Categorie Patient',
                                hintText: '-- Plus d\'options --',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodeaddresse,
                            controller: addresseController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Addresse',
                              hintText: 'Entrer votre addresse',
                              labelStyle: TextStyle(
                                  color: _focusNodeprenom.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.location_on,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodeville,
                            controller: villeController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Ville',
                              hintText: 'Entrer votre ville',
                              labelStyle: TextStyle(
                                  color: _focusNodeprenom.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.location_city,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextFormField(
                            focusNode: _focusNodepass,
                            controller: passwordController,
                            obscureText: obscurepwd ? true : false,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
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
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 20),
                          child: TextFormField(
                            focusNode: _focusNodeconfpass,
                            controller: confirmPasswordController,
                            obscureText: obscureconfpwd ? true : false,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 20, 20, 100))),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              labelText: 'Confirmer Mot de passe',
                              hintText: 'Confirmer votre mot de passe',
                              labelStyle: TextStyle(
                                  color: _focusNodeconfpass.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    obscureconfpwd = !obscureconfpwd;
                                  });
                                },
                                child: Icon(
                                  obscureconfpwd
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
                          padding: const EdgeInsets.only(
                              left: 35, right: 35, bottom: 30),
                          child: TextButton(
                            child: const Text(
                              'Vous avez déjà un compte? S\'authentifier ici',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Login()));
                            },
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(
                                top: 10.0, left: 50, right: 50),
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
                                    const Size(50.0, 60.0)),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();

                                print(
                                    '+261${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}');

                                if (passwordController.text ==
                                    confirmPasswordController.text) {
                                  if (nomController.text != "" &&
                                      prenomController.text != "" &&
                                      emailController.text != "" &&
                                      phoneNumberController.text != "" &&
                                      passwordController.text != "" &&
                                      confirmPasswordController.text != "" &&
                                      categorie != null &&
                                      addresseController.text != "" &&
                                      villeController.text != "") {
                                    String? mail =
                                        _validateEmail(emailController.text);

                                    if (mail == null) {
                                      String phone =
                                          '${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}';
                                      if (phone.length != 9) {
                                        if (phone.startsWith('32') ||
                                            phone.startsWith('33') ||
                                            phone.startsWith('34') ||
                                            phone.startsWith('38') ||
                                            phone.startsWith('37')) {
                                          String number =
                                              "+261${phoneNumberController.text.replaceAll(RegExp(r'\s+'), '')}";
                                          Utilisateur user = Utilisateur(
                                              id: '',
                                              lastName:
                                                  nomController.text.trim(),
                                              roles: ['ROLE_USER'],
                                              firstName:
                                                  prenomController.text.trim(),
                                              password: passwordController.text
                                                  .trim(),
                                              userType: 'Patient',
                                              phone: number,
                                              email:
                                                  emailController.text.trim(),
                                              imageName: (path.text != "")
                                                  ? path.text.trim()
                                                  : "",
                                              category: utilities!
                                                  .extractApiPath(
                                                      categorie!.id),
                                              address: addresseController.text
                                                  .trim(),
                                              createdAt: DateTime.now(),
                                              city:
                                                  villeController.text.trim());
                                          addUser(user);
                                        } else {
                                          utilities!.ModificationError(
                                              'Veuillez inserer un numero valide');
                                        }
                                      } else {
                                        utilities!.ModificationError(
                                            'Veuillez inserer un numero valide');
                                      }
                                    } else {
                                      //print('MAIL NON VALIDE');
                                      emailInvalide();
                                    }
                                  } else {
                                    ChampsIncomplets();
                                  }
                                } else {
                                  PasswordIsNotTheSame();
                                }
                              },
                              child: const Text(
                                'Enregistrer',
                                textScaleFactor: 1.5,
                                style: TextStyle(
                                  color: Color.fromARGB(255, 253, 253, 253),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )),
                        const SizedBox(
                          height: 50,
                        )
                      ],
                    )
                  : Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loadingWidget(),
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                          textAlign: TextAlign.center,
                        )
                      ],
                    ))),
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

  void CreationUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Utilisateur crée',

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

  void PasswordIsNotTheSame() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message:
            'Les champs du mot de passe et de confirmation ne correspondent pas!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
