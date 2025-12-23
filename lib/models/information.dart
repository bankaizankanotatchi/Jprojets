import 'package:hive/hive.dart';

part 'information.g.dart';

@HiveType(typeId: 4)
class Information extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titre;

  @HiveField(2)
  List<String> points; // Les différents points de description

  @HiveField(3)
  List<String>? images;

  @HiveField(4)
  DateTime dateCreation;

  @HiveField(5)
  DateTime? dateModification;

  Information({
    required this.id,
    required this.titre,
    required this.points,
    this.images,
    required this.dateCreation,
    this.dateModification,
  });
}