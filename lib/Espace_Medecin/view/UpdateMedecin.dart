import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/main.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:med_scheduler_front/Models/Centre.dart';
import 'ModificationPassword.dart';
import 'package:med_scheduler_front/Models/UtilisateurNewPassword.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Repository/MedecinRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:med_scheduler_front/Models/UtilisateurImage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';

class UpdateMedecin extends StatefulWidget {
  @override
  _UpdateMedecinState createState() => _UpdateMedecinState();
}

class _UpdateMedecinState extends State<UpdateMedecin> {
  final TextEditingController phoneNumberController = TextEditingController();

  String baseUrl = UrlBase().baseUrl;

  List<Centre> listCenter = [];

  Centre? center;

  Centre? centerTemporaire;

  Utilities? utilities;
  MedecinRepository? medecinRepository;
  BaseRepository? baseRepository;

  Utilisateur? user;

  void formatPhoneNumberText() {
    final unformattedText =
        phoneNumberController.text.replaceAll(RegExp(r'\D'), '');

    String formattedText = '';
    int index = 0;
    final groups = [2, 2, 3, 2];
    var cursorOffset = 0;

    for (final group in groups) {
      final endIndex = index + group;
      if (endIndex <= unformattedText.length) {
        formattedText += unformattedText.substring(index, endIndex);
        cursorOffset += group;
        if (endIndex < unformattedText.length) {
          formattedText += ' ';
          cursorOffset++;
        }
        index = endIndex;
      } else {
        formattedText += unformattedText.substring(index);
        cursorOffset += unformattedText.length - index;
        break;
      }
    }

    phoneNumberController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    phoneNumberController.addListener(formatPhoneNumberText);
    utilities = Utilities(context: context);
    baseRepository = BaseRepository(context: context, utilities: utilities!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      profilImage =
          (utilisateur.imageName != null) ? File(utilisateur.imageName!) : null;
      nomController.text = utilisateur.firstName;
      prenomController.text = utilisateur.lastName;
      phoneNumberController.text = utilisateur.phone.replaceFirst('+261', '');
      emailController.text = utilisateur.email;
      centreController.text =
          (utilisateur.center != null) ? utilisateur.center!.label : '';
      categorieController.text = (utilisateur.category != null)
          ? categorieSet(utilisateur.category!)
          : "";

      EditEmail = false;
      EditCenter = false;
      EditPhone = false;
      isLoading = false;
      dataLoaded = true;
    });

    getAll();
  }

  Widget buildDropdownButtonFormFieldCenter({
    required String label,
    required Centre? value,
    required FocusNode focusNode,
    required List<DropdownMenuItem<Centre>> items,
    required ValueChanged<Centre?> onChanged,
    required FormFieldValidator<Centre?> validator,
  }) {
    value = null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<Centre>(
        focusNode: focusNode,
        value: value,
        onChanged: onChanged,
        items: items,
        icon: Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: Colors.black.withOpacity(0.7),
        ),
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          labelStyle: TextStyle(
            color: focusNode.hasFocus
                ? Colors.redAccent
                : Colors.black.withOpacity(0.5),
          ),
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.4),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          labelText: label,
          hintText: 'Plus d\'options',
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    phoneNumberController.removeListener(formatPhoneNumberText);
    phoneNumberController.dispose();

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

  Future<File?> resizeImage(File file,
      {int width = 300, int height = 300}) async {
    try {
      // Lire le fichier image
      List<int> imageBytes = await file.readAsBytes();
      img.Image originalImage =
          img.decodeImage(Uint8List.fromList(imageBytes))!;

      // Redimensionner l'image
      img.Image resizedImage =
          img.copyResize(originalImage, width: width, height: height);

      // Créer un nouveau fichier avec l'image redimensionnée
      File resizedFile = File('${file.path}_resized.jpg');
      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));

      return resizedFile;
    } catch (e) {
      print('Erreur lors du redimensionnement de l\'image : $e');
      return null;
    }
  }

  Future<void> _cropImage(File? file) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file!.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 500,
      maxHeight: 500,
      cropStyle: CropStyle.circle,
      compressQuality: 100,
      aspectRatioPresets: [CropAspectRatioPreset.ratio3x2],
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
            showCropGrid: false,
            backgroundColor: Color.fromARGB(1000, 238, 239, 244),
            toolbarTitle: 'Recadrez votre profil',
            toolbarColor: Color.fromARGB(230, 20, 20, 90),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Rogner',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile != null) {
      // Faites quelque chose avec le fichier rogné (par exemple, l'envoyer au serveur)
      File? newFile = File(croppedFile.path);

      UserUpdateImage(newFile, utilisateur);
    }
  }

  Future<void> UserUpdateImage(File file, Utilisateur utilisateur) async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        "${baseUrl}api/image-profile/${utilities!.extractLastNumber(utilisateur.id)}");

    try {
      // Limiter la taille du fichier à, par exemple, 2 Mo (ajustez selon vos besoins)
      const maxSizeInBytes = 2 * 1024 * 1024; // 2 Mo
      if (await file.length() > maxSizeInBytes) {
        utilities!.error(
            'La taille du fichier est trop grande. Veuillez sélectionner un fichier plus petit.');
        return;
      } else {
        var request = http.MultipartRequest('POST', url);

        // Ajouter les en-têtes
        request.headers['Content-Type'] = 'multipart/form-data';
        request.headers['Authorization'] = 'Bearer $token';

        // Ajouter le fichier au champ de données multipartes
        var fileStream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile('image', fileStream, length,
            filename: file.path.split('/').last);
        request.files.add(multipartFile);

        var response = await request.send();

        // Lire la réponse
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });
          utilities!.ModificationUtilisateur();
          Map<String, dynamic> map = json.decode(responseBody);

          UtilisateurImage utilisateurImage = UtilisateurImage.fromJson(map);

          if (utilisateurImage.imageName != "") {
            setState(() {
              utilisateur = Utilisateur(
                  id: utilisateur.id,
                  lastName: utilisateur.lastName,
                  firstName: utilisateur.firstName,
                  userType: utilisateur.userType,
                  phone: utilisateur.phone,
                  password: utilisateur.password,
                  email: utilisateur.email,
                  imageName: utilisateurImage.imageName,
                  category: utilisateur.category,
                  address: utilisateur.address,
                  roles: utilisateur.roles,
                  city: utilisateur.city);
              authProviderUser.setUser(utilisateur);
            });
            Navigator.pop(context);
          } else {
            print('IMAGE USER NULL');
          }

          setState(() {});
          final Map<String, dynamic> jsonResponse = json.decode(responseBody);

          if (jsonResponse.containsKey('error')) {
            utilities!.error('Erreur de modification');
          } else {
            setState(() {
              isLoading = false;
            });
          }
        } else if (response.statusCode == 401) {
          setState(() {
            isLoading = false;
          });
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        } else {
          setState(() {
            isLoading = false;
          });
          // Gestion des erreurs HTTP
          utilities!.ErrorConnexion();
        }
      }
    } catch (e, exception) {
      setState(() {
        isLoading = false;
      });
      if (e is http.ClientException) {
        utilities!.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      } else {
        // Gérer d'autres exceptions
      }
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

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

  late AuthProviderUser authProviderUser;
  late AuthProvider authProvider;
  late String token;

  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController categorieController = TextEditingController();
  TextEditingController centreController = TextEditingController();

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
  bool EditCenter = false;

  File? profilImage;

  late Utilisateur utilisateur;

  void getAll() {
    baseRepository!.getAllCenter().then((value) => {
          setState(() {
            listCenter = value;
          })
        });
  }

  Future<void> UserUpdate(Utilisateur utilisateur) async {
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);

    setState(() {
      isLoading = true;
      dataLoaded = false;
    });

    final url = Uri.parse(
        "${baseUrl}api/users/${utilities!.extractLastNumber(utilisateur.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {'Content-Type': 'application/merge-patch+json'};

    try {
      String jsonUser = jsonEncode(utilisateur.toJson());

      final response = await http.patch(url, headers: headers, body: jsonUser);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('error')) {
          utilities!.error('Erreur de modification');
        } else {
          authProviderUser.setUser(utilisateur);
          utilities!.ModificationUtilisateur();

          setState(() {
            isLoading = false;
            dataLoaded = false;
          });
          Navigator.pop(context, true);

          //Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>IndexAcceuilMedecin()), (route) => false);

          didChangeDependencies();
        }
      } else {
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
        // Gestion des erreurs HTTP
        utilities!.error(
            'Il y a une erreur. HTTP Status Code: ${response.statusCode}');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, exception) {
      if (e is http.ClientException) {
        utilities!.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
      }
      throw Exception('-- CATCH Failed to add user. Error: $e');
    }
  }

  bool dataLoaded = false;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    authProviderUser = Provider.of<AuthProviderUser>(context, listen: false);
    utilisateur = ModalRoute.of(context)?.settings.arguments as Utilisateur;
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
  FocusNode nodeCenter = FocusNode();

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;

      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw const FormatException("Aucun nombre trouvé dans la chaîne.");
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
          body: (!isLoading && dataLoaded)
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
                              setState(() {
                                isLoading = false;
                                dataLoaded = true;
                              });
                              Navigator.of(context).pop();
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
                          right: 15, left: 15, bottom: 20),
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
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(60),
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  '$baseUrl${utilisateur.imageName}',
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(
                                                color: Colors.redAccent,
                                              ), // Affiche un indicateur de chargement en attendant l'image
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Stack(
                                                children: [
                                                  Icon(
                                                    Icons.account_circle,
                                                    size: 120,
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                  ),
                                                ],
                                              ), // Affiche une icône d'erreur si le chargement échoue
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                            bottom: -5,
                                            right: -10,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                ),
                                                child: IconButton(
                                                  onPressed: () async {
                                                    bool isGranted =
                                                        await _requestGalleryPermission();
                                                    if (isGranted) {
                                                      String imageName =
                                                          generateUniqueImageName()
                                                              .trim();

                                                      FilePickerResult? result =
                                                          await FilePicker
                                                              .platform
                                                              .pickFiles(
                                                        type: FileType.image,
                                                        allowMultiple:
                                                            false, // Extensions d'images autorisées
                                                      );

                                                      if (result != null &&
                                                          result.files
                                                              .isNotEmpty) {
                                                        String originalPath =
                                                            result.files.first
                                                                .path!;
                                                        File originalFile =
                                                            File(originalPath);

                                                        _cropImage(
                                                            originalFile);

                                                        print(
                                                            'Chemin du fichier original : $originalPath');
                                                      } else {
                                                        print(
                                                            'Aucun fichier sélectionné');
                                                      }
                                                    } else {
                                                      print('NOT GRANTED');
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.add_a_photo,
                                                    size: 30,
                                                    color: Color.fromARGB(
                                                        230, 20, 20, 90),
                                                    shadows: [
                                                      Shadow(
                                                          color: Colors.white,
                                                          blurRadius: 6)
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ))
                                      ],
                                    )),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Text('Nom:',
                                      style: TextStyle(
                                        fontSize: 14,
                                      )),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.only(left: 15),
                                  width:
                                      MediaQuery.of(context).size.width / 2.3,
                                  child: TextField(
                                    style: TextStyle(fontSize: 15),
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
                                const SizedBox(
                                  width: 75,
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Text('Prenom:',
                                      style: TextStyle(
                                        fontSize: 14,
                                      )),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.only(left: 15),
                                  width:
                                      MediaQuery.of(context).size.width / 2.3,
                                  child: TextField(
                                    style: TextStyle(fontSize: 15),
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
                                const SizedBox(
                                  width: 75,
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Text('Email:',
                                      style: TextStyle(
                                        fontSize: 14,
                                      )),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.only(left: 15),
                                  width:
                                      MediaQuery.of(context).size.width / 2.3,
                                  child: TextField(
                                    style: TextStyle(fontSize: 15),
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
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        EditEmail = !EditEmail;
                                        EditPhone = false;
                                      });
                                      if (EditEmail == true) {
                                        nodeEmail.requestFocus();
                                        EditPhone = false;
                                        EditCenter = false;
                                      }
                                    },
                                    icon: const Icon(Icons.edit)),
                                const SizedBox(
                                  width: 25,
                                )
                              ],
                            ),
                            if (EditEmail) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 110, right: 30),
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
                                            center: utilisateur.center,
                                            speciality: utilisateur.speciality,
                                            imageName: (utilisateur.imageName !=
                                                    null)
                                                ? utilities!.extraireNomFichier(
                                                    utilisateur.imageName!)
                                                : null,
                                            category: utilisateur.category,
                                            address: utilisateur.address,
                                            roles: utilisateur.roles,
                                            createdAt: utilisateur.createdAt,
                                            city: utilisateur.city);
                                        UserUpdate(userInterm);
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
                                Container(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Text('Telephone:',
                                      style: TextStyle(
                                        fontSize: 14,
                                      )),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.only(left: 15),
                                  width:
                                      MediaQuery.of(context).size.width / 2.3,
                                  child: TextField(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(9)
                                    ],
                                    style: TextStyle(fontSize: 15),
                                    maxLength: 12,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '+261 ',
                                      prefixStyle: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black.withOpacity(0.7)),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(230, 20, 20, 90),
                                        ),
                                      ),
                                    ),
                                    controller: phoneNumberController,
                                    readOnly: EditPhone ? false : true,
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        EditPhone = !EditPhone;
                                        EditEmail = false;
                                        if (EditPhone == true) {
                                          nodePhone.requestFocus();
                                          EditCenter = false;
                                          EditEmail = false;
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.edit)),
                                const SizedBox(
                                  width: 25,
                                )
                              ],
                            ),
                            if (EditPhone) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 110, right: 30),
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
                                    FocusScope.of(context).unfocus();

                                    String phone = phoneNumberController.text
                                        .replaceFirst('+261', '');
                                    if (phone.replaceAll(' ', '').length != 9) {
                                      ModificationError(
                                          'Veuillez inserer un numero valide');
                                    } else {
                                      if (phone.startsWith('32') ||
                                          phone.startsWith('33') ||
                                          phone.startsWith('34') ||
                                          phone.startsWith('38') ||
                                          phone.startsWith('37')) {
                                        String number =
                                            "+261${phone.replaceAll(RegExp(r'\s+'), '')}";
                                        Utilisateur userInterm = Utilisateur(
                                            id: utilisateur.id,
                                            lastName: utilisateur.lastName,
                                            firstName: utilisateur.firstName,
                                            userType: utilisateur.userType,
                                            phone: number,
                                            center: utilisateur.center,
                                            speciality: utilisateur.speciality,
                                            password: utilisateur.password,
                                            email: utilisateur.email,
                                            imageName: (utilisateur.imageName !=
                                                    null)
                                                ? utilities!.extraireNomFichier(
                                                    utilisateur.imageName!)
                                                : null,
                                            category: utilisateur.category,
                                            address: utilisateur.address,
                                            roles: utilisateur.roles,
                                            createdAt: utilisateur.createdAt,
                                            city: utilisateur.city);
                                        UserUpdate(userInterm);
                                      } else {
                                        ModificationError(
                                            'Veuillez inserer un numero valide');
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
                            if (!EditCenter) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Text('Centre:',
                                        style: TextStyle(
                                          fontSize: 14,
                                        )),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.only(left: 15),
                                    width:
                                        MediaQuery.of(context).size.width / 2.3,
                                    child: TextField(
                                      style: TextStyle(fontSize: 15),
                                      maxLength: 10,
                                      keyboardType: TextInputType.name,
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                Color.fromARGB(230, 20, 20, 90),
                                          ),
                                        ),
                                      ),
                                      controller: centreController,
                                      readOnly: true,
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          EditCenter = !EditCenter;
                                          EditEmail = false;
                                          EditPhone = false;
                                        });
                                      },
                                      icon: const Icon(Icons.edit)),
                                  SizedBox(
                                    width: 25,
                                  )
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Text('Centre:',
                                        style: TextStyle(
                                          fontSize: 14,
                                        )),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.only(left: 15),
                                    width: MediaQuery.of(context).size.width /
                                        2.19,
                                    child: buildDropdownButtonFormFieldCenter(
                                      label: 'Centre',
                                      value: centerTemporaire ?? center,
                                      focusNode: nodeCenter,
                                      items: listCenter.map((e) {
                                        return DropdownMenuItem<Centre>(
                                          value: e,
                                          child: Text('${e.label}'),
                                        );
                                      }).toList(),
                                      onChanged: (Centre? newval) {
                                        setState(() {
                                          EditCenter = true;
                                          centerTemporaire = newval;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Veuillez sélectionner un centre';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          EditCenter = !EditCenter;
                                          EditEmail = false;
                                          EditPhone = false;
                                        });
                                      },
                                      icon: const Icon(Icons.edit)),
                                  const SizedBox(
                                    width: 25,
                                  )
                                ],
                              ),
                            ],
                            if (EditCenter) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 110, right: 30),
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
                                        const Size(100.0, 40.0)),
                                  ),
                                  onPressed: () {
                                    String phone = phoneController.text;
                                    if (centerTemporaire == null) {
                                      ModificationError(
                                          'Veuillez inserer votre centre');
                                    } else {
                                      FocusScope.of(context).unfocus();
                                      Utilisateur userInterm = Utilisateur(
                                          id: utilisateur.id,
                                          lastName: utilisateur.lastName,
                                          firstName: utilisateur.firstName,
                                          userType: utilisateur.userType,
                                          phone: utilisateur.phone,
                                          center: centerTemporaire!,
                                          speciality: utilisateur.speciality,
                                          password: utilisateur.password,
                                          email: utilisateur.email,
                                          imageName: (utilisateur.imageName !=
                                                  null)
                                              ? utilities!.extraireNomFichier(
                                                  utilisateur.imageName!)
                                              : null,
                                          category: utilisateur.category,
                                          address: utilisateur.address,
                                          roles: utilisateur.roles,
                                          createdAt: utilisateur.createdAt,
                                          city: utilisateur.city);
                                      UserUpdate(userInterm);
                                      setState(() {
                                        centreController.text =
                                            userInterm.center!.label;
                                        center = null;
                                        EditCenter = false;
                                        didChangeDependencies();
                                      });
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
                                  top: 20, left: 10, right: 10, bottom: 70),
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
                                      const Size(100.0, 40.0)),
                                ),
                                onPressed: () {
                                  UtilisateurNewPassword
                                      utilisateurNewPassword =
                                      UtilisateurNewPassword(
                                          id: int.parse(extractLastNumber(
                                              utilisateur.id)),
                                          lastName: utilisateur.lastName,
                                          firstName: utilisateur.firstName,
                                          userType: utilisateur.userType,
                                          phone: utilisateur.phone,
                                          password: utilisateur.password,
                                          email: utilisateur.email,
                                          imageName: (utilisateur.imageName !=
                                                  null)
                                              ? utilities!.extraireNomFichier(
                                                  utilisateur.imageName!)
                                              : null,
                                          category: utilisateur.category,
                                          address: utilisateur.address,
                                          roles: utilisateur.roles,
                                          city: utilisateur.city);

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ModificationPassword(),
                                          settings: RouteSettings(
                                              arguments:
                                                  utilisateurNewPassword)));
                                },
                                child: const Text(
                                  'Changer mot de passe',
                                  textScaleFactor: 1.2,
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 253, 253, 253),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              : loadingWidget()),
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
