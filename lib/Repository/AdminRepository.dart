import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/Specialite.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:med_scheduler_front/Models/main.dart';
import 'package:med_scheduler_front/Models/Centre.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';

class AdminRepository {
  final BuildContext context;
  final Utilities utilities;

  AdminRepository({required this.context, required this.utilities});

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  Future<Utilisateur> getUser(String id) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url =
            Uri.parse("${baseUrl}api/users/${utilities.extractLastNumber(id)}");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

          Utilisateur user = Utilisateur.fromJson(jsonData);

          return user;
        } else {
          // Gestion des erreurs HTTP

          if (response.statusCode == 401) {
            authProvider.logout();
            // ignore: use_build_context_synchronously
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
              (route) => false,
            );
          }
          throw Exception('ANOTHER ERROR');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('Failed to get User');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      throw Exception('Failed to get User');
    }
  }

  /// Centre Repository
  ///
  /// Suppression Center

  Future<void> deleteCenter(String idCenter) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/centers/${utilities.extractLastNumber(idCenter)}");
        //final headers = {'Content-Type': 'application/merge-patch+json'};

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        final response = await http.delete(url, headers: headers);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Specialite déja existant');
          }
        } else {
          if (response.statusCode == 204) {
            utilities.DeleteCenter();
          } else {
            // Gestion des erreurs HTTP
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Ajout Center

  Future<void> addCenter(Centre centre) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;
        final url = Uri.parse("${baseUrl}api/centers");
        //final headers = {'Content-Type': 'application/json'};

        final headers = {
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token'
        };

        String jsonSpec = jsonEncode(centre.toJson());

        final response = await http.post(url, headers: headers, body: jsonSpec);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Centre déja existant');
          }
        } else {
          if (response.statusCode == 201) {
            utilities.CreationCentre();
          } else {
            // Gestion des erreurs HTTP
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Update Center

  Future<void> updateCenter(Centre centre) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/centers/${utilities.extractLastNumber(centre.id)}");
        //final headers = {'Content-Type': 'application/json'};

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        String jsonSpec = jsonEncode(centre.toJson());

        final response =
            await http.patch(url, headers: headers, body: jsonSpec);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Centre déja existant');
          } else {
            utilities.UpdateCenter();
          }
        } else {
          // Gestion des erreurs HTTP
          utilities
              .error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          throw Exception(
              '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Centre Repository
  ///
  /// Suppression Specialite

  Future<void> deleteSpecialite(String idSpec) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/specialities/${utilities.extractLastNumber(idSpec)}");
        //final headers = {'Content-Type': 'application/merge-patch+json'};

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        final response = await http.delete(url, headers: headers);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Specialite déja existant');
          }
        } else {
          if (response.statusCode == 204) {
            utilities.DeleteSpecialite();
          } else {
            // Gestion des erreurs HTTP
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Ajout Specialite

  Future<void> addSpecialite(Specialite specialite) async {
    try {
      if (await utilities.isConnectionAvailable()) {
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
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Update Specialite

  Future<void> updateSpecialite(Specialite specialite) async {
    try {
      if (await utilities.isConnectionAvailable()) {
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

        final response =
            await http.patch(url, headers: headers, body: jsonSpec);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Specialite déja existant');
          } else {
            utilities.UpdateSpecialite();
          }
        } else {
          // Gestion des erreurs HTTP
          utilities
              .error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          throw Exception('-- Erreur reseau');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Medecin Repository
  ///
  /// Update Medecin

  Future<void> updateMedecin(Utilisateur medecin) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/users/${utilities.extractLastNumber(medecin.id)}");
        //final headers = {'Content-Type': 'application/json'};

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        String jsonSpec = jsonEncode(medecin.toJson());

        final response =
            await http.patch(url, headers: headers, body: jsonSpec);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
            utilities.error('Medecin déja existant');
          } else {
            utilities.UpdateUtilisateur();
          }
        } else {
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

          utilities
              .error('Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          throw Exception('-- Failed to add user.');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  /// Ajout Medecin

  Future<void> addMedecin(Utilisateur medecin) async {
    try {
      if (await utilities.isConnectionAvailable()) {
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

        final response = await http.post(url, headers: headers, body: jsonSpec);

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
            // Gestion des erreurs HTTP
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  Future<void> deleteMedecin(Medecin medecin) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/users/${utilities.extractLastNumber(medecin.id)}");
        //final headers = {'Content-Type': 'application/merge-patch+json'};

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        final response = await http.delete(url, headers: headers);

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
            utilities.error(
                'Il y a une erreur.\n Veuillez ressayer ulterieurement.');
          }
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  Future<void> UserUpdate(Utilisateur utilisateur) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        final url = Uri.parse(
            "${baseUrl}api/users/${utilities.extractLastNumber(utilisateur.id)}");
        //final headers = {'Content-Type': 'application/json'};

        final headers = {'Content-Type': 'application/merge-patch+json'};

        String jsonUser = jsonEncode(utilisateur.toJson());

        final response =
            await http.patch(url, headers: headers, body: jsonUser);

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
            // ignore: use_build_context_synchronously
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
              (route) => false,
            );
          }
          // Gestion des erreurs HTTP
          utilities.error(
              'Il y a une erreur. HTTP Status Code: ${response.statusCode}');
          throw Exception(
              '-- Failed to add user. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }
}
