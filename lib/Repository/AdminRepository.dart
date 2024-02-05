import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Utilisateur.dart';
import 'package:med_scheduler_front/Specialite.dart';
import 'package:med_scheduler_front/AuthProvider.dart';
import 'package:med_scheduler_front/UrlBase.dart';
import 'package:med_scheduler_front/main.dart';
import 'package:med_scheduler_front/Centre.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:med_scheduler_front/ConnectionError.dart';



class AdminRepository{

  final BuildContext context;
  final Utilities utilities;

  AdminRepository({required this.context,required this.utilities});



  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;




  Future<Utilisateur> getUser(String id) async {


    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/users/${utilities.extractLastNumber(id)}");

      print('URL USER: $url');

      final headers = {'Authorization': 'Bearer $token'};

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
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        throw Exception('ANOTHER ERROR');
      }
    }else{
      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
      throw Exception('Failed to get User');
    }

  }



  /// Centre Repository
  ///
  /// Suppression Center


  Future<void> deleteCenter(String idCenter) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url =
      Uri.parse("${baseUrl}api/centers/${utilities.extractLastNumber(idCenter)}");
      //final headers = {'Content-Type': 'application/merge-patch+json'};

      print('URL DELETE: $url');

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };

      final response = await http.delete(url, headers: headers);
      print(response.statusCode);
      print('RESP: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 204) {
          utilities.DeleteCenter();
        } else {
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }



  /// Ajout Center


  Future<void> addCenter(Centre centre) async {


    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;
      final url = Uri.parse("${baseUrl}api/centers");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };

      String jsonSpec = jsonEncode(centre.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Centre déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          utilities.CreationCentre();
        } else {
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }


  /// Update Center

  Future<void> updateCenter(Centre centre) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;
      print('CENTER ID: ${centre.id}');

      final url =
      Uri.parse("${baseUrl}api/centers/${utilities.extractLastNumber(centre.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };

      String jsonSpec = jsonEncode(centre.toJson());

      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Centre déja existant');
        } else {
          utilities.UpdateCenter();
        }
      } else {
        // Gestion des erreurs HTTP
        utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }
  }


  /// Centre Repository
  ///
  /// Suppression Specialite

  Future<void> deleteSpecialite(String idSpec) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url =
      Uri.parse("${baseUrl}api/specialities/${utilities.extractLastNumber(idSpec)}");
      //final headers = {'Content-Type': 'application/merge-patch+json'};

      print('URL DELETE: $url');

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };

      final response = await http.delete(url, headers: headers);
      print(response.statusCode);
      print('RESP: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 204) {
          utilities.DeleteSpecialite();
        } else {
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }


  }



  /// Ajout Specialite

  Future<void> addSpecialite(Specialite specialite) async {

    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/specialities");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };

      String jsonSpec = jsonEncode(specialite.toJson());

      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Specialite déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          utilities.CreationSpecialite();
        } else {
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }


  /// Update Specialite


  Future<void> updateSpecialite(Specialite specialite) async {


    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse(
          "${baseUrl}api/specialities/${utilities.extractLastNumber(specialite.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };

      String jsonSpec = jsonEncode(specialite.toJson());

      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Specialite déja existant');
        } else {
          utilities.UpdateSpecialite();
        }
      } else {
        // Gestion des erreurs HTTP
        utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }




  /// Medecin Repository
  ///
  /// Update Medecin

  Future<void> updateMedecin(Utilisateur medecin) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url =
      Uri.parse("${baseUrl}api/users/${utilities.extractLastNumber(medecin.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };

      String jsonSpec = jsonEncode(medecin.toJson());


      print('Request Body: $jsonSpec');
      final response = await http.patch(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('ERRRR: $jsonResponse');

        if (jsonResponse.containsKey('error')) {
          utilities.error('Specialite déja existant');
        } else {
          utilities.UpdateUtilisateur();
        }
      } else {


        if (response.statusCode == 401) {
          authProvider.logout();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
        }
        // Gestion des erreurs HTTP

        print('REQ ERROR: ${response.body}');

        utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        throw Exception(
            '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
      }
    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }


  /// Ajout Medecin


  Future<void> addMedecin(Utilisateur medecin) async {

    if(await utilities.isConnectionAvailable()){


      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url = Uri.parse("${baseUrl}api/users");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {
        'Content-Type': 'application/ld+json',
        'Authorization': 'Bearer $token'
      };


      String jsonSpec = jsonEncode(medecin.toJson());
      print('Request Body: $jsonSpec');
      final response = await http.post(url, headers: headers, body: jsonSpec);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        utilities.CreationUtilisateur();

        if (jsonResponse.containsKey('error')) {
          utilities.error('Medecin déja existant');
        }
      } else {
        if (response.statusCode == 201) {
          utilities.CreationUtilisateur();
        } else {
          print('REQU BODY: ${response.body}');
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }

    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }




  Future<void> deleteMedecin(Medecin medecin) async {


    if(await utilities.isConnectionAvailable()){

      authProvider = Provider.of<AuthProvider>(context, listen: false);
      token = authProvider.token;

      final url =
      Uri.parse("${baseUrl}api/users/${utilities.extractLastNumber(medecin.id)}");
      //final headers = {'Content-Type': 'application/merge-patch+json'};

      print('URL DELETE: $url');

      final headers = {
        'Content-Type': 'application/merge-patch+json',
        'Authorization': 'Bearer $token'
      };


      final response = await http.delete(url, headers: headers);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);


        if (jsonResponse.containsKey('error')) {
          utilities.error('Il y a une erreur de connexion');
        }
      } else {
        if (response.statusCode == 204) {
          utilities.DeleteMedecin();
        } else {
          // Gestion des erreurs HTTP
          utilities.error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
        }
      }
    }else{

      utilities.handleConnectionError(ConnectionError("Une erreur de connexion s'est produite!"));
    }

  }



  Future<void> UserUpdate(Utilisateur utilisateur) async {

    if(await utilities.isConnectionAvailable()){

      final url = Uri.parse(
          "${baseUrl}api/users/${utilities.extractLastNumber(utilisateur.id)}");
      //final headers = {'Content-Type': 'application/json'};

      final headers = {'Content-Type': 'application/merge-patch+json'};

      String jsonUser = jsonEncode(utilisateur.toJson());

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
    }

  }




}