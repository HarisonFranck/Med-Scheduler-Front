


class UtilisateurNewPassword{

  int id;
  String? speciality;
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
  String? center;
  List<String> roles;
  List<dynamic>? patientAppointments;
  List<dynamic>? patientUnavailableAppointments;
  List<dynamic>? doctorAppointments;
  List<dynamic>? doctorUnavailableAppointments;


  UtilisateurNewPassword({
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
  factory UtilisateurNewPassword.fromJson(Map<String, dynamic> json) {
    return UtilisateurNewPassword(
        id: json['id'],
        speciality: json['speciality'] != null?json['speciality']:null,
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
    center: json['center']!=null?json['center']:null,
    createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):null,
    updatedAt: json['updatedAt']!=null?DateTime.parse(json['updatedAt']):null,
    patientAppointments: json['patientAppointments']!=null?json['patientAppointments'] as List<dynamic>:[],
    patientUnavailableAppointments: json['patientUnavailableAppointments']!=null?json['patientUnavailableAppointments'] as List<dynamic>:[],
    doctorAppointments: json['doctorAppointments']!=null?json['doctorAppointments'] as List<dynamic>:[],
    doctorUnavailableAppointments: json['doctorUnavailableAppointments']!=null?json['doctorUnavailableAppointments'] as List<dynamic>:[],
    );
  }

}

