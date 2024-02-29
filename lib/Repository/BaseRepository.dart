import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/Specialite.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/main.dart';
import 'package:med_scheduler_front/Models/Centre.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Espace_Admin/view/IndexAccueilAdmin.dart';
import 'package:med_scheduler_front/Espace_Client/view/IndexAccueil.dart';
import 'package:med_scheduler_front/Espace_Medecin/view/IndexAcceuilMedecin.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:med_scheduler_front/Models/Categorie.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart';
import 'dart:developer' as devtools show log;

class BaseRepository{

  final BuildContext context;
  final Utilities utilities;

  BaseRepository({required this.context,required this.utilities});

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;




  Future<void> patchAppointment(
      CustomAppointment appointment) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/appointments/${utilities.extractLastNumber(appointment.id)}");

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };


      String jsonUser = jsonEncode(appointment.toJsonUnav());



      final response = await http.patch(url, headers: headers, body: jsonUser);

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

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));

    }

  }




  Future<void> createUnavalaibleAppointment(
      CustomAppointment appointment) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/unavailable_appointments");


      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };

      String jsonUser = jsonEncode(appointment.toJsonUnav());

      final response = await http.post(url, headers: headers, body: jsonUser);

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
              'Il y a une erreur reseau.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));

    }

  }

  Future<void> deleteUnavalaibleAppointment(
      CustomAppointment appointment) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse(
          "${baseUrl}api/unavailable_appointments/${utilities.extractLastNumber(appointment.id)}");


      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.delete(url, headers: headers);


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
              'Il y a une erreur reseau');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));

    }
  }





  Future<Utilisateur> getUser(int id) async {

    if(await utilities.isConnectionAvailable()){


      final url = Uri.parse("${baseUrl}api/users/$id");

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        Utilisateur user = Utilisateur.fromJson(jsonData);


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

    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');

    }
  }





  Future<List<Medecin>> getAllMedecin() async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        // Définir l'URL de base
        Uri url = Uri.parse("${baseUrl}api/doctors?page=1");

        final headers = {'Authorization': 'Bearer $token'};

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
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Medecin>[];
      }
    }catch (e) {

      if(e is http.ClientException){
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Medecin>[];
      }
      // Retourner une valeur par défaut en cas d'erreur

      print('Unexpected Error: $e');
      // Gérer les autres erreurs ici
      return <Medecin>[];
    }

  }



  Future<List<Medecin>> getAllMedecinPerPage(int page) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        // Définir l'URL de base
        Uri url = Uri.parse("${baseUrl}api/doctors?page=$page");

        final headers = {'Authorization': 'Bearer $token'};

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
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Medecin>[];
      }
    }catch (e) {

      if(e is http.ClientException){
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Medecin>[];
      }
      // Retourner une valeur par défaut en cas d'erreur

      print('Unexpected Error: $e');
      // Gérer les autres erreurs ici
      return <Medecin>[];
    }

  }





  Future<List<Centre>> getAllCenter() async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse("${baseUrl}api/centers?page=1");

        final headers = {'Authorization': 'Bearer $token'};

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
      } else {
        utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Centre>[];
      }
    } catch (e) {
      if(e is http.ClientException){
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Unexpected Error: $e');
      // Gérer les autres erreurs ici
      return <Centre>[];
    }
  }


  Future<List<Specialite>> getAllSpecialite() async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;
        final url = Uri.parse("${baseUrl}api/specialities?page=1");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;

          return datas.map((e) => Specialite.fromJson(e)).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Specialite>[];
      }
    } catch (e) {
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <Specialite>[];
    }
  }




  Future<List<CustomAppointment>> getAllUnavalaibleAppointment(Medecin medecinClicked) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;


        final url = Uri.parse(
            "${baseUrl}api/doctors/unavailable/appointments/${utilities
                .extractLastNumber(medecinClicked.id)}");

        final headers = {'Authorization': 'Bearer $token'};


        final response = await http.get(url, headers: headers);


        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;

          return datas.map((e) => CustomAppointment.fromJson(e)).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }

          print('RESP ERROR UNAV: ${response.body}');
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Failed to load data. HTTP Status Code: ${response
                  .statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <CustomAppointment>[];
      }
    }catch (e) {
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <CustomAppointment>[];
    }


  }

  Future<List<CustomAppointment>> getAllAppointmentByMedecin(Medecin medecinClicked) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;


        final url = Uri.parse(
            "${baseUrl}api/doctors/appointments/${utilities.extractLastNumber(
                medecinClicked.id)}");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;

          //return datas.map((e) => CustomAppointment.fromJson(e)).toList();

          // Filtrer les rendez-vous à venir
          final upcomingAppointments = datas.where((e) {
            final appointmentDate = DateTime.parse(e['startAt']);
            return appointmentDate.isAfter(
                DateTime.now().subtract(Duration(days: 1)));
          }).toList();

          return upcomingAppointments
              .map((e) => CustomAppointment.fromJson(e))
              .toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            // ignore: use_build_context_synchronously
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),(route) => false,);
          }

          // Gestion des erreurs HTTP
          throw Exception('-- TOKEN EXPIRED.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <CustomAppointment>[];
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <CustomAppointment>[];
    }

  }




  Future<List<CustomAppointment>> getAllAppointment() async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse("${baseUrl}api/appointments?page=1");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);


        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;


          return datas.map((e) => CustomAppointment.fromJson(e)).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <CustomAppointment>[];
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <CustomAppointment>[];
    }

  }




  Future<Utilisateur> getUserById(int id,String token) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/users/$id");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

          Utilisateur user = Utilisateur.fromJson(jsonData);


          return user;
        } else {
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Failed to load data. HTTP Status Code: ${response
                  .statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception(
            '-- Failed to load data.');
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      throw Exception(
          '-- Failed to load data.');

    }

  }



  Future<void> getUserByUsernameAndPassword(String email,String password) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        final url = Uri.parse("${baseUrl}api/login_check");
        final headers = {'Content-Type': 'application/json'};

        Map<String, String> requestData = {
          'username': email,
          'password': password
        };

        final jsonEncode = json.encode(requestData);

        final response = await http.post(
            url, headers: headers, body: jsonEncode);
        print(response.statusCode);

        if (response.statusCode == 200) {
          if (response.body == null || response.body.isEmpty) {
            // Utilisateur non trouvé
            utilities.error('Utilisateur introuvable');
          } else {
            String token = jsonDecode(response.body)['token'];

            final authProvider = Provider.of<AuthProvider>(
                context, listen: false);
            authProvider.setToken(token);


            Map<String, dynamic> payload = Jwt.parseJwt(token);

            int idUser = payload['id'];

            Utilisateur utilisateur = await getUserById(idUser, token);


            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                utilisateur.userType == "Admin"
                    ? IndexAccueilAdmin()
                    : (utilisateur.userType == "Doctor"
                    ? IndexAcceuilMedecin()
                    : IndexAccueil()),
              ),
            );
          }
        } else {
          utilities.error('Utilisateur introuvable');
          //throw Exception('-- Failed to get user. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception(
            '-- Failed to load data.');
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      throw Exception(
          '-- Failed to load data.');

    }

  }



  Future<List<CustomAppointment>> getAllAppointmentPerPage(int page) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse("${baseUrl}api/appointments?page=$page");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;

          return datas.map((e) => CustomAppointment.fromJson(e)).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <CustomAppointment>[];
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <CustomAppointment>[];
    }

  }


  Future<List<Medecin>> searchAllMedecin(String lastName) async {

    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        // Définir l'URL de base
        Uri url = Uri.parse("${baseUrl}api/doctors?page=1");

        // Ajouter les paramètres en fonction des cas
        if (lastName
            .trim()
            .isNotEmpty) {
          url = Uri.parse("$url&lastName=$lastName");
        }


        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;

          return datas.map((e) => Medecin.fromJson(e)).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }
          // Gestion des erreurs HTTP
          throw Exception(
            '-- Erreur d\'obtention des données\n vérifier votre connexion internet. Code: ${response
                .statusCode}',
          );
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        // Retourner une valeur par défaut en cas d'erreur
        return <Medecin>[];
      }
    }catch(e){
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <Medecin>[];
    }

  }


  Future<List<Categorie>> getAllCategorie() async {
    try {
      if (await utilities.isConnectionAvailable()) {
        final url = Uri.parse("${baseUrl}api/categories?page=1");

        final response = await http.get(url);


        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

          final datas = jsonData['hydra:member'] as List<dynamic>;

          return datas.map((e) => Categorie.fromJson(e)).toList();
        } else {
          // Gestion des erreurs HTTP
          utilities.ErrorConnexion();

          throw Exception(
              '-- Erreur d\'obtention des données\n vérifier votre connexion internet.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

        return <Categorie>[];
      }
    } catch (e) {
      if (e is http.ClientException) {

        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));

      }
      print('Exception: $e');
      return <Categorie>[];
    }
  }

  Future<bool> sendNotificationDisableAppointment({
    required String doctorName,
    required String recipientToken}) async {


    final jsonCredentials = await rootBundle
        .loadString('assets/data/med-scheduler-front-d86b24fcb422.json');
    final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);

    final client = await auth.clientViaServiceAccount(
      creds,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );

    final notificationData = {
      'message': {
        'token': recipientToken,
        'notification': {'title': 'Rendez-vous annulé', 'body': 'Votre rendez-vous avec le Dr.$doctorName a eté annulé.\n veuillez le contacter pour plus d\'information.'}
      },
    };

    const String senderId = '469458129138';
    final response = await client.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
      headers: {
        'content-type': 'application/json',
      },
      body: jsonEncode(notificationData),
    );

    client.close();
    if (response.statusCode == 200) {
      return true; // Success!
    }

    devtools.log(
        'Notification Sending to Patient Error Response status: ${response.statusCode}');
    devtools.log('Notification Patient Response body: ${response.body}');
    return false;
  }

}