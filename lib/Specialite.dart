import 'UtilisateurSpec.dart';

class Specialite{

  String id;
  String type;
  String label;
  String? description;
  List<dynamic> users;
  DateTime? createdAt;
  DateTime? updatedAt;




  Specialite({required this.id,required this.type,this.description,required this.users,required this.label,this.createdAt,this.updatedAt});


  factory Specialite.fromJson(Map<String, dynamic> json)=>Specialite(


      // Vérifiez si usersData est nul avant de le traiter comme une liste


      id: json['@id'],
      type: json['@type'],
      label: json['label'],
      description: json['description'],
      users: ((json['users'] as List<dynamic>?) != null) ? json['users'].map((userData) => UtilisateurSpec.fromJson(userData)).toList() : [],
      createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):null,
      updatedAt: json['updatedAt']!=null?DateTime.parse(json['updatedAt']):null
  );



  Map<String, dynamic> toJson() => {
    "label": label,
    "description": description,
    "type": (type != "") ? type : "Speciality",
    "users":users,
    "createdAt": (createdAt != null) ? createdAt!.toIso8601String() : null,
    "updatedAt": (updatedAt != null) ? updatedAt!.toIso8601String() : null,
  };



}