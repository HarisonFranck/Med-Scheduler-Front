
import 'Categorie.dart';
import 'Specialite.dart';
import 'Centre.dart';




class Medecin{

  String id;
  List<String> roles;
  Specialite? speciality;
  String lastName;
  String firstName;
  String userType;
  String phone;
  String? imageName;
  String email;
  String address;
  Categorie? category;
  DateTime? createdAt;
  String city;
  Centre? center;
  String? token;
  List<dynamic>? doctorAppointments;


  Medecin({
    required this.id,
    required this.roles,
    required this.speciality,
    required this.lastName,
    required this.firstName,
    required this.userType,
    required this.phone,
    required this.email,
    this.imageName,
    this.category,
    this.doctorAppointments,
    required this.address,
    required this.center,
    required this.createdAt,
    required this.city,
    this.token
  });

  // Constructeur nommé pour créer un Utilisateur à partir d'un objet JSON
  factory Medecin.fromJson(Map<String, dynamic> json) {
    return Medecin(
        id: json['@id'],
        roles: json['roles']!=null?List.from(json['roles']):[],
        speciality: json['speciality']!=null?Specialite.fromJson(json['speciality']):null,
        lastName: json['lastName'],
        firstName: json['firstName'],
        userType: json['userType']??'',
        phone: json['phone']??'',
        imageName: json['imageName']??'',
        email: json['email']??'',
        category: json['category']!=null?Categorie.fromJson(json['category']):null,
        address: json['address']??'',
        city: json['city']??'',
        token: json ['token'],
        doctorAppointments: json['doctorAppointments']!=null?json['doctorAppointments'] as List<dynamic>:[],
        center: json['center']!=null?Centre.fromJson(json['center']):null,
      createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):DateTime.now()
    );
  }

  // Méthode pour convertir un Utilisateur en un objet JSON
  Map<String, dynamic> toJson() {
    return {

      "lastName": lastName,
      "firstName": firstName,
      "userType": userType,
      "phone": phone,
      "email": email,
      "imageName":imageName,
      "category": category,
      "address": address,
      "city":city,
      "token":token,
      "createdAt": (createdAt!=null)?createdAt!.toIso8601String():DateTime.now().toIso8601String()

    };
  }

}