class Categorie{

  String id;
  String type;
  String title;
  String description;





  Categorie({required this.id,required this.type,required this.title,required this.description});


  factory Categorie.fromJson(Map<String,dynamic> json)=>Categorie(
      id: json['@id']??'',
      type: json['@type']??'',
      title: json['title']??'',
      description: json['description']??'',
  );

  Map<String, dynamic> toJson() {
    return {
      '@id': id,
      '@type': type,
      'title': title,
      'description': description,
    };
  }

}