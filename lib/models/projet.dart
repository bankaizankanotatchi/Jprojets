import 'package:hive/hive.dart';
import 'package:jprojets/models/tache.dart';

part 'projet.g.dart';

@HiveType(typeId: 1)
class Projet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titre;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<String>? images;

  @HiveField(4)
  String statut; // "en_attente", "en_cours", "termine"

  @HiveField(5)
  List<Tache> taches;

  @HiveField(6)
  DateTime dateCreation;

  @HiveField(7)
  DateTime? dateModification;

  Projet({
    required this.id,
    required this.titre,
    this.description,
    this.images,
    required this.statut,
    required this.taches,
    required this.dateCreation,
    this.dateModification,
  });
}