import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/main.dart';
import 'package:med_scheduler_front/CustomAppointment.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Espace_Client/view/PriseDeRendezVous.dart';
import 'package:med_scheduler_front/Espace_Client/view/Login.dart';
import 'dart:io';
import 'package:med_scheduler_front/Patient.dart';
import 'package:med_scheduler_front/ConnectionError.dart';

class UserRepository {
  final BuildContext context;
  final Utilities utilities;

  UserRepository({required this.context, required this.utilities});

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  Future<List<CustomAppointment>> getAllAppointmentByPatient(
      Utilisateur user) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse(
          "${baseUrl}api/patients/appointments/${utilities.extractLastNumber(user.id)}");

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        final datasAppoints =
        datas.map((e) => CustomAppointment.fromJson(e)).toList();

        return datasAppoints
            .where((element) =>
        (element.isDeleted == null || element.isDeleted == false))
            .toList();
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

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));

      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];

    }


  }

  Future<List<Medecin>> getAllMedecin(int page, String lastName, String center,
      String spec, String location) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      // Définir l'URL de base
      Uri url = Uri.parse("${baseUrl}api/doctors?page=$page");

      // Ajouter les paramètres en fonction des cas
      if (lastName.trim().isNotEmpty) {
        print('ANARANA');
        if (center.trim().isNotEmpty) {
          url = Uri.parse("$url&lastName=$lastName&center=$center");
        } else if (spec.isNotEmpty) {
          url = Uri.parse("$url&lastName=$lastName&speciality=$spec");
        } else if (location.isNotEmpty) {
          url = Uri.parse("$url&lastName=$lastName&city=$location");
        } else {
          url = Uri.parse("$url&lastName=$lastName");
        }
      } else if (location.trim().isNotEmpty) {
        url = Uri.parse("$url&city=$location");
      } else if (center.trim().isNotEmpty) {
        url = Uri.parse("$url&center=$center");
      } else if (spec.trim().isNotEmpty) {
        url = Uri.parse("$url&speciality=$spec");
      }

      print('URI: $url');

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

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      // Retourner une valeur par défaut en cas d'erreur
      return <Medecin>[];
    }


  }

  Future<void> addAppointment(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/appointments");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };


      String jsonUser = jsonEncode(appointment.toJson());
      print('Request Body: $jsonUser');
      final response = await http.post(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Rendez-vous déja existant');
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        }
      } else {
        if (response.statusCode == 201) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          } else {
            utilities.error(
                'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
          }
        }
      }
    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');
    }

  }

  Future<void> addAppointmentUnavailable(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {

    if(await utilities.isConnectionAvailable()){
      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/unavailable_appointments");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };

      String jsonUser = jsonEncode(appointment.toJson());
      print('Request Body: $jsonUser');
      final response = await http.post(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Rendez-vous déja existant');
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        }
      } else {
        if (response.statusCode == 201) {
          utilities.RdvValider();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PriseDeRendezVous(patient: widgetAppointment.patient!),
                  settings: RouteSettings(arguments: appointment.medecin)));
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }

          // Gestion des erreurs HTTP
          utilities.error(
              'Il y a une erreur APPOINTMENT. HTTP Status Code: ${response.statusCode}');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');
    }

  }

  Future<void> patchUserPassword(int id, String newPassword) async {

    if(await utilities.isConnectionAvailable()){

      final url = Uri.parse("${baseUrl}api/change-password/$id");

      print('URL USER: $url');

      //final headers = {'Authorization': 'Bearer $token'};

      final body = {"password": "$newPassword"};

      final response = await http.patch(url, body: jsonEncode(body));
      print(' --- ST CODE: ${response.statusCode}');

      if (response.statusCode == 200) {
        utilities.modifPasswordValider();

        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) => Login()), (route) => false);
      } else {
        // Gestion des erreurs HTTP

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        throw Exception('ANOTHER ERROR');
      }

    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');
    }



  }

  Future<void> UserUpdate(Utilisateur utilisateur) async {


    if(await utilities.isConnectionAvailable()){

      final url = Uri.parse(
          "${baseUrl}api/users/${utilities.extractLastNumber(utilisateur.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {'Content-Type': 'application/merge-patch+json'};

      String jsonUser = jsonEncode(utilisateur.toJson());
      print('Request Body: $jsonUser');
      final response = await http.patch(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('error')) {
          utilities.error('Erreur de modification');
        } else {
          utilities.ModificationUtilisateur();
        }
      } else {
        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        utilities.error(
            'Il y a une erreur. HTTP Status Code: ${response.statusCode}');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }


    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');
    }

  }

  Future<Utilisateur> getUser(String id) async {

    if(await utilities.isConnectionAvailable()){

      final url =
      Uri.parse("${baseUrl}api/users/${utilities.extractLastNumber(id)}");

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

  Future<void> UserUpdateImage(File file,Utilisateur utilisateur) async {

    if(await utilities.isConnectionAvailable()){
      final url = Uri.parse(
          "${baseUrl}api/image-profile/${utilities.extractLastNumber(utilisateur.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {'Content-Type': 'multipart/form-data'};


      var request = http.MultipartRequest('POST', Uri.parse(url.path));

      // Ajouter le fichier au champ de données multipartes
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile('file', fileStream, length,
          filename: file.path.split('/').last);
      request.files.add(multipartFile);

      //String jsonUser = jsonEncode(utilisateur.toJson());
      //print('Request Body: $jsonUser');

      var response = await http.Response.fromStream(await request.send());

      //final response = await http.patch(url, headers: headers, body: jsonUser);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Erreur de modification');
        } else {
          utilities.ModificationUtilisateur();
        }
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP
        utilities.error(
            'Il y a une erreur de connexion\n Veuillez verifiez votre connexion!');
        throw Exception('-- Erreur de connexion');
      }
    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception(
          '-- Failed to load data.');
    }

  }


  Future<List<CustomAppointment>> getAllUnavalaibleAppointment(Medecin medecinCliked) async {
    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse(
          "${baseUrl}api/doctors/unavailable/appointments/${utilities.extractLastNumber(medecinCliked.id)}");

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;


        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {

        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const MyApp()),(route) => false,);
        }
        print('RESP ERROR UNAV: ${response.body}');
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



  Future<List<CustomAppointment>> getAllAppointmentByUserPatient(Patient patient) async {

    if(await utilities.isConnectionAvailable()){
      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;


      final url = Uri.parse(
          "${baseUrl}api/patients/appointments/${utilities.extractLastNumber(patient.id)}");

      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        return datas.map((e) => CustomAppointment.fromJson(e)).toList();
      } else {
        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const MyApp()),(route) => false,);
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





}
