
import 'Specialite.dart';
import 'Centre.dart';



class Utilisateur{

  String id;
  Specialite? speciality;
  String lastName;
  String firstName;
  String userType;
  String phone;
  String? imageName;
  String password;
  String email;
  String address;
  String? category;
  DateTime? createdAt;
  DateTime? updatedAt;
  String city;
  Centre? center;
  List<String> roles;
  List<String>? patientAppointments;
  List<String>? patientUnavailableAppointments;
  List<String>? doctorAppointments;
  List<String>? doctorUnavailableAppointments;


  Utilisateur({
    required this.id,
    this.speciality,
    required this.lastName,
    required this.firstName,
    required this.userType,
    required this.phone,
    required this.password,
    required this.email,
    required this.imageName,
    required this.category,
    required this.address,
    required this.roles,
    this.center,
    this.createdAt,
    this.updatedAt,
    this.patientAppointments,
    this.patientUnavailableAppointments,
    this.doctorAppointments,
    this.doctorUnavailableAppointments,
    required this.city,
  });

  // Constructeur nommé pour créer un Utilisateur à partir d'un objet JSON
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['@id'],
      speciality: json['speciality'] != null?Specialite.fromJson(json['speciality']):null,
      lastName: json['lastName'],
      firstName: json['firstName'],
      userType: json['userType'],
      phone: json['phone'],
        password:json['password'],
      imageName: json['imageName'],
      email: json['email'],
      roles: List<String>.from(json['roles']),
      category: json['category'],
      address: json['address'],
      city: json['city'],
      center: json['center']!=null?Centre.fromJson(json['center']):json['center'],
      createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):null,
      updatedAt: json['updatedAt']!=null?DateTime.parse(json['updatedAt']):null,
      patientAppointments: json['patientAppointments']!=null?json['patientAppointments']:[],
      patientUnavailableAppointments: json['patientUnavailableAppointments']!=null?json['patientUnavailableAppointments']:[],
      doctorAppointments: json['doctorAppointments']!=null?json['doctorAppointments']:[],
      doctorUnavailableAppointments: json['doctorUnavailableAppointments']!=null?json['doctorUnavailableAppointments']:[],
    );
  }



  // Méthode pour convertir un Utilisateur en un objet JSON
  Map<String, dynamic> toJson() {
    return {

      "lastName": lastName,
      "firstName": firstName,
      "userType": userType,
      "password":password,
      "phone": phone,
      "email": email,
      "imageName":imageName,
      "category": category,
      "address": address,
      "city":city,
      "center":(center!=null)?center!.id:null,
      "roles":roles,
      "speciality": (speciality!=null)?speciality!.id:null,
      "createdAt": (createdAt!=null)?createdAt!.toIso8601String():null,
      "updaedAt": (updatedAt!=null)?updatedAt!.toIso8601String():null,

    };
  }



}