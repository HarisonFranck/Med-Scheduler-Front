

import 'Specialite.dart';
import 'Centre.dart';



class UtilisateurSpec{

  String id;
  String? type;
  int myid;


  UtilisateurSpec({
    required this.id,
    this.type,
    required this.myid
  });

  // Constructeur nommé pour créer un Utilisateur à partir d'un objet JSON
  factory UtilisateurSpec.fromJson(Map<String, dynamic> json) {
    return UtilisateurSpec(
        id: json['@id'],
        type:json['@type'],
        myid: json['id'],

    );
  }


}