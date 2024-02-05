class UtilisateurImage {
  int id;
  String lastName;
  String firstName;
  String phone;
  String email;
  String imageName;
  DateTime createdAt;

  UtilisateurImage({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.phone,
    required this.email,
    required this.imageName,
    required this.createdAt,
  });

  factory UtilisateurImage.fromJson(Map<String, dynamic> json) {
    return UtilisateurImage(
      id: json['id'] as int,
      lastName: json['lastName'] as String,
      firstName: json['firstName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      imageName: json['imageName'] as String,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

// Ajoutez d'autres méthodes ou propriétés au besoin.
}