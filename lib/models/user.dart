import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String nom;

  @HiveField(1)
  DateTime dateConnexion;

  User({
    required this.nom,
    required this.dateConnexion,
  });
}