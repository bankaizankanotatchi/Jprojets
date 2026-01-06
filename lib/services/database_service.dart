import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/models/sous_tache.dart';
import 'package:jprojets/models/tache.dart';
import 'package:jprojets/models/user.dart';

/// Service principal pour gérer toutes les opérations de la base de données Hive
class DatabaseService {
  // Noms des boxes Hive
  static const String _userBoxName = 'userBox';
  static const String _projetBoxName = 'projetBox';
  static const String _informationBoxName = 'informationBox';

  // Références aux boxes
  late Box<User> _userBox;
  late Box<Projet> _projetBox;
  late Box<Information> _informationBox;

  // Singleton pour avoir une seule instance du service
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Initialise Hive et ouvre toutes les boxes nécessaires
  Future<void> init() async {
    // Initialise Hive avec Flutter
    await Hive.initFlutter();

    // Enregistre tous les adapters pour les models
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ProjetAdapter());
    Hive.registerAdapter(TacheAdapter());
    Hive.registerAdapter(SousTacheAdapter());
    Hive.registerAdapter(InformationAdapter());

    // Ouvre toutes les boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
    _projetBox = await Hive.openBox<Projet>(_projetBoxName);
    _informationBox = await Hive.openBox<Information>(_informationBoxName);
  }

  // ==================== GESTION UTILISATEUR ====================

  /// Connecte un utilisateur avec son nom
  Future<User> connexion(String nom) async {
    // Crée un nouvel utilisateur


    if(nom != 'Justin'){
      throw Exception("Le nom d'utilisateur est incorrect.");
    }else{

        final user = User(
      nom: nom,
      dateConnexion: DateTime.now(),
    );



    // Sauvegarde l'utilisateur (clé unique: 'current_user')
    await _userBox.put('current_user', user);
    return user;
  }
  }

  /// Récupère l'utilisateur connecté
  User? getUtilisateurConnecte() {
    return _userBox.get('current_user');
  }

  /// Vérifie si un utilisateur est connecté
  bool estConnecte() {
    return _userBox.get('current_user') != null;
  }

  /// Déconnecte l'utilisateur actuel
  Future<void> deconnexion() async {
    await _userBox.delete('current_user');
  }

  /// Met à jour le nom de l'utilisateur
  Future<void> updateNomUtilisateur(String nouveauNom) async {
    final user = getUtilisateurConnecte();
    if (user != null) {
      user.nom = nouveauNom;
      await user.save();
    }
  }

  // ==================== CRUD PROJETS ====================

  /// Crée un nouveau projet
  Future<Projet> creerProjet({
    required String titre,
    String? description,
    List<String>? images,
    String statut = 'en_attente',
  }) async {
    final projet = Projet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: titre,
      description: description,
      images: images ?? [],
      statut: statut,
      taches: [],
      dateCreation: DateTime.now(),
    );

    await _projetBox.put(projet.id, projet);
    return projet;
  }

  /// Récupère tous les projets
  List<Projet> getTousProjets() {
    return _projetBox.values.toList();
  }

  /// Récupère un projet par son ID
  Projet? getProjetParId(String id) {
    return _projetBox.get(id);
  }

  /// Met à jour un projet
  Future<void> updateProjet({
    required String id,
    String? titre,
    String? description,
    List<String>? images,
    String? statut,
    List<Tache>? taches,
  }) async {
    final projet = _projetBox.get(id);
    if (projet != null) {
      if (titre != null) projet.titre = titre;
      if (description != null) projet.description = description;
      if (images != null) projet.images = images;
      if (statut != null) projet.statut = statut;
      if (taches != null) projet.taches = taches;
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Supprime un projet
  Future<void> supprimerProjet(String id) async {
    await _projetBox.delete(id);
  }

  /// Supprime tous les projets
  Future<void> supprimerTousProjets() async {
    await _projetBox.clear();
  }

  // ==================== GESTION DES IMAGES DANS PROJETS ====================

  /// Ajoute une image à un projet
  Future<void> ajouterImageProjet(String projetId, String imagePath) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      projet.images ??= [];
      projet.images!.add(imagePath);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Supprime une image d'un projet par son index
  Future<void> supprimerImageProjet(String projetId, int imageIndex) async {
    final projet = _projetBox.get(projetId);
    if (projet != null && projet.images != null && imageIndex < projet.images!.length) {
      projet.images!.removeAt(imageIndex);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Supprime une image d'un projet par son path
  Future<void> supprimerImageProjetParPath(String projetId, String imagePath) async {
    final projet = _projetBox.get(projetId);
    if (projet != null && projet.images != null) {
      projet.images!.remove(imagePath);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Supprime toutes les images d'un projet
  Future<void> supprimerToutesImagesProjet(String projetId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      projet.images = [];
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  // ==================== GESTION DES TÂCHES ====================

  /// Ajoute une tâche à un projet
  Future<void> ajouterTache({
    required String projetId,
    required String titre,
    String? description,
    List<SousTache>? sousTaches,
    List<String>? checklist,
  }) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tache = Tache(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: titre,
        description: description,
        estCompletee: false,
        sousTaches: sousTaches ?? [],
        checklist: checklist ?? [],
        dateCreation: DateTime.now(),
      );
      projet.taches.add(tache);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Met à jour une tâche
  Future<void> updateTache({
    required String projetId,
    required String tacheId,
    String? titre,
    String? description,
    bool? estCompletee,
    List<SousTache>? sousTaches,
    List<String>? checklist,
  }) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        final tache = projet.taches[tacheIndex];
        if (titre != null) tache.titre = titre;
        if (description != null) tache.description = description;
        if (estCompletee != null) tache.estCompletee = estCompletee;
        if (sousTaches != null) tache.sousTaches = sousTaches;
        if (checklist != null) tache.checklist = checklist;
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Supprime une tâche d'un projet
  Future<void> supprimerTache(String projetId, String tacheId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      projet.taches.removeWhere((t) => t.id == tacheId);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Marque une tâche comme complétée ou non
  Future<void> toggleTacheCompletee(String projetId, String tacheId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        projet.taches[tacheIndex].estCompletee = !projet.taches[tacheIndex].estCompletee;
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Supprime toutes les tâches d'un projet
  Future<void> supprimerToutesLesTaches(String projetId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      projet.taches.clear();
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  // ==================== GESTION DES SOUS-TÂCHES ====================

  /// Ajoute une sous-tâche à une tâche
  Future<void> ajouterSousTache({
    required String projetId,
    required String tacheId,
    required String titre,
  }) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        final sousTache = SousTache(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: titre,
          estCompletee: false,
          dateCreation: DateTime.now(),
        );
        projet.taches[tacheIndex].sousTaches ??= [];
        projet.taches[tacheIndex].sousTaches!.add(sousTache);
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Met à jour une sous-tâche
  Future<void> updateSousTache({
    required String projetId,
    required String tacheId,
    required String sousTacheId,
    String? titre,
    bool? estCompletee,
  }) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1 && projet.taches[tacheIndex].sousTaches != null) {
        final sousTacheIndex = projet.taches[tacheIndex].sousTaches!.indexWhere((st) => st.id == sousTacheId);
        if (sousTacheIndex != -1) {
          final sousTache = projet.taches[tacheIndex].sousTaches![sousTacheIndex];
          if (titre != null) sousTache.titre = titre;
          if (estCompletee != null) sousTache.estCompletee = estCompletee;
          projet.dateModification = DateTime.now();
          await projet.save();
        }
      }
    }
  }

// ==================== GESTION DES SOUS-TÂCHES ====================

/// Supprime une sous-tâche
Future<void> supprimerSousTache(String projetId, String tacheId, String sousTacheId) async {
  final projet = _projetBox.get(projetId);
  if (projet != null) {
    final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
    if (tacheIndex != -1 && projet.taches[tacheIndex].sousTaches != null) {
      projet.taches[tacheIndex].sousTaches!.removeWhere((st) => st.id == sousTacheId);
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }
}

/// Marque une sous-tâche comme complétée ou non
Future<void> toggleSousTacheCompletee(String projetId, String tacheId, String sousTacheId) async {
  final projet = _projetBox.get(projetId);
  if (projet != null) {
    final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
    if (tacheIndex != -1 && projet.taches[tacheIndex].sousTaches != null) {
      final sousTacheIndex = projet.taches[tacheIndex].sousTaches!.indexWhere((st) => st.id == sousTacheId);
      if (sousTacheIndex != -1) {
        projet.taches[tacheIndex].sousTaches![sousTacheIndex].estCompletee = 
            !projet.taches[tacheIndex].sousTaches![sousTacheIndex].estCompletee;
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }
}

  /// Supprime toutes les sous-tâches d'une tâche
  Future<void> supprimerToutesLesSousTaches(String projetId, String tacheId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        projet.taches[tacheIndex].sousTaches = [];
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  // ==================== GESTION DES CHECKLISTS ====================

  /// Ajoute un item à la checklist d'une tâche
  Future<void> ajouterItemChecklist(String projetId, String tacheId, String item) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        projet.taches[tacheIndex].checklist ??= [];
        projet.taches[tacheIndex].checklist!.add(item);
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Met à jour un item de checklist
  Future<void> updateItemChecklist(String projetId, String tacheId, int itemIndex, String nouveauItem) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1 && 
          projet.taches[tacheIndex].checklist != null && 
          itemIndex < projet.taches[tacheIndex].checklist!.length) {
        projet.taches[tacheIndex].checklist![itemIndex] = nouveauItem;
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Supprime un item de checklist par son index
  Future<void> supprimerItemChecklist(String projetId, String tacheId, int itemIndex) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1 && 
          projet.taches[tacheIndex].checklist != null && 
          itemIndex < projet.taches[tacheIndex].checklist!.length) {
        projet.taches[tacheIndex].checklist!.removeAt(itemIndex);
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  /// Supprime toute la checklist d'une tâche
  Future<void> supprimerTouteChecklist(String projetId, String tacheId) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      final tacheIndex = projet.taches.indexWhere((t) => t.id == tacheId);
      if (tacheIndex != -1) {
        projet.taches[tacheIndex].checklist = [];
        projet.dateModification = DateTime.now();
        await projet.save();
      }
    }
  }

  // ==================== GESTION DES STATUTS DE PROJETS ====================

  /// Change le statut d'un projet
  Future<void> changerStatutProjet(String projetId, String nouveauStatut) async {
    final projet = _projetBox.get(projetId);
    if (projet != null) {
      projet.statut = nouveauStatut;
      projet.dateModification = DateTime.now();
      await projet.save();
    }
  }

  /// Récupère les projets par statut
  List<Projet> getProjetsParStatut(String statut) {
    return _projetBox.values.where((p) => p.statut == statut).toList();
  }

  // ==================== CRUD INFORMATIONS ====================

  /// Crée une nouvelle information
  Future<Information> creerInformation({
    required String titre,
    required List<String> points,
    List<String>? images,
  }) async {
    final info = Information(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: titre,
      points: points,
      images: images ?? [],
      dateCreation: DateTime.now(),
    );

    await _informationBox.put(info.id, info);
    return info;
  }

  /// Récupère toutes les informations
  List<Information> getToutesInformations() {
    return _informationBox.values.toList();
  }

  /// Récupère une information par son ID
  Information? getInformationParId(String id) {
    return _informationBox.get(id);
  }

  /// Met à jour une information
  Future<void> updateInformation({
    required String id,
    String? titre,
    List<String>? points,
    List<String>? images,
  }) async {
    final info = _informationBox.get(id);
    if (info != null) {
      if (titre != null) info.titre = titre;
      if (points != null) info.points = points;
      if (images != null) info.images = images;
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime une information
  Future<void> supprimerInformation(String id) async {
    await _informationBox.delete(id);
  }

  /// Supprime toutes les informations
  Future<void> supprimerToutesInformations() async {
    await _informationBox.clear();
  }

  // ==================== GESTION DES POINTS D'INFORMATION ====================

  /// Ajoute un point à une information
  Future<void> ajouterPointInformation(String infoId, String point) async {
    final info = _informationBox.get(infoId);
    if (info != null) {
      info.points.add(point);
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Met à jour un point d'information
  Future<void> updatePointInformation(String infoId, int pointIndex, String nouveauPoint) async {
    final info = _informationBox.get(infoId);
    if (info != null && pointIndex < info.points.length) {
      info.points[pointIndex] = nouveauPoint;
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime un point d'information par son index
  Future<void> supprimerPointInformation(String infoId, int pointIndex) async {
    final info = _informationBox.get(infoId);
    if (info != null && pointIndex < info.points.length) {
      info.points.removeAt(pointIndex);
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime tous les points d'une information
  Future<void> supprimerTousLesPoints(String infoId) async {
    final info = _informationBox.get(infoId);
    if (info != null) {
      info.points.clear();
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  // ==================== GESTION DES IMAGES DANS INFORMATIONS ====================

  /// Ajoute une image à une information
  Future<void> ajouterImageInformation(String infoId, String imagePath) async {
    final info = _informationBox.get(infoId);
    if (info != null) {
      info.images ??= [];
      info.images!.add(imagePath);
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime une image d'une information par son index
  Future<void> supprimerImageInformation(String infoId, int imageIndex) async {
    final info = _informationBox.get(infoId);
    if (info != null && info.images != null && imageIndex < info.images!.length) {
      info.images!.removeAt(imageIndex);
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime une image d'une information par son path
  Future<void> supprimerImageInformationParPath(String infoId, String imagePath) async {
    final info = _informationBox.get(infoId);
    if (info != null && info.images != null) {
      info.images!.remove(imagePath);
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  /// Supprime toutes les images d'une information
  Future<void> supprimerToutesImagesInformation(String infoId) async {
    final info = _informationBox.get(infoId);
    if (info != null) {
      info.images = [];
      info.dateModification = DateTime.now();
      await info.save();
    }
  }

  // ==================== RECHERCHE HYPERPUISSANTE - PROJETS ====================

  /// Recherche des projets avec options avancées
  List<Projet> rechercherProjets({
    String? motCle,
    String? statut,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? avecImages,
    bool? avecDescription,
    bool? avecTaches,
    int? nombreMinTaches,
    int? nombreMaxTaches,
    bool? tachesCompletes,
    bool? tachesIncompletes,
    String? triPar, // 'date_creation', 'date_modification', 'titre', 'nombre_taches'
    bool? ordreDecroissant,
  }) {
    var resultats = _projetBox.values.toList();

    // Filtre par mot-clé (recherche dans titre, description, tâches)
    if (motCle != null && motCle.isNotEmpty) {
      final motCleMin = motCle.toLowerCase();
      resultats = resultats.where((p) {
        // Recherche dans le titre
        if (p.titre.toLowerCase().contains(motCleMin)) return true;
        
        // Recherche dans la description
        if (p.description != null && p.description!.toLowerCase().contains(motCleMin)) return true;
        
        // Recherche dans les tâches
        for (var tache in p.taches) {
          if (tache.titre.toLowerCase().contains(motCleMin)) return true;
          if (tache.description != null && tache.description!.toLowerCase().contains(motCleMin)) return true;
          
          // Recherche dans les sous-tâches
          if (tache.sousTaches != null) {
            for (var sousTache in tache.sousTaches!) {
              if (sousTache.titre.toLowerCase().contains(motCleMin)) return true;
            }
          }
          
          // Recherche dans la checklist
          if (tache.checklist != null) {
            for (var item in tache.checklist!) {
              if (item.toLowerCase().contains(motCleMin)) return true;
            }
          }
        }
        
        return false;
      }).toList();
    }

    // Filtre par statut
    if (statut != null) {
      resultats = resultats.where((p) => p.statut == statut).toList();
    }

    // Filtre par plage de dates
    if (dateDebut != null) {
      resultats = resultats.where((p) => p.dateCreation.isAfter(dateDebut) || p.dateCreation.isAtSameMomentAs(dateDebut)).toList();
    }
    if (dateFin != null) {
      resultats = resultats.where((p) => p.dateCreation.isBefore(dateFin) || p.dateCreation.isAtSameMomentAs(dateFin)).toList();
    }

    // Filtre par présence d'images
    if (avecImages != null) {
      if (avecImages) {
        resultats = resultats.where((p) => p.images != null && p.images!.isNotEmpty).toList();
      } else {
        resultats = resultats.where((p) => p.images == null || p.images!.isEmpty).toList();
      }
    }

    // Filtre par présence de description
    if (avecDescription != null) {
      if (avecDescription) {
        resultats = resultats.where((p) => p.description != null && p.description!.isNotEmpty).toList();
      } else {
        resultats = resultats.where((p) => p.description == null || p.description!.isEmpty).toList();
      }
    }

    // Filtre par présence de tâches
    if (avecTaches != null) {
      if (avecTaches) {
        resultats = resultats.where((p) => p.taches.isNotEmpty).toList();
      } else {
        resultats = resultats.where((p) => p.taches.isEmpty).toList();
      }
    }

    // Filtre par nombre de tâches
    if (nombreMinTaches != null) {
      resultats = resultats.where((p) => p.taches.length >= nombreMinTaches).toList();
    }
    if (nombreMaxTaches != null) {
      resultats = resultats.where((p) => p.taches.length <= nombreMaxTaches).toList();
    }

    // Filtre par tâches complètes/incomplètes
    if (tachesCompletes == true) {
      resultats = resultats.where((p) => p.taches.any((t) => t.estCompletee)).toList();
    }
    if (tachesIncompletes == true) {
      resultats = resultats.where((p) => p.taches.any((t) => !t.estCompletee)).toList();
    }

    // Tri des résultats
    if (triPar != null) {
      switch (triPar) {
        case 'date_creation':
          resultats.sort((a, b) => a.dateCreation.compareTo(b.dateCreation));
          break;
        case 'date_modification':
          resultats.sort((a, b) {
            final dateA = a.dateModification ?? a.dateCreation;
            final dateB = b.dateModification ?? b.dateCreation;
            return dateA.compareTo(dateB);
          });
          break;
        case 'titre':
          resultats.sort((a, b) => a.titre.toLowerCase().compareTo(b.titre.toLowerCase()));
          break;
        case 'nombre_taches':
          resultats.sort((a, b) => a.taches.length.compareTo(b.taches.length));
          break;
      }

      // Inverse l'ordre si demandé
      if (ordreDecroissant == true) {
        resultats = resultats.reversed.toList();
      }
    }

    return resultats;
  }

  // ==================== RECHERCHE HYPERPUISSANTE - INFORMATIONS ====================

  /// Recherche des informations avec options avancées
  List<Information> rechercherInformations({
    String? motCle,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? avecImages,
    int? nombreMinPoints,
    int? nombreMaxPoints,
    String? triPar, // 'date_creation', 'date_modification', 'titre', 'nombre_points'
    bool? ordreDecroissant,
  }) {
    var resultats = _informationBox.values.toList();

    // Filtre par mot-clé (recherche dans titre et points)
    if (motCle != null && motCle.isNotEmpty) {
      final motCleMin = motCle.toLowerCase();
      resultats = resultats.where((info) {
        // Recherche dans le titre
        if (info.titre.toLowerCase().contains(motCleMin)) return true;
        
        // Recherche dans tous les points
        for (var point in info.points) {
          if (point.toLowerCase().contains(motCleMin)) return true;
        }
        
        return false;
      }).toList();
    }

    // Filtre par plage de dates
    if (dateDebut != null) {
      resultats = resultats.where((info) => info.dateCreation.isAfter(dateDebut) || info.dateCreation.isAtSameMomentAs(dateDebut)).toList();
    }
    if (dateFin != null) {
      resultats = resultats.where((info) => info.dateCreation.isBefore(dateFin) || info.dateCreation.isAtSameMomentAs(dateFin)).toList();
    }

    // Filtre par présence d'images
    if (avecImages != null) {
      if (avecImages) {
        resultats = resultats.where((info) => info.images != null && info.images!.isNotEmpty).toList();
      } else {
        resultats = resultats.where((info) => info.images == null ||info.images!.isEmpty).toList();
      }
    }

    // Filtre par nombre de points
    if (nombreMinPoints != null) {
      resultats = resultats.where((info) => info.points.length >= nombreMinPoints).toList();
    }
    if (nombreMaxPoints != null) {
      resultats = resultats.where((info) => info.points.length <= nombreMaxPoints).toList();
    }

    // Tri des résultats
    if (triPar != null) {
      switch (triPar) {
        case 'date_creation':
          resultats.sort((a, b) => a.dateCreation.compareTo(b.dateCreation));
          break;
        case 'date_modification':
          resultats.sort((a, b) {
            final dateA = a.dateModification ?? a.dateCreation;
            final dateB = b.dateModification ?? b.dateCreation;
            return dateA.compareTo(dateB);
          });
          break;
        case 'titre':
          resultats.sort((a, b) => a.titre.toLowerCase().compareTo(b.titre.toLowerCase()));
          break;
        case 'nombre_points':
          resultats.sort((a, b) => a.points.length.compareTo(b.points.length));
          break;
      }

      // Inverse l'ordre si demandé
      if (ordreDecroissant == true) {
        resultats = resultats.reversed.toList();
      }
    }

    return resultats;
  }

    // ==================== KPIs - STATISTIQUES PROJETS ====================
    /// Compte le nombre total de projets
    int getNombreTotalProjets() {
      return _projetBox.length;
    }
    /// Compte les projets en attente
    int getNombreProjetsEnAttente() {
      return _projetBox.values.where((p) => p.statut == 'en_attente').length;
    }
    /// Compte les projets en cours
    int getNombreProjetsEnCours() {
      return _projetBox.values.where((p) => p.statut == 'en_cours').length;
    }
    /// Compte les projets terminés
    int getNombreProjetsTermines() {
      return _projetBox.values.where((p) => p.statut == 'termine').length;
    }
    /// Compte le nombre total de tâches dans tous les projets
    int getNombreTotalTaches() {
    int total = 0;

    for (var projet in _projetBox.values) {
      total += projet.taches.length;
    }
    return total;
    }
    /// Compte le nombre de tâches complétées dans tous les projets
    int getNombreTachesCompletees() {
    int total = 0;
    for (var projet in _projetBox.values) {
      total += projet.taches.where((t) => t.estCompletee).length;
    }
    
    return total;
  }

  // ==================== KPIs - STATISTIQUES INFORMATIONS ====================
  /// Compte le nombre total d'informations
  int getNombreTotalInformations() {
    return _informationBox.length;
  }
  /// Compte les informations créées aujourd'hui
  int getNombreInformationsAujourdhui() {
    final aujourdhui = DateTime.now();

    return _informationBox.values.where((info) {
      return info.dateCreation.year == aujourdhui.year &&
      info.dateCreation.month == aujourdhui.month &&
      info.dateCreation.day == aujourdhui.day;
    }).length;
  }

  /// Compte les informations créées cette semaine
  int getNombreInformationsCetteSemaine() {
    final maintenant = DateTime.now();
    final debutSemaine = maintenant.subtract(Duration(days: maintenant.weekday - 1));
    final debutSemaineMinuit = DateTime(debutSemaine.year, debutSemaine.month, debutSemaine.day);

    return _informationBox.values.where((info) {
      return info.dateCreation.isAfter(debutSemaineMinuit) || info.dateCreation.isAtSameMomentAs(debutSemaineMinuit);
    }).length;
  }

  /// Compte les informations créées ce mois
  int getNombreInformationsCeMois() {
    final maintenant = DateTime.now();

    return _informationBox.values.where((info) {
      return info.dateCreation.year == maintenant.year &&
      info.dateCreation.month == maintenant.month;
    }).length;
  }
    /// Récupère les informations par période (jour, semaine, mois)
    Map<String, int> getStatistiquesInformationsParPeriode() {
      return {
      'aujourdhui': getNombreInformationsAujourdhui(),
      'cette_semaine': getNombreInformationsCetteSemaine(),
      'ce_mois': getNombreInformationsCeMois(),
      'total': getNombreTotalInformations(),
      };
    }
    /// Récupère toutes les statistiques des projets
    Map<String, int> getStatistiquesProjets() {
      return {
      'total': getNombreTotalProjets(),
      'en_attente': getNombreProjetsEnAttente(),
      'en_cours': getNombreProjetsEnCours(),
      'termines': getNombreProjetsTermines(),
      'total_taches': getNombreTotalTaches(),
      'taches_completees': getNombreTachesCompletees(),
      };
    }
  // ==================== UTILITAIRES ====================
  /// Ferme toutes les boxes Hive
  Future<void> fermerTout() async {
    await _userBox.close();
    await _projetBox.close();
    await _informationBox.close();
  }

  /// Exporte toutes les données sous forme de Map (pour backup)
  Map<String, dynamic> exporterDonnees() {
    return {
      'user': _userBox.get('current_user')?.nom,
      'projets': _projetBox.values.map((p) => {
        'id': p.id,
        'titre': p.titre,
        'description': p.description,
        'statut': p.statut,
        'images': p.images,
        'dateCreation': p.dateCreation.toIso8601String(),
        'dateModification': p.dateModification?.toIso8601String(),
          'taches': p.taches.map((t) => {
          'id': t.id,
          'titre': t.titre,
          'description': t.description,
          'estCompletee': t.estCompletee,
          'dateCreation': t.dateCreation.toIso8601String(),
            'sousTaches': t.sousTaches?.map((st) => {
            'id': st.id,
            'titre': st.titre,
            'estCompletee': st.estCompletee,
            }).toList(),
            'checklist': t.checklist,
          }).toList(),
      }).toList(),
      'informations': _informationBox.values.map((info) => {
        'id': info.id,
        'titre': info.titre,
        'points': info.points,
        'images': info.images,
        'dateCreation': info.dateCreation.toIso8601String(),
        'dateModification': info.dateModification?.toIso8601String(),
      }).toList(),
    };
  }

  // ==================== EXPORT/IMPORT PROJETS ====================

/// Exporte tous les projets en format JSON
Future<String> exporterProjetsEnJson() async {
  final projets = getTousProjets();
  final List<Map<String, dynamic>> projetsData = [];
  
  for (final projet in projets) {
    projetsData.add(_projetToMap(projet));
  }
  
  return jsonEncode({
    'type': 'jprojets_export',
    'version': '1.0',
    'date_export': DateTime.now().toIso8601String(),
    'nombre_projets': projetsData.length,
    'projets': projetsData,
  });
}

/// Exporte un projet spécifique en JSON
Future<String> exporterProjetEnJson(String projetId) async {
  final projet = getProjetParId(projetId);
  if (projet == null) {
    throw Exception('Projet non trouvé');
  }
  
  return jsonEncode({
    'type': 'jprojets_projet',
    'version': '1.0',
    'date_export': DateTime.now().toIso8601String(),
    'projet': _projetToMap(projet),
  });
}

/// Importe des projets depuis un JSON
Future<List<Projet>> importerProjetsDepuisJson(String jsonData) async {
  final data = jsonDecode(jsonData);
  
  // Validation basique
  if (data['type'] != 'jprojets_export' && data['type'] != 'jprojets_projet') {
    throw Exception('Format JSON invalide pour JProjets');
  }
  
  final List<Projet> projetsImportes = [];
  
  if (data['type'] == 'jprojets_export') {
    // Import multiple
    final projetsList = data['projets'] as List;
    for (final projetData in projetsList) {
      final projet = await _creerProjetDepuisMap(projetData);
      projetsImportes.add(projet);
    }
  } else {
    // Import unique
    final projetData = data['projet'];
    final projet = await _creerProjetDepuisMap(projetData);
    projetsImportes.add(projet);
  }
  
  return projetsImportes;
}

// ==================== EXPORT/IMPORT INFORMATIONS ====================

/// Exporte toutes les informations en format JSON
Future<String> exporterInformationsEnJson() async {
  final informations = getToutesInformations();
  final List<Map<String, dynamic>> infosData = [];
  
  for (final info in informations) {
    infosData.add(_informationToMap(info));
  }
  
  return jsonEncode({
    'type': 'jprojets_infos_export',
    'version': '1.0',
    'date_export': DateTime.now().toIso8601String(),
    'nombre_informations': infosData.length,
    'informations': infosData,
  });
}

/// Exporte une information spécifique en JSON
Future<String> exporterInformationEnJson(String infoId) async {
  final info = getInformationParId(infoId);
  if (info == null) {
    throw Exception('Information non trouvée');
  }
  
  return jsonEncode({
    'type': 'jprojets_information',
    'version': '1.0',
    'date_export': DateTime.now().toIso8601String(),
    'information': _informationToMap(info),
  });
}

/// Importe des informations depuis un JSON
Future<List<Information>> importerInformationsDepuisJson(String jsonData) async {
  final data = jsonDecode(jsonData);
  
  if (data['type'] != 'jprojets_infos_export' && data['type'] != 'jprojets_information') {
    throw Exception('Format JSON invalide pour JProjets Informations');
  }
  
  final List<Information> infosImportees = [];
  
  if (data['type'] == 'jprojets_infos_export') {
    final infosList = data['informations'] as List;
    for (final infoData in infosList) {
      final info = await _creerInformationDepuisMap(infoData);
      infosImportees.add(info);
    }
  } else {
    final infoData = data['information'];
    final info = await _creerInformationDepuisMap(infoData);
    infosImportees.add(info);
  }
  
  return infosImportees;
}

// ==================== EXPORT/IMPORT COMPLET ====================

/// Exporte TOUTES les données de l'application
Future<String> exporterToutesDonneesEnJson() async {
  final projetsJson = await exporterProjetsEnJson();
  final infosJson = await exporterInformationsEnJson();
  
  final projetsData = jsonDecode(projetsJson);
  final infosData = jsonDecode(infosJson);
  
  return jsonEncode({
    'type': 'jprojets_complet_export',
    'version': '1.0',
    'date_export': DateTime.now().toIso8601String(),
    'utilisateur': getUtilisateurConnecte()?.nom,
    'projets': projetsData['projets'],
    'informations': infosData['informations'],
    'statistiques': {
      'projets': getStatistiquesProjets(),
      'informations': getStatistiquesInformationsParPeriode(),
    },
  });
}

/// Importe toutes les données depuis un JSON complet
Future<Map<String, dynamic>> importerToutesDonneesDepuisJson(String jsonData) async {
  final data = jsonDecode(jsonData);
  
  if (data['type'] != 'jprojets_complet_export') {
    throw Exception('Format JSON invalide pour export complet');
  }
  
  final result = {
    'projets': <Projet>[],
    'informations': <Information>[],
  };
  
  // Import des projets
  if (data['projets'] != null) {
    for (final projetData in data['projets'] as List) {
      final projet = await _creerProjetDepuisMap(projetData);
      result['projets']!.add(projet);
    }
  }
  
  // Import des informations
  if (data['informations'] != null) {
    for (final infoData in data['informations'] as List) {
      final info = await _creerInformationDepuisMap(infoData);
      result['informations']!.add(info);
    }
  }
  
  return result;
}

// ==================== METHODES PRIVEES D'AIDE ====================

/// Convertit un projet en Map pour JSON
Map<String, dynamic> _projetToMap(Projet projet) {
  return {
    'id': projet.id,
    'titre': projet.titre,
    'description': projet.description,
    'statut': projet.statut,
    'images': projet.images,
    'taches': projet.taches.map((tache) => _tacheToMap(tache)).toList(),
    'dateCreation': projet.dateCreation.toIso8601String(),
    'dateModification': projet.dateModification?.toIso8601String(),
  };
}

/// Convertit une tâche en Map pour JSON
Map<String, dynamic> _tacheToMap(Tache tache) {
  return {
    'id': tache.id,
    'titre': tache.titre,
    'description': tache.description,
    'estCompletee': tache.estCompletee,
    'sousTaches': tache.sousTaches?.map((st) => _sousTacheToMap(st)).toList(),
    'checklist': tache.checklist,
    'dateCreation': tache.dateCreation.toIso8601String(),
  };
}

/// Convertit une sous-tâche en Map pour JSON
Map<String, dynamic> _sousTacheToMap(SousTache sousTache) {
  return {
    'id': sousTache.id,
    'titre': sousTache.titre,
    'estCompletee': sousTache.estCompletee,
    'dateCreation': sousTache.dateCreation.toIso8601String(),
  };
}

/// Convertit une information en Map pour JSON
Map<String, dynamic> _informationToMap(Information info) {
  return {
    'id': info.id,
    'titre': info.titre,
    'points': info.points,
    'images': info.images,
    'dateCreation': info.dateCreation.toIso8601String(),
    'dateModification': info.dateModification?.toIso8601String(),
  };
}

/// Crée un projet depuis une Map (import)
Future<Projet> _creerProjetDepuisMap(Map<String, dynamic> data) async {
  // Si le projet existe déjà, on le met à jour
  final projetExistant = getProjetParId(data['id']);
  
  if (projetExistant != null) {
    // Option 1: Mettre à jour l'existant
    await updateProjet(
      id: data['id'],
      titre: data['titre'],
      description: data['description'],
      statut: data['statut'],
      images: List<String>.from(data['images'] ?? []),
    );
    return getProjetParId(data['id'])!;
  } else {
    // Option 2: Créer un nouveau avec un ID différent
    final nouveauProjet = await creerProjet(
      titre: data['titre'],
      description: data['description'],
      images: List<String>.from(data['images'] ?? []),
      statut: data['statut'],
    );
    
    // Ajouter les tâches
    if (data['taches'] != null) {
      for (final tacheData in data['taches'] as List) {
        await _ajouterTacheDepuisMap(nouveauProjet.id, tacheData);
      }
    }
    
    return nouveauProjet;
  }
}

/// Ajoute une tâche depuis une Map (import)
Future<void> _ajouterTacheDepuisMap(String projetId, Map<String, dynamic> data) async {
  await ajouterTache(
    projetId: projetId,
    titre: data['titre'],
    description: data['description'],
    sousTaches: data['sousTaches'] != null
        ? (data['sousTaches'] as List)
            .map((st) => SousTache(
                  id: st['id'],
                  titre: st['titre'],
                  estCompletee: st['estCompletee'],
                  dateCreation: DateTime.parse(st['dateCreation']),
                ))
            .toList()
        : null,
    checklist: List<String>.from(data['checklist'] ?? []),
  );
}

/// Crée une information depuis une Map (import)
Future<Information> _creerInformationDepuisMap(Map<String, dynamic> data) async {
  final infoExistant = getInformationParId(data['id']);
  
  if (infoExistant != null) {
    await updateInformation(
      id: data['id'],
      titre: data['titre'],
      points: List<String>.from(data['points']),
      images: List<String>.from(data['images'] ?? []),
    );
    return getInformationParId(data['id'])!;
  } else {
    return await creerInformation(
      titre: data['titre'],
      points: List<String>.from(data['points']),
      images: List<String>.from(data['images'] ?? []),
    );
  }
}

}