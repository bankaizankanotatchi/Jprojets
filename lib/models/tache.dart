import 'package:hive/hive.dart';
import 'package:jprojets/models/sous_tache.dart';

part 'tache.g.dart';

@HiveType(typeId: 2)
class Tache extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titre;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool estCompletee;

  @HiveField(4)
  List<SousTache>? sousTaches;

  @HiveField(5)
  List<String>? checklist;

  @HiveField(6)
  DateTime dateCreation;

  Tache({
    required this.id,
    required this.titre,
    this.description,
    required this.estCompletee,
    this.sousTaches,
    this.checklist,
    required this.dateCreation,
  });
}