import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/main.dart';
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
import 'IndexAcceuilMedecin.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';


class MedecinDetails extends StatefulWidget {

  @override
  _MedecinDetailsState createState() => _MedecinDetailsState();
  final Utilisateur user;

  MedecinDetails({required this.user});
}

class _MedecinDetailsState extends State<MedecinDetails> {
  String baseUrl = UrlBase().baseUrl;

  bool _isPageActive = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _isPageActive = false;
    super.dispose();

    print('--- DESTRUCTION PAGE ---');
  }

  String generateUniqueImageName() {
    // Générer un jeton UUID (Universally Unique Identifier)
    var uuid = const Uuid();

    return uuid
        .v4()
        .substring(0, 6); // Utilisez les 6 premiers caractères du UUID
  }

  TextEditingController path = TextEditingController();
  StreamController<bool> _permissionStatusController = StreamController<bool>();

  Stream<bool> get permissionStatusStream => _permissionStatusController.stream;

  Future<bool> _requestGalleryPermission() async {
    print("Autorisation");

    PermissionStatus status = await Permission.storage.request();
    bool isGranted = status.isGranted;

    // Ajouter l'état actuel à la diffusion
    _permissionStatusController.add(isGranted);

    if (!isGranted) {
      // Si la permission est refusée, renvoyer false
      return false;
    }

    return true;
  }

  File? _profileImageFile;

  Future<List<int>> _resizeImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(Uint8List.fromList(bytes))!;

    // Define la taille maximale souhaitée pour la nouvelle image
    const int maxSize = 500;

    // Calculer les nouvelles dimensions tout en conservant le rapport hauteur/largeur
    int newWidth, newHeight;
    if (originalImage.width > originalImage.height) {
      newWidth = maxSize;
      newHeight =
          (originalImage.height * maxSize / originalImage.width).round();
    } else {
      newWidth = (originalImage.width * maxSize / originalImage.height).round();
      newHeight = maxSize;
    }

    // Redimensionner l'image
    final resizedImage =
        img.copyResize(originalImage, width: newWidth, height: newHeight);

    // Convertir l'image redimensionnée en bytes
    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);

    return resizedBytes;
  }

  Future<void> _pickImage(String imageName) async {
    bool isGranted = await _requestGalleryPermission();
    try {
      if (isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          AjouterImage(pickedFile, imageName);
          print('NOT NULL');

          //AjouterImage(_profileImageFile!);
        } else {
          print('Il y a une erreur');
        }
      } else {
        AutorisationParametre();
      }
    } catch (e) {
      print('CATCH : $e');
    }
  }

  File? _selectedImage;

  void AutorisationParametre() {
    // L'utilisateur a refusé la permission, afficher un message d'information
    // pour expliquer pourquoi la permission est nécessaire
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Autorisation requise'),
        content: const Text(
            'Cette application nécessite l\'autorisation d\'accéder à votre galerie pour choisir des images.'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Paramètres'),
            onPressed: () {
              // Ouvrir les paramètres de l'application pour permettre à
              // l'utilisateur d'activer la permission manuellement
              openAppSettings();
              Navigator.pop(context);
              permissionStatusStream.listen((bool isGranted) {
                if (isGranted) {
                  // L'utilisateur a autorisé l'accès à la galerie après être revenu des paramètres
                  // Mettez à jour votre interface utilisateur ou effectuez d'autres actions nécessaires
                } else {
                  // L'utilisateur n'a toujours pas autorisé l'accès à la galerie
                }
              });
            },
          ),
        ],
      ),
    );
  }

  late AuthProvider authProvider;
  late String token;

  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController categorieController = TextEditingController();

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

  bool EditEmail = false;
  bool EditPhone = false;

  File? profilImage;

  late Utilisateur utilisateur;

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
    categorieController.text = (utilisateur.category != null)
        ? categorieSet(utilisateur.category!)
        : "";
  }

  Future<Utilisateur> getUser(String id) async {
    final url = Uri.parse("${baseUrl}api/users/${extractLastNumber(id)}");

    print('URL USER: $url');

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print(' --- ST CODE: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        Utilisateur user = Utilisateur.fromJson(jsonData);

        print('UTILISATEUR: ${user.lastName}');

        return user;
      } else {
        // Gestion des erreurs HTTP
        if (response.statusCode == 401) {
          print('DETAILS ADMIN GET USER');
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        throw Exception('ANOTHER ERROR');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw Exception('-- Failed to load data. Error: $e');
    }
  }

  bool dataLoaded = false;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print('DID ZAO');
    authProvider = Provider.of<AuthProvider>(context);
    token = authProvider.token;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      utilisateur = await getUser(widget.user.id);
      if (mounted) {
        setState(() {
          profilImage = (utilisateur.imageName != null)
              ? File(utilisateur.imageName!)
              : null;
          nomController.text = utilisateur.firstName;
          prenomController.text = utilisateur.lastName;
          phoneController.text = utilisateur.phone;
          emailController.text = utilisateur.email;
          categorieController.text = (utilisateur.category != null)
              ? categorieSet(utilisateur.category!)
              : "";

          dataLoaded = true;
        });
      }
    });
  }

  String categorieSet(String uri) {
    if (extractLastNumber(uri) == '1') {
      return 'Bébé';
    } else if (extractLastNumber(uri) == '2') {
      return 'Enfant';
    } else if (extractLastNumber(uri) == '3') {
      return 'Femme';
    } else {
      return 'Homme';
    }
  }

  FocusNode nodeEmail = FocusNode();
  FocusNode nodePhone = FocusNode();

  void AjouterImage(XFile xfProfilImage, String imageName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          title: const Text(
            'Confirmation',
            style: TextStyle(letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 20),
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width - 40,
            height: MediaQuery.of(context).size.height / 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 10, left: 20, right: 20, bottom: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60)),
                      width: 120,
                      height: 120,
                      child: ((File(xfProfilImage.path) != null) &&
                              (File(xfProfilImage.path)!.existsSync()))
                          ? Image.file(
                              File(xfProfilImage.path)!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.account_circle,
                            ),
                    ),
                  ),
                ),
                const Expanded(
                    child: Text(
                  'Voulez-vous vraiment enregistrer cette image pour votre profil?',
                  textAlign: TextAlign.center,
                  style: TextStyle(letterSpacing: 2),
                ))
              ],
            ),
          ),
          scrollable: true,
          actions: [
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: Colors.redAccent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Confirmer',
                style: TextStyle(
                    color: Colors.green,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                final appDocumentsDirectory =
                    await getApplicationDocumentsDirectory();
                final fileName = '$imageName.jpg';
                final localCopyFile =
                    File('${appDocumentsDirectory.path}/$fileName');

                await localCopyFile
                    .writeAsBytes(await _resizeImage(xfProfilImage.path));

                print('Local copy file path: ${localCopyFile.path}');
                Utilisateur userInterm = Utilisateur(
                    id: utilisateur.id,
                    lastName: utilisateur.lastName,
                    firstName: utilisateur.firstName,
                    userType: utilisateur.userType,
                    phone: utilisateur.phone,
                    password: utilisateur.password,
                    email: utilisateur.email,
                    imageName: localCopyFile.path,
                    category: utilisateur.category,
                    address: utilisateur.address,
                    roles: utilisateur.roles,
                    createdAt: utilisateur.createdAt,
                    city: utilisateur.city);

                UserUpdate(userInterm);

                if (mounted) {
                  setState(() {
                    _profileImageFile = localCopyFile;
                    path.text = _profileImageFile!.path;
                    profilImage = File(path.text);
                    print('IMAGE PATH :${path.text}');
                  });
                }
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
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

  Future<void> UserUpdate(Utilisateur utilisateur) async {
    final url =
        Uri.parse("${baseUrl}api/users/${extractLastNumber(utilisateur.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {'Content-Type': 'application/merge-patch+json'};

    print('URL: $url');

    try {
      String jsonUser = jsonEncode(utilisateur.toJson());
      print('Request Body: $jsonUser');
      final response = await http.patch(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          error('Erreur de modification');
        } else {
          ModificationUtilisateur();
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        // Gestion des erreurs HTTP
        error('Il y a une erreur. HTTP Status Code: ${response.statusCode}');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
      throw Exception('-- CATCH Failed to add user. Error: $e');
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
          body: (dataLoaded)
              ? ListView(
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
                                      builder: (context) =>
                                          IndexAcceuilMedecin()));
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
                          top: 30, right: 15, left: 15, bottom: 20),
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
                                          borderRadius:
                                              BorderRadius.circular(60),
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
                                                  Positioned(
                                                    bottom: 15,
                                                    right: 10,
                                                    child: IconButton(
                                                      onPressed: () {
                                                        String imageName =
                                                            generateUniqueImageName()
                                                                .trim();
                                                        print(
                                                            'IMAGE NAME: $imageName');

                                                        _pickImage(imageName);
                                                      },
                                                      icon: const Icon(
                                                        Icons.add_a_photo,
                                                        size: 30,
                                                        color: Color.fromARGB(
                                                            230, 20, 20, 90),
                                                        shadows: [
                                                          Shadow(
                                                              color:
                                                                  Colors.white,
                                                              blurRadius: 6)
                                                        ],
                                                      ),
                                                    ),
                                                  )
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
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('Nom:'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 45),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.8,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
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
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('Prenom:'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 26),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.8,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
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
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('Email:'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width /
                                        1.89,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        ),
                                      ),
                                      controller: emailController,
                                      readOnly: EditEmail ? false : true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        EditEmail = !EditEmail;
                                        EditPhone = false;
                                      });
                                      if (EditEmail == true) {
                                        nodeEmail.requestFocus();
                                      }
                                    },
                                    icon: const Icon(Icons.edit))
                              ],
                            ),
                            if (EditEmail) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 160, right: 10),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color.fromARGB(
                                            1000, 60, 70, 120)),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Définissez le rayon de la bordure ici
                                      ),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                        const Size(100.0, 30.0)),
                                  ),
                                  onPressed: () {
                                    String email = emailController.text;
                                    if (email.isEmpty) {
                                      ModificationError(
                                          'Veuillez saisir votre email');
                                    } else {
                                      String? mail = _validateEmail(email);
                                      if (mail == null) {
                                        FocusScope.of(context).unfocus();
                                        Utilisateur userInterm = Utilisateur(
                                            id: utilisateur.id,
                                            lastName: utilisateur.lastName,
                                            firstName: utilisateur.firstName,
                                            userType: utilisateur.userType,
                                            phone: utilisateur.phone,
                                            password: utilisateur.password,
                                            email: email,
                                            imageName: utilisateur.imageName,
                                            category: utilisateur.category,
                                            address: utilisateur.address,
                                            roles: utilisateur.roles,
                                            createdAt: utilisateur.createdAt,
                                            city: utilisateur.city);
                                        UserUpdate(userInterm);
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      } else {
                                        emailInvalide();
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Enregistrer',
                                    textScaleFactor: 1.2,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 253, 253, 253),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('Telephone:'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 7),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width /
                                        1.89,
                                    child: TextField(
                                      maxLength: 10,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        ),
                                      ),
                                      controller: phoneController,
                                      readOnly: EditPhone ? false : true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        EditPhone = !EditPhone;
                                        EditEmail = false;
                                        if (EditPhone == true) {
                                          nodePhone.requestFocus();
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.edit))
                              ],
                            ),
                            if (EditPhone) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 160, right: 10),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color.fromARGB(
                                            1000, 60, 70, 120)),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Définissez le rayon de la bordure ici
                                      ),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                        const Size(100.0, 30.0)),
                                  ),
                                  onPressed: () {
                                    String phone = phoneController.text;
                                    if (phone.length != 10) {
                                      ModificationError(
                                          'Veuillez inserer un numero valide');
                                    } else {
                                      FocusScope.of(context).unfocus();
                                      Utilisateur userInterm = Utilisateur(
                                          id: utilisateur.id,
                                          lastName: utilisateur.lastName,
                                          firstName: utilisateur.firstName,
                                          userType: utilisateur.userType,
                                          phone: phone,
                                          password: utilisateur.password,
                                          email: utilisateur.email,
                                          imageName: utilisateur.imageName,
                                          category: utilisateur.category,
                                          address: utilisateur.address,
                                          roles: utilisateur.roles,
                                          createdAt: utilisateur.createdAt,
                                          city: utilisateur.city);
                                      UserUpdate(userInterm);
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Enregistrer',
                                    textScaleFactor: 1.2,
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 253, 253, 253),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Padding(
                                padding: const EdgeInsets.only(
                                    top: 40, left: 30, bottom: 30),
                                child: GestureDetector(
                                  onTap: () {
                                    authProvider.logout();

                                    print(
                                        'TOKEN PRVIDED: ${authProvider.token}');
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MyApp(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.logout_outlined,
                                        color: Colors.redAccent,
                                        size: 25,
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Text(
                                        'Se deconnecter',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                )),
    );
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
