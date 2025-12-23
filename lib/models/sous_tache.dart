import 'package:hive/hive.dart';

part 'sous_tache.g.dart';

@HiveType(typeId: 3)
class SousTache extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titre;

  @HiveField(2)
  bool estCompletee;

  @HiveField(3)
  DateTime dateCreation;

  SousTache({
    required this.id,
    required this.titre,
    required this.estCompletee,
    required this.dateCreation,
  });
}