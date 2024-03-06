import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/main.dart';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Espace_Client/view/PriseDeRendezVous.dart';
import 'package:med_scheduler_front/Espace_Client/view/Login.dart';
import 'dart:io';
import 'package:med_scheduler_front/Models/Patient.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart';
import 'dart:developer' as devtools show log;

class UserRepository {
  final BuildContext context;
  final Utilities utilities;

  UserRepository({required this.context, required this.utilities});

  late AuthProvider authProvider;
  late String token;

  String baseUrl = UrlBase().baseUrl;

  Future<List<CustomAppointment>> getAllAppointmentByPatient(
      Utilisateur user) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/patients/appointments/${utilities.extractLastNumber(user.id)}");

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

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
            // ignore: use_build_context_synchronously
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),
                (route) => false);
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
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      return <CustomAppointment>[];
    }
  }

  Future<List<Medecin>> getAllMedecin(int page, String lastName, String center,
      String spec, String location) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        // Définir l'URL de base
        Uri url = Uri.parse("${baseUrl}api/doctors?page=$page");

        // Ajouter les paramètres en fonction des cas
        if (lastName.trim().isNotEmpty) {
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

        final headers = {'Authorization': 'Bearer $token'};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          final datas = jsonData['hydra:member'] as List<dynamic>;
          return datas.map((e) => Medecin.fromJson(e)).toList();
          //List<Medecin> list = datas.map((e) => Medecin.fromJson(e)).toList();
          //return list.where((medecin) => (medecin.token!=null&&medecin.token!="")).toList();
        } else {
          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyApp()));
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
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      return <Medecin>[];
    }
  }

  Future<void> addAppointment(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse("${baseUrl}api/appointments");

        final headers = {
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token'
        };

        String jsonUser = jsonEncode(appointment.toJson());
        final response = await http.post(url, headers: headers, body: jsonUser);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

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
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  Future<void> addAppointmentUnavailable(CustomAppointment appointment,
      CustomAppointment widgetAppointment) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse("${baseUrl}api/unavailable_appointments");
        //final headers = {'Content-Type': 'application/json'};

        final headers = {
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token'
        };

        String jsonUser = jsonEncode(appointment.toJson());
        final response = await http.post(url, headers: headers, body: jsonUser);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

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
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  Future<void> patchUserPassword(int id, String newPassword) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        final url = Uri.parse("${baseUrl}api/change-password/$id");

        final body = {"password": "$newPassword"};

        final response = await http.patch(url, body: jsonEncode(body));

        if (response.statusCode == 200) {
          utilities.modifPasswordValider();

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Login()),
              (route) => false);
        } else {
          // Gestion des erreurs HTTP

          if (response.statusCode == 401) {
            authProvider.logout();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyApp()));
          }
          throw Exception('ANOTHER ERROR');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
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
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MyApp()));
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
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {}
  }

  Future<Utilisateur> getUser(String id) async {
    try {
      if (await utilities.isConnectionAvailable()) {
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
            // ignore: use_build_context_synchronously
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
              (route) => false,
            );
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      throw Exception('-- Failed to load data.');
    }
  }

  Future<void> UserUpdateImage(File file, Utilisateur utilisateur) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        final url = Uri.parse(
            "${baseUrl}api/image-profile/${utilities.extractLastNumber(utilisateur.id)}");

        final headers = {'Content-Type': 'multipart/form-data'};

        var request = http.MultipartRequest('POST', Uri.parse(url.path));

        // Ajouter le fichier au champ de données multipartes
        var fileStream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile('file', fileStream, length,
            filename: file.path.split('/').last);
        request.files.add(multipartFile);

        var response = await http.Response.fromStream(await request.send());

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
              'Il y a une erreur de connexion\n Veuillez verifiez votre connexion!');
          throw Exception('-- Erreur de connexion');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
    }
  }

  Future<List<CustomAppointment>> getAllUnavalaibleAppointment(
      Medecin medecinCliked) async {
    try {
      if (await utilities.isConnectionAvailable()) {
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
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
              (route) => false,
            );
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      throw Exception('-- Failed to load data.');
    }
  }

  Future<List<CustomAppointment>> getAllAppointmentByUserPatient(
      Patient patient) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/patients/appointments/${utilities.extractLastNumber(patient.id)}");

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
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
              (route) => false,
            );
          }
          // Gestion des erreurs HTTP
          throw Exception(
              '-- Failed to load data. HTTP Status Code: ${response.statusCode}');
        }
      } else {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
        throw Exception('-- Failed to load data.');
      }
    } catch (e) {
      if (e is http.ClientException) {
        utilities.handleConnectionError(
            ConnectionError("Une erreur de connexion s'est produite!"));
      }
      print('Exception: $e');
      throw Exception('-- Failed to load data.');
    }
  }

  Future<void> updatePatient(Utilisateur patient) async {
    try {
      if (await utilities.isConnectionAvailable()) {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
        token = authProvider.token;

        final url = Uri.parse(
            "${baseUrl}api/users/${utilities.extractLastNumber(patient.id)}");

        final headers = {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token'
        };

        String jsonSpec = jsonEncode(patient.toJson());

        final response =
            await http.patch(url, headers: headers, body: jsonSpec);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('error')) {
          } else {}
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

  Future<bool> sendPushMessage({required String recipientToken}) async {
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
        'notification': {
          'title': 'Nouveau rendez-vous',
          'body': 'Un patient a pris un rendez-vous avec vous.'
        }
      },
    };

    const String senderId = '469458129138';
    final response = await client.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
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
        'Notification Sending Error Response status: ${response.statusCode}');
    devtools.log('Notification Response body: ${response.body}');
    return false;
  }
}
