// ignore_for_file: camel_case_types, non_constant_identifier_names
class User_model {
  final String name;
  final String email;
  final String uid;
  final String profileimage;
  // final List <String> agents;
  final List<String> groupId;
  // List <String> chats;
  final bool Isonline;

  User_model(
      {required this.name,
      required this.email,
      required this.uid,
      required this.profileimage,
      required this.groupId,
      required this.Isonline}
      );

  Map<String, dynamic> toMap(){
    return {
        "name": name,
        "email": email,
        "uid": uid,
        "profileimage": profileimage,
        "groupId": groupId,
        "Isonline": Isonline
        };
      }

  factory User_model.fromMap(Map<String, dynamic> map) 
  {
    return User_model(
      name: map["name"],
      email: map["email"],
      uid: map["uid"],
      profileimage: map["profileimage"],
      groupId: map["groupId"],
      Isonline: map["Isonline"]);
  }
}
