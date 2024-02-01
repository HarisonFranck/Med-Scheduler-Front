import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/Specialite.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/main.dart';
import 'package:med_scheduler_front/Centre.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Espace_Admin/view/IndexAccueilAdmin.dart';
import 'package:med_scheduler_front/Espace_Client/view/IndexAccueil.dart';
import 'package:med_scheduler_front/Espace_Medecin/view/IndexAcceuilMedecin.dart';
import 'package:jwt_decode/jwt_decode.dart';

class BaseRepository{

  final BuildContext context;
  final Utilities utilities;

  BaseRepository({required this.context,required this.utilities});

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;




  Future<void> patchAppointment(
      CustomAppointment appointment) async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/appointments/${utilities.extractLastNumber(appointment.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/merge-patch+json',
      'Authorization': 'Bearer $token'
    };

    try {
      print('PATCH ISDELETED: ${appointment.isDeleted}');
      String jsonUser = jsonEncode(appointment.toJsonUnav());

      print('JSOON USER: ${jsonUser}');

      final response = await http.patch(url, headers: headers, body: jsonUser);
      print('${response.statusCode} \n BODY PATCH: ${response.body} ');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Rendez-vous déja existant');
        } else {}
      } else {


        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }

        if (response.statusCode == 201) {
        } else {
          // Gestion des erreurs HTTP

          utilities.error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      throw e;
    }
  }




  Future<void> createUnavalaibleAppointment(
      CustomAppointment appointment) async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/unavailable_appointments");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
      'Content-Type': 'application/ld+json',
      'Authorization': 'Bearer $token'
    };

    try {
      String jsonUser = jsonEncode(appointment.toJsonUnav());

      final response = await http.post(url, headers: headers, body: jsonUser);
      print('${response.statusCode} \n BODY: ${response.body} ');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Rendez-vous déja existant');
        } else {}
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }

        if (response.statusCode == 201) {
        } else {
          // Gestion des erreurs HTTP

          utilities.error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      throw e;
    }
  }

  Future<void> deleteUnavalaibleAppointment(
      CustomAppointment appointment) async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse(
        "${baseUrl}api/unavailable_appointments/${utilities.extractLastNumber(appointment.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {'Authorization': 'Bearer $token'};

    try {
      //print('Request Body: $jsonUser');
      final response = await http.delete(url, headers: headers);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('error')) {
          utilities.error('Rendez-vous déja existant');
        } else {}
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }

        if (response.statusCode == 204) {
        } else {
          // Gestion des erreurs HTTP

          utilities.error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      throw e;
    }
  }






  Future<Utilisateur> getUser(int id) async {
    final url = Uri.parse("${baseUrl}api/users/$id");

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        Utilisateur user = Utilisateur.fromJson(jsonData);

        print('UTILISATEUR: ${user.lastName}');

        return user;
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Gérer l'exception spécifique (ClientException dans ce cas)
      if (e is http.ClientException) {
       utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      throw e;
    }
  }





  Future<List<Medecin>> getAllMedecin() async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    // Définir l'URL de base
    Uri url = Uri.parse("${baseUrl}api/doctors?page=1");

    print('URI: $url');

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print('STATUS CODE MEDS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Medecin.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
          '-- Erreur d\'obtention des données\n vérifier votre connexion internet. Code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <Medecin>[];
    }
  }




  Future<List<Centre>> getAllCenter() async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/centers?page=1");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Centre.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {

      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <Centre>[];
    }
  }

  Future<List<Specialite>> getAllSpecialite() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;
    final url = Uri.parse("${baseUrl}api/specialities?page=1");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);
      print('STATUS CODE SPECS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Specialite.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {

      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <Specialite>[];
    }
  }




  Future<List<CustomAppointment>> getAllUnavalaibleAppointment(Medecin medecinClicked) async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;


    print('MED ID: ${medecinClicked.id}');
    final url = Uri.parse(
        "${baseUrl}api/doctors/unavailable/appointments/${utilities.extractLastNumber(medecinClicked.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {


        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }

        print('RESP ERROR UNAV: ${response.body}');
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {

      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }
  }

  Future<List<CustomAppointment>> getAllAppointmentByMedecin(Medecin medecinClicked) async {

    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;


    final url = Uri.parse(
        "${baseUrl}api/doctors/appointments/${utilities.extractLastNumber(medecinClicked.id)}");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGNENDAAA: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        //return datas.map((e) => CustomAppointment.fromJson(e)).toList();

        // Filtrer les rendez-vous à venir
        final upcomingAppointments = datas.where((e) {
          final appointmentDate = DateTime.parse(e['startAt']);
          return appointmentDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
        }).toList();

        return upcomingAppointments
            .map((e) => CustomAppointment.fromJson(e))
            .toList();
      } else {


        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }

        // Gestion des erreurs HTTP
        throw Exception('-- TOKEN EXPIRED.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }
  }




  Future<List<CustomAppointment>> getAllAppointment() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/appointments?page=1");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        print('DATAS SIZE:${datas.length}');

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }
  }




  Future<Utilisateur> getUserById(int id,String token) async {


    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse(
        "${baseUrl}api/users/$id");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        Utilisateur user = Utilisateur.fromJson(jsonData);



        print('UTILISATEUR: ${user.lastName}');

        return user;
      } else {


        // Gestion des erreurs HTTP
        throw Exception(
            '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {


      print('Error: $e \nStack trace: $stackTrace');
      throw Exception('-- Failed to load data. Error: $e');
    }
  }



  Future<void> getUserByUsernameAndPassword(String email,String password) async {


    final url = Uri.parse("${baseUrl}api/login_check");
    final headers = {'Content-Type': 'application/json'};


    try {
      Map<String, String> requestData = {
        'username': email,
        'password': password

      };

      final jsonEncode = json.encode(requestData);

      final response = await http.post(url,headers: headers,body: jsonEncode);
      print(response.statusCode);

      if (response.statusCode == 200) {



        if (response.body == null || response.body.isEmpty) {

          // Utilisateur non trouvé
          utilities.error( 'Utilisateur introuvable');
        } else {


          String token = jsonDecode(response.body)['token'];

          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.setToken(token);



          Map<String, dynamic> payload = Jwt.parseJwt(token);

          int idUser = payload['id'];
          print('ID USER INDEXED: $idUser');

          Utilisateur utilisateur = await getUserById(idUser, token);


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => utilisateur.userType=="Admin"
                  ? IndexAccueilAdmin()
                  : (utilisateur.userType=="Doctor"?IndexAcceuilMedecin():IndexAccueil()),
            ),
          );



        }
      } else {

        // Gestion des erreurs HTTP
        print('ERROR');
        utilities.error('Utilisateur introuvable');
        //throw Exception('-- Failed to get user. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e,stacktrace) {

      // Gestion des erreurs autres que HTTP
      print('ERROR CONNEXION');
      utilities.ErrorConnexion();
      throw Exception('-- Failed to get user. Error: $e\n STACK: $stacktrace');
    }
  }



  Future<List<CustomAppointment>> getAllAppointmentPerPage(int page) async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    final url = Uri.parse("${baseUrl}api/appointments?page=$page");

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }
  }


  Future<List<Medecin>> searchAllMedecin(String lastName) async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    token = authProvider.token;

    // Définir l'URL de base
    Uri url = Uri.parse("${baseUrl}api/doctors?page=1");

    // Ajouter les paramètres en fonction des cas
    if (lastName.trim().isNotEmpty) {

        url = Uri.parse("$url&lastName=$lastName");

    }

    print('URI: $url');

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => Medecin.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        throw Exception(
          '-- Erreur d\'obtention des données\n vérifier votre connexion internet. Code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      if (e is http.ClientException) {
        utilities.ErrorConnexion();
      } else {
        // Gérer d'autres exceptions
        print('Une erreur inattendue s\'est produite: $e');
      }

      // Retourner une valeur par défaut en cas d'erreur
      return <Medecin>[];
    }
  }



}