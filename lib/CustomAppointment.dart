import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Medecin.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/Patient.dart';
import 'dart:math';
import 'dart:convert';


class CustomAppointment{

  final String type;
  final String id;
  final Medecin? medecin;
  final Patient? patient;
  final DateTime startAt;   // ex = 2023-12-19 00H
  final DateTime timeStart; // ex = 2023-12-19 09H
  final DateTime timeEnd;   // ex = 2023-12-19 10H
  final String reason;
  final DateTime createdAt;
  final Color color;
  final String? appType;

  CustomAppointment({
    this.medecin,
    this.patient,
    required this.id,
    required this.type,
    required this.startAt,
    required this.timeStart,
    required this.timeEnd,
    required this.reason,
    required this.createdAt,
    this.appType
  }): color = getRandomColor().withOpacity(0.8);


  factory CustomAppointment.fromJson(Map<String,dynamic> json){

    Color color = getRandomColor().withOpacity(0.5);

    DateTime parseDate(String dateString) {
      // Remplacer le décalage horaire "+01:00" par "+00:00" avant l'analyse
      String adjustedDateString = dateString.replaceFirst(RegExp(r'\+(\d\d):(\d\d)$'), '+00:00');

      // Utiliser le parseur de date avec le décalage horaire modifié
      DateFormat dateFormat = DateFormat("yyyy-MM-ddTHH:mm:ssZ");
      return dateFormat.parse(adjustedDateString);
    }

    //Medecin medecin = Medecin(idmedecin: json['idmedecin'], speciality_id: json['speciality_id'], lastname: json['lastname'], firstname: json['firstname'], profil: json['profil'], phone: json['phone'], email: json['email'], onm: json['onm'], address: json['address'], created_at: json['created_at'], updated_at: json['updated_at']);
    //Patient patient = Patient(idpatient: json['idpatient'], nom: json['nom'], prenom: json['prenom'], email: json['email'], telephone: json['telephone'], idcategorie: json['idcategorie'], motdepasse: json['motdepasse']);

    return CustomAppointment(
        id: json['@id'],
        type: json['@type'],
        medecin: json['doctor'] != null?Medecin.fromJson(json['doctor']):null,
        patient: json['patient'] != null?Patient.fromJson(json['patient']):null,
        startAt: parseDate(json['startAt']) ,
        timeStart:parseDate(json['timeStart']),
        timeEnd:parseDate(json['timeEnd']),
        reason: json['reason'],
        createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):DateTime.now(),
        appType:json['appType']??'',
        );
}



  String encodeTimeOfDay(TimeOfDay timeOfDay){


    Map<String, dynamic> timeOfDayMap = {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };

    String timeEncoded = jsonEncode(timeOfDayMap);

    return timeEncoded;

  }


Map<String,dynamic> toJson()=>{


    "doctor": medecin!.id,
    "patient": patient!.id,
    "startAt": startAt.toIso8601String(),
    "timeStart": timeStart.toIso8601String(),
    "timeEnd": timeEnd.toIso8601String(),
    "reason": reason,
    "createdAt": createdAt.toIso8601String(),
    "appType":appType

  };

  Map<String,dynamic> toJsonUnav()=>{


    "doctor": medecin!.id,
    "startAt": startAt.toIso8601String(),
    "timeStart": timeStart.toIso8601String(),
    "timeEnd": timeEnd.toIso8601String(),
    "reason": reason,
    "createdAt": createdAt.toIso8601String(),
    "appType":appType

  };

  static Color getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }



}