class Patient {

  String id;
  String type;
  String? email;
  String lastName;
  String firstName;
  String? phone;
  String? address;
  String? userType;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? imageName;
  String? city;

  Patient({
    required this.id,
    required this.type,
    this.email,
    required this.lastName,
    required this.firstName,
     this.phone,
     this.address,
     this.userType,
     this.createdAt,
     this.updatedAt,
     this.imageName,
     this.city,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['@id'],
      type: json['@type'],
      email: json['email']??'',
      lastName: json['lastName'],
      firstName: json['firstName'],
      phone: json['phone']??'',
      address: json['address']??'',
      userType: json['userType']??'',
      createdAt: json['createdAt']??DateTime.now(),
      updatedAt: json['updatedAt']??DateTime.now(),
      imageName: json['imageName']??'',
      city: json['city']??'',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '@id': id,
      '@type': type,
      'email': email,
      'lastName': lastName,
      'firstName': firstName,
      'phone': phone,
      'address': address,
      'userType': userType,
      'createdAt': (createdAt!=null)?createdAt!.toIso8601String():DateTime.now().toIso8601String(),
      'updatedAt': (updatedAt!=null)?updatedAt!.toIso8601String():DateTime.now().toIso8601String(),
      'imageName': imageName,
      'city': city,
    };
  }
}
