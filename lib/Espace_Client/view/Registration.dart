import 'package:flutter/material.dart';
import 'Login.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:med_scheduler_front/Categorie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:med_scheduler_front/main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:uuid/uuid.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';

class Registration extends StatefulWidget {

  @override
  _RegistrationState createState() => _RegistrationState();

}

class _RegistrationState extends State<Registration> {

  String baseUrl = UrlBase().baseUrl;

  bool isLoading = false;


  Utilities? utilities;


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
    newHeight = (originalImage.height * maxSize / originalImage.width).round();
    } else {
    newWidth = (originalImage.width * maxSize / originalImage.height).round();
    newHeight = maxSize;
    }

    // Redimensionner l'image
    final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);

    // Convertir l'image redimensionnée en bytes
    final resizedBytes = img.encodeJpg(resizedImage, quality: 85);

    return resizedBytes;
  }


  Future<void> _pickImage(String imageName) async {
    bool isGranted = await _requestGalleryPermission();
    try{
      if (isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          print('NOT NULL');
          final appDocumentsDirectory = await getApplicationDocumentsDirectory();
          final fileName = '$imageName.jpg';
          final localCopyFile = File('${appDocumentsDirectory.path}/$fileName');

          await localCopyFile.writeAsBytes(await _resizeImage(pickedFile.path));

          print('Local copy file path: ${localCopyFile.path}');


          setState(() {
            _profileImageFile = localCopyFile;
            path.text = _profileImageFile!.path;
            print('IMAGE PATH :${path.text}');
          });
        }else{
          print('Il y a une erreur');
        }
      }else{
        AutorisationParametre();
      }
    }catch (e){
      print('CATCH : $e');
    }

  }






  File? _selectedImage;


  void AutorisationParametre(){

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



  List<Categorie> listCategorie = [];


  Future<List<Categorie>> getAllCategorie() async {
    final url = Uri.parse("${baseUrl}api/categories?page=1");

    try {
      final response = await http.get(url);

      print('STATUS CODE: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        print('MAHAZO DONNEE');
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;
        print('DATA GET: ${datas.map((e) => Categorie.fromJson(e)).toList().length}');
        return datas.map((e) => Categorie.fromJson(e)).toList();
      } else {
        // Gestion des erreurs HTTP
        throw Exception('-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error: $e \nStack trace: $stackTrace');
      throw Exception('-- Failed to load data. Error: $e');
    }
  }

  //Fonction pour stocker les categories trouvés
  void getAll(){
    getAllCategorie().then((value) => {


      setState((){
          listCategorie = value;
        })

    });
    print('LIST CAT:${listCategorie.length}');
    for(Categorie cat in listCategorie){
      print('CATEGORIE: ${cat.id} , ${cat.type} , ${cat.title} , ${cat.description}  ');
    }
  }

  @override
  void initState() {
    super.initState();
    utilities = Utilities(context: context);


    getAll();

    print('CATEGORIE: ${categorie} ');
  }




    void success() {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            title: Text('Succès'),
            content: Text('Utilisateur créé avec succès.',textScaleFactor: 1.3,style: TextStyle(color: Colors.teal,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
          );
        },
      );

      // Fermer la boîte de dialogue après 4 secondes
      Future.delayed(const Duration(seconds: 4), () {
        Navigator.of(context).pop();
      });
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
            content: Text('$description.',textScaleFactor: 1.5,style: const TextStyle(color: Colors.red),textAlign: TextAlign.center,),
          );
        },
      );

      // Fermer la boîte de dialogue après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
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
      print('Request Body: $jsonUser');
      final response = await http.post(url,headers: headers,body: jsonUser);
      print(response.statusCode);



      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          setState(() {
            isLoading = false;
          });

          error('Utilisateur déja existant');
        } else {
          setState(() {
            isLoading = false;
          });

          CreationUtilisateur();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
        }



        } else {
        setState(() {
          isLoading = false;
        });
        // Gestion des erreurs HTTP
        error('Il y a une erreur. HTTP Status Code: ${response.statusCode}');
        throw Exception('-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }

    } catch (e,exception) {
      // Gestion des erreurs autres que HTTP
      error('Erreur de connexion ou voir ceci: $e');
      print('EXCPEPT: $exception');
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



  final _emailValidator = RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");



  FocusNode _focusNodenom = FocusNode();
  FocusNode _focusNodeprenom = FocusNode();
  FocusNode _focusNodemail = FocusNode();
  FocusNode _focusNodephone = FocusNode();
  FocusNode _focusNodecategorie = FocusNode();
  FocusNode _focusNodepass = FocusNode();
  FocusNode _focusNodeimage = FocusNode();
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

    return uuid.v4().substring(0, 6); // Utilisez les 6 premiers caractères du UUID
  }



  final GlobalKey<ScaffoldState> scafkey = GlobalKey<ScaffoldState>();


  String? cat;





  Widget scafWithLoading(){

    return Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        key: scafkey,

        body: Stack(
          children: [
            (listCategorie.isNotEmpty)?ListView(

              children: [



                Padding(padding: const EdgeInsets.only(top: 10,left: 10),child:  GestureDetector(

                  onTap: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const MyApp()));
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.keyboard_arrow_left,size: 40,),


                      const Text('Retour'),

                      Padding(
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width-170),child: Center(child: Container(
                        width: 60,
                        height: 60,
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          child: Image.asset("assets/images/logo2.png",fit: BoxFit.cover,) ,
                        ),
                      ),
                      ),
                      ),


                    ],

                  ),
                ),
                ),


                const Center(

                  child: Text('Commençons,',textScaler: TextScaler.linear(2.5),style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.5),) ,
                ),



                const Padding(padding: EdgeInsets.only(top:40,bottom: 20,left: 40,right: 40),child: Center(

                  child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Text('Accédez à notre application de planification de rendez-vous médical avec notre formulaire d’inscription',textAlign: TextAlign.center,style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.3),) ,
                  ),

                ),
                ),


                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35),
                  child: TextFormField(
                    onTap: (){

                      String imageName = generateUniqueImageName().trim();
                      print('IMAGE NAME: $imageName');

                      _pickImage(imageName);



                    },
                    readOnly: true,
                    focusNode: _focusNodeimage,
                    controller: path,
                    keyboardType: TextInputType.name,


                    style:const TextStyle(color: Colors.black),

                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Profil',
                      hintText: 'Inserer votre photo',
                      labelStyle: TextStyle(color: _focusNodeimage.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.photo, color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),


                Padding(
                  padding:const EdgeInsets.only(top: 30,left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodenom,
                    controller: nomController,
                    keyboardType: TextInputType.name
                    ,


                    style:const TextStyle(color: Colors.black),

                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Nom',
                      hintText: 'Entrer votre nom',
                      labelStyle: TextStyle(color: _focusNodenom.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.person_2_rounded, color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),

                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodeprenom,
                    controller: prenomController,
                    keyboardType: TextInputType.name
                    ,


                    style:const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Prenom',
                      hintText: 'Entrer votre prenom',
                      labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.person_2_rounded, color:Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),


                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodemail,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress
                    ,

                    style:const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'E-mail',
                      hintText: 'exemple@domaine.com',
                      labelStyle: TextStyle(color: _focusNodemail.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.mail,  color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),



                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodephone,
                    controller: phoneController,
                    keyboardType: TextInputType.number
                    ,

                    style:const TextStyle(color: Colors.black),
                    maxLength: 10,
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),

                      labelText: 'Telephone',
                      hintText: 'ex: 0380020020',
                      suffixIcon: Padding(padding:const EdgeInsets.only(right: 10),child: SvgPicture.asset('assets/images/madagascar.svg',fit: BoxFit.fitWidth,width: 100,height: 20,),),
                      labelStyle: TextStyle(color: _focusNodephone.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.phone,  color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),


                Padding(
                  padding:const EdgeInsets.only( bottom: 30.0,right: 35,left: 35),
                  child: DropdownButtonFormField<Categorie>(
                    focusNode: _focusNodecategorie,
                    icon:const Icon(Icons.arrow_drop_down_circle_outlined,color: Colors.black,),
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
                    style:const TextStyle(color: Colors.black),

                    decoration: InputDecoration(
                        enabledBorder:const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)
                        ),
                        prefixIcon:const Icon(Icons.people, color: Color.fromARGB(1000, 60, 70, 120),),

                        labelStyle: TextStyle(color: _focusNodecategorie.hasFocus?Colors.redAccent:Colors.black),
                        hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                        labelText: 'Categorie Patient',
                        hintText: '-- Plus d\'options --',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),


                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodeaddresse,
                    controller: addresseController,
                    keyboardType: TextInputType.name
                    ,


                    style:const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Addresse',
                      hintText: 'Entrer votre addresse',
                      labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.location_on, color:Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),


                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodeville,
                    controller: villeController,
                    keyboardType: TextInputType.name
                    ,


                    style:const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Ville',
                      hintText: 'Entrer votre ville',
                      labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon:const Icon(Icons.location_city, color:Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),

                Padding(
                  padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
                  child: TextFormField(
                    focusNode: _focusNodepass,
                    controller: passwordController,
                    obscureText: obscurepwd?true:false,

                    style:const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder:const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Mot de passe',
                      hintText: 'Entrer votre mot de passe',
                      labelStyle: TextStyle(color: _focusNodepass.hasFocus?Colors.redAccent:Colors.black),
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
                      prefixIcon: const Icon(Icons.password,  color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.only(left: 35,right: 35, bottom: 20),
                  child: TextFormField(
                    focusNode: _focusNodeconfpass,
                    controller: confirmPasswordController,
                    obscureText: obscureconfpwd?true:false,
                    keyboardType:TextInputType.emailAddress,

                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)
                      ),
                      hintStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                      labelText: 'Confirmer Mot de passe',
                      hintText: 'Confirmer votre mot de passe',
                      labelStyle: TextStyle(color: _focusNodeconfpass.hasFocus?Colors.redAccent:Colors.black),
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
                      prefixIcon:const Icon(Icons.password,  color: Color.fromARGB(1000, 60, 70, 120)),

                    ),
                  ),
                ),







                Padding(padding:const EdgeInsets.only(left: 35,right: 35,bottom: 30),child: TextButton(
                  child:const Text('Vous avez déjà un compte? S\'authentifier ici',textAlign: TextAlign.center,style: TextStyle(color:Colors.redAccent),),

                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Login()));
                  },
                ),
                ),

                Padding(
                    padding:const EdgeInsets.only(top: 10.0,left: 50,right: 50),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(1000, 60, 70, 120)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // Définissez le rayon de la bordure ici
                          ),

                        ),
                        minimumSize: MaterialStateProperty.all(const Size(50.0, 60.0)),
                      ),
                      onPressed: () {

                        FocusScope.of(context).unfocus();

                        if(passwordController.text==confirmPasswordController.text){



                          if(nomController.text!="" && prenomController.text!="" && emailController.text!="" && phoneController.text!="" && passwordController.text!="" && confirmPasswordController.text!="" && categorie!=null && addresseController.text!=""&& villeController.text!=""){
                            String? mail = _validateEmail(emailController.text);

                            if(mail==null){

                              Utilisateur user = Utilisateur(id: '', lastName: nomController.text.trim(),roles: ['ROLE_USER'], firstName: prenomController.text.trim(),password: passwordController.text.trim(), userType: 'Patient', phone: phoneController.text.trim(), email: emailController.text.trim(), imageName: path.text.trim(), category: utilities!.extractApiPath(categorie!.id), address: addresseController.text.trim(), createdAt: DateTime.now(), city: villeController.text.trim());
                              addUser(user);
                            }else{
                              //print('MAIL NON VALIDE');
                              emailInvalide();
                            }
                          }else{
                            ChampsIncomplets();
                          }
                        }else{
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
                    )
                ),

                const SizedBox(height: 50,)


              ],
            ):const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.redAccent,
                ),
                SizedBox(height: 30,),
                Text('Chargement des données..\n Assurez-vous d\'avoir une connexion internet',textAlign: TextAlign.center,)
              ],
            )
            ),

            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black.withOpacity(0.2),
            ),
            loadingWidget()
          ],
        )
    );
  }




  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false,child:isLoading?scafWithLoading():Scaffold(
        backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
        key: scafkey,

        body: (listCategorie.isNotEmpty)?ListView(

          children: [



            Padding(padding: const EdgeInsets.only(top: 10,left: 10),child:  GestureDetector(

              onTap: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const MyApp()));
              },
              child: Row(
                children: [
                  const Icon(Icons.keyboard_arrow_left,size: 40,),


                  const Text('Retour'),

                  Padding(
                    padding: EdgeInsets.only(left: MediaQuery.of(context).size.width-170),child: Center(child: Container(
                    width: 60,
                    height: 60,
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Image.asset("assets/images/logo2.png",fit: BoxFit.cover,) ,
                    ),
                  ),
                  ),
                  ),


                ],

              ),
            ),
            ),


            const Center(

              child: Text('Commençons,',textScaler: TextScaler.linear(2.5),style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.5),) ,
            ),



            const Padding(padding: EdgeInsets.only(top:40,bottom: 20,left: 40,right: 40),child: Center(

              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: Text('Accédez à notre application de planification de rendez-vous médical avec notre formulaire d’inscription',textAlign: TextAlign.center,style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.3),) ,
              ),

            ),
            ),


            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35),
              child: TextFormField(
                onTap: (){

                  String imageName = generateUniqueImageName().trim();
                  print('IMAGE NAME: $imageName');

                  _pickImage(imageName);



                },
                readOnly: true,
                focusNode: _focusNodeimage,
                controller: path,
                keyboardType: TextInputType.name,


                style:const TextStyle(color: Colors.black),

                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Profil',
                  hintText: 'Inserer votre photo',
                  labelStyle: TextStyle(color: _focusNodeimage.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.photo, color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),


            Padding(
              padding:const EdgeInsets.only(top: 30,left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodenom,
                controller: nomController,
                keyboardType: TextInputType.name
                ,


                style:const TextStyle(color: Colors.black),

                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Nom',
                  hintText: 'Entrer votre nom',
                  labelStyle: TextStyle(color: _focusNodenom.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.person_2_rounded, color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),

            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodeprenom,
                controller: prenomController,
                keyboardType: TextInputType.name
                ,


                style:const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Prenom',
                  hintText: 'Entrer votre prenom',
                  labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.person_2_rounded, color:Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),


            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodemail,
                controller: emailController,
                keyboardType: TextInputType.emailAddress
                ,

                style:const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'E-mail',
                  hintText: 'exemple@domaine.com',
                  labelStyle: TextStyle(color: _focusNodemail.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.mail,  color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),



            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodephone,
                controller: phoneController,
                keyboardType: TextInputType.number
                ,

                style:const TextStyle(color: Colors.black),
                maxLength: 10,
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),

                  labelText: 'Telephone',
                  hintText: 'ex: 0380020020',
                  suffixIcon: Padding(padding:const EdgeInsets.only(right: 10),child: SvgPicture.asset('assets/images/madagascar.svg',fit: BoxFit.fitWidth,width: 100,height: 20,),),
                  labelStyle: TextStyle(color: _focusNodephone.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),

                  prefixIcon:const Icon(Icons.phone,  color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),


            Padding(
              padding:const EdgeInsets.only( bottom: 30.0,right: 35,left: 35),
              child: DropdownButtonFormField<Categorie>(
                focusNode: _focusNodecategorie,
                icon:const Icon(Icons.arrow_drop_down_circle_outlined,color: Colors.black,),
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
                style:const TextStyle(color: Colors.black),

                decoration: InputDecoration(
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 20, 20, 100))),
                    enabledBorder:const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)
                    ),
                    prefixIcon:const Icon(Icons.people, color: Color.fromARGB(1000, 60, 70, 120),),

                    labelStyle: TextStyle(color: _focusNodecategorie.hasFocus?Colors.redAccent:Colors.black),
                    hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                    labelText: 'Categorie Patient',
                    hintText: '-- Plus d\'options --',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
            ),


            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodeaddresse,
                controller: addresseController,
                keyboardType: TextInputType.name
                ,


                style:const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Addresse',
                  hintText: 'Entrer votre addresse',
                  labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.location_on, color:Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),


            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodeville,
                controller: villeController,
                keyboardType: TextInputType.name
                ,


                style:const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Ville',
                  hintText: 'Entrer votre ville',
                  labelStyle: TextStyle(color: _focusNodeprenom.hasFocus?Colors.redAccent:Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:const Icon(Icons.location_city, color:Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),

            Padding(
              padding:const EdgeInsets.only(left: 35,right: 35, bottom: 30),
              child: TextFormField(
                focusNode: _focusNodepass,
                controller: passwordController,
                obscureText: obscurepwd?true:false,

                style:const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder:const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Mot de passe',
                  hintText: 'Entrer votre mot de passe',
                  labelStyle: TextStyle(color: _focusNodepass.hasFocus?Colors.redAccent:Colors.black),
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
                  prefixIcon: const Icon(Icons.password,  color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),


            Padding(
              padding: const EdgeInsets.only(left: 35,right: 35, bottom: 20),
              child: TextFormField(
                focusNode: _focusNodeconfpass,
                controller: confirmPasswordController,
                obscureText: obscureconfpwd?true:false,
                keyboardType:TextInputType.emailAddress,

                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 20, 20, 100))),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),
                  hintStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),
                  labelText: 'Confirmer Mot de passe',
                  hintText: 'Confirmer votre mot de passe',
                  labelStyle: TextStyle(color: _focusNodeconfpass.hasFocus?Colors.redAccent:Colors.black),
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
                  prefixIcon:const Icon(Icons.password,  color: Color.fromARGB(1000, 60, 70, 120)),

                ),
              ),
            ),







            Padding(padding:const EdgeInsets.only(left: 35,right: 35,bottom: 30),child: TextButton(
              child:const Text('Vous avez déjà un compte? S\'authentifier ici',textAlign: TextAlign.center,style: TextStyle(color:Colors.redAccent),),

              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Login()));
              },
            ),
            ),

            Padding(
                padding:const EdgeInsets.only(top: 10.0,left: 50,right: 50),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color.fromARGB(1000, 60, 70, 120)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // Définissez le rayon de la bordure ici
                      ),

                    ),
                    minimumSize: MaterialStateProperty.all(const Size(50.0, 60.0)),
                  ),
                  onPressed: () {

                    FocusScope.of(context).unfocus();

                    if(passwordController.text==confirmPasswordController.text){



                      if(nomController.text!="" && prenomController.text!="" && emailController.text!="" && phoneController.text!="" && passwordController.text!="" && confirmPasswordController.text!="" && categorie!=null && addresseController.text!=""&& villeController.text!=""){
                        String? mail = _validateEmail(emailController.text);

                        if(mail==null){

                          Utilisateur user = Utilisateur(id: '', lastName: nomController.text.trim(),roles: ['ROLE_USER'], firstName: prenomController.text.trim(),password: passwordController.text.trim(), userType: 'Patient', phone: phoneController.text.trim(), email: emailController.text.trim(), imageName: (path.text!="")?path.text.trim():"", category: utilities!.extractApiPath(categorie!.id), address: addresseController.text.trim(), createdAt: DateTime.now(), city: villeController.text.trim());
                          addUser(user);
                        }else{
                          //print('MAIL NON VALIDE');
                          emailInvalide();
                        }
                      }else{
                        ChampsIncomplets();
                      }
                    }else{
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
                )
            ),

            const SizedBox(height: 50,)


          ],
        ): Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loadingWidget(),
            SizedBox(height: 30,),
            Text('Chargement des données..\n Assurez-vous d\'avoir une connexion internet',textAlign: TextAlign.center,)
          ],
        )
        )
    ),);
  }




  Widget loadingWidget(){
    return Center(
        child:Container(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [

              LoadingAnimationWidget.hexagonDots(
                  color: Colors.redAccent,
                  size: 120),

              Image.asset('assets/images/logo2.png',width: 80,height: 80,fit: BoxFit.cover,)
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
        message:
        'E-mail invalide!',

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
        message:
        'Champs incomplets!',

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
        message:
        'Utilisateur crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)..hideCurrentMaterialBanner()..showMaterialBanner(materialBanner);
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


