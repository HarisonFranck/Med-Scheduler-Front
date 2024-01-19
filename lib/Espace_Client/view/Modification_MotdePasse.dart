import 'package:flutter/material.dart';
import 'Login.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/main.dart';

class Modification_MotdePasse extends StatefulWidget {
  @override
  _Modification_MotdePasseState createState() => _Modification_MotdePasseState();
}

class _Modification_MotdePasseState extends State<Modification_MotdePasse> {

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;


  TextEditingController emailController = TextEditingController();

  TextEditingController newmdpController = TextEditingController();

  TextEditingController confirmnewmdpController = TextEditingController();

  bool obscurepwd = true;
  bool obscureconfirmpwd = true;


  FocusNode _focusNodemail = FocusNode();


  final GlobalKey<ScaffoldState> scafkey = GlobalKey<ScaffoldState>();



  final _emailValidator = RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");



  /// Validation du format E-mail
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail.';
    } else if (!_emailValidator.hasMatch(email.trim())) {
      return 'Veuillez entrer une adresse e-mail valide.';
    }
    return null;
  }


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




  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false,child: Scaffold(

      backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
      key: scafkey,


      body: ListView(

        children: [



          Padding(padding: const EdgeInsets.only(top: 10,left: 10),child:  GestureDetector(

            onTap: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
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

            child: Text('Continuons,',textScaler: TextScaler.linear(2.5),style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.5),) ,
          ),



          const Padding(padding: EdgeInsets.only(top:40,bottom: 80,left: 40,right: 40),child: Center(

            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: Text('Créer votre nouveau clé de sécurité avec notre formulaire d’insertion du nouveau mot de passe.',textAlign: TextAlign.center,style: TextStyle(color: Color.fromARGB(1000, 60, 70, 120),letterSpacing: 1.3),) ,
            ),

          ),
          ),


          Padding(
            padding: const EdgeInsets.only(left: 35,right: 35, bottom: 30),
            child: TextFormField(
              focusNode: _focusNodemail,

              controller: emailController,

              keyboardType: TextInputType.emailAddress,

              style:const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                focusColor:const Color.fromARGB(255, 20, 20, 100),
                focusedBorder:const OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 20, 20, 100))
                ),
                hintStyle:const TextStyle(color: Colors.black,fontWeight: FontWeight.w300),

                labelText: 'Adresse Email',
                hintText: 'exemple@domaine.com',

                labelStyle: TextStyle(color: _focusNodemail.hasFocus?Colors.redAccent:Colors.black),
                border: OutlineInputBorder(
                  borderSide:const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder:const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)
                ),
                prefixIcon:const Icon(Icons.mail, color: Color.fromARGB(1000, 60, 70, 120)),

              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.only(top: 20,left: 35,right: 35, bottom: 30),
            child: TextFormField(
              controller: newmdpController,
              obscureText: obscurepwd?true:false,

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
                prefixIcon: const Icon(Icons.password, color: Colors.black),

              ),
            ),
          ),






          Padding(
            padding: const EdgeInsets.only(top: 20,left: 35,right: 35, bottom: 30),
            child: TextFormField(
              controller: confirmnewmdpController,
              obscureText: obscureconfirmpwd?true:false,

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
                prefixIcon: const Icon(Icons.password, color: Colors.black),

              ),
            ),
          ),




          Padding(
              padding: const EdgeInsets.only(top: 20.0,left: 40,right: 40),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(const Color.fromARGB(1000, 60, 70, 120)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Définissez le rayon de la bordure ici
                    ),

                  ),
                  minimumSize: MaterialStateProperty.all(const Size(260.0, 60.0)),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();

                  /// Si les champs nouveau mot de passe et la confirmation mot de passe ne sont pas vide
                  if((emailController.text!="")&&newmdpController.text!=""&&confirmnewmdpController.text!=""){


                    /// Si les champs nouveau mot de passe et la confirmation mot de passe sont les mêmes
                    if(newmdpController.text==confirmnewmdpController.text){

                      String? mail = _validateEmail(emailController.text);

                      if(mail==null){



                      }else{
                        emailInvalide();
                      }


                    }else{

                    }
                  }else{

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
              )
          ),


          const SizedBox(height: 20,)


        ],
      ),
    ),);
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
        'E-mail invalide.',

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


}
