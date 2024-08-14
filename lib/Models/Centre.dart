import 'UtilisateurSpec.dart';

class Centre{

  String id;
  String type;
  String label;
  List<dynamic> users;
  String? description;
  DateTime? createdAt;




  Centre({required this.id,required this.type,required this.label,this.description,required this.users,this.createdAt});



  factory Centre.fromJson(Map<String,dynamic> json)=>Centre(
      id: json['@id'],
      type: json['@type'],
      label: json['label'],
      description: json['description'],
      users: ((json['users'] as List<dynamic>?) != null) ? json['users'].map((userData) => UtilisateurSpec.fromJson(userData)).toList() : [],
      createdAt: json['createdAt']!=null?DateTime.parse(json['createdAt']):null
  );

  Map<String, dynamic> toJson() {
    return {

      'label': label,
      'description':description,
      'createdAt': createdAt!.toIso8601String()
    };
  }


}