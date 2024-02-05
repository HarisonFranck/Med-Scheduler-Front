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
import 'package:med_scheduler_front/ConnectionError.dart';
import 'package:med_scheduler_front/Espace_Medecin/view/IndexAcceuilMedecin.dart';
import 'package:intl/intl.dart';

class MedecinRepository {
  final BuildContext context;
  final Utilities utilities;

  MedecinRepository({required this.context, required this.utilities});

  late AuthProvider authProvider;

  late String token;

  String baseUrl = UrlBase().baseUrl;


  Future<List<CustomAppointment>> getAllUnavalaibleAppointmentByDayAndDoctor(
      DateTime dtClicked, Medecin medecin,Medecin widgetMedecin) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;


      String formated = DateFormat('yyyy-MM-dd').format(dtClicked);


      print('MED ID: ${widgetMedecin.id}');
      final url = Uri.parse(
          "${baseUrl}api/unavailable_appointments?page=1&startAt[before]=$formated&startAt[after]=$formated");

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS AGENDA:  ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        //return datas.map((e) => CustomAppointment.fromJson(e)).toList();

        final unavAppoints = datas.where((e) {
          final med = Medecin.fromJson(e['doctor']);
          return med.id == medecin.id;
        }).toList();

        return unavAppoints.map((e) => CustomAppointment.fromJson(e)).toList();
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
      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }


  }

  Future<List<CustomAppointment>> getAllAppointmentMedecin(Medecin medecin) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;


      final url = Uri.parse(
          "${baseUrl}api/doctors/appointments/${utilities.extractLastNumber(medecin.id)}");

      final headers = {'Authorization': 'Bearer $token'};

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
    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      // Retourner une valeur par défaut en cas d'erreur
      return <CustomAppointment>[];
    }

  }



  Future<List<CustomAppointment>> getAllAppointment(Medecin medecin) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse(
          "${baseUrl}api/doctors/appointments/${utilities.extractLastNumber(medecin.id)}");

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




  Future<void> patchAppointment(
      CustomAppointment appointment) async {


    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/appointments/${utilities!.extractLastNumber(appointment.id)}");
    //final headers = {'Content-Type': 'application/json'};

    final headers = {
    'Content-Type': 'application/merge-patch+json',
    'Authorization': 'Bearer $token'
    };


    String jsonUser = jsonEncode(appointment.toJsonUnav());


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
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };


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
      //final headers = {'Content-Type': 'application/json'};

      final headers = {'Authorization': 'Bearer $token'};


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
    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }



  Future<List<CustomAppointment>> getAllAppointmentByMedecin(
      Utilisateur user) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      print('ID MED: ${user.id}');

      final url = Uri.parse(
          "${baseUrl}api/doctors/appointments/${utilities.extractLastNumber(user.id)}");

      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      print('STATUS CODE APPOINTS: ${response.statusCode} \n');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final datas = jsonData['hydra:member'] as List<dynamic>;

        final datasAppoints =
        datas.map((e) => CustomAppointment.fromJson(e)).toList();

        return datasAppoints.where((element) => (element.isDeleted==null||element.isDeleted==false)).toList();
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



  Future<void> getUserToChangePassword(int id,String newPassword) async {

    if(await utilities.isConnectionAvailable()){

      final url = Uri.parse("${baseUrl}api/change-password/$id");

      print('URL USER: $url');

      //final headers = {'Authorization': 'Bearer $token'};

      final body = {"password": "$newPassword"};

      final response = await http.patch(url, body: jsonEncode(body));
      print(' --- ST CODE: ${response.statusCode}');

      if (response.statusCode == 200) {
        utilities.modifPasswordValider();


        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>IndexAcceuilMedecin()), (route) => false);


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
    }

  }


}
