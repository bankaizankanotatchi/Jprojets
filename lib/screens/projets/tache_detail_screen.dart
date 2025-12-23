import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/models/tache.dart';
import 'package:jprojets/models/sous_tache.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/widgets/checklist_widget.dart';
import 'package:jprojets/widgets/link_actions_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class TacheDetailScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String projetId;
  final String tacheId;

  const TacheDetailScreen({
    Key? key,
    required this.databaseService,
    required this.projetId,
    required this.tacheId,
  }) : super(key: key);

  @override
  _TacheDetailScreenState createState() => _TacheDetailScreenState();
}

class _TacheDetailScreenState extends State<TacheDetailScreen> {
  late Projet? _projet;
  late Tache? _tache;
  final TextEditingController _sousTacheController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    setState(() {
      _projet = widget.databaseService.getProjetParId(widget.projetId);
      if (_projet != null) {
        _tache = _projet!.taches.firstWhere(
          (t) => t.id == widget.tacheId,
          orElse: () => Tache(
            id: '',
            titre: '',
            estCompletee: false,
            dateCreation: DateTime.now(),
          ),
        );
        if (_tache != null) {
          _descriptionController.text = _tache!.description ?? '';
        }
      }
    });
  }

  Future<void> _modifierTitreTache() async {
    if (_tache == null) return;

    final newTitleController = TextEditingController(text: _tache!.titre);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le titre'),
        content: TextField(
          controller: newTitleController,
          decoration: const InputDecoration(
            hintText: 'Nouveau titre de la tâche',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, newTitleController.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await widget.databaseService.updateTache(
          projetId: widget.projetId,
          tacheId: widget.tacheId,
          titre: result,
        );
        _chargerDonnees();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _modifierTitreSousTache(String sousTacheId) async {
    if (_tache == null) return;

    final sousTache = _tache!.sousTaches?.firstWhere(
      (st) => st.id == sousTacheId,
      orElse: () => SousTache(
        id: '',
        titre: '',
        estCompletee: false,
        dateCreation: DateTime.now(),
      ),
    );

    if (sousTache!.id.isEmpty) return;

    final newTitleController = TextEditingController(text: sousTache.titre);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le titre'),
        content: TextField(
          controller: newTitleController,
          decoration: const InputDecoration(
            hintText: 'Nouveau titre de la sous-tâche',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, newTitleController.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await widget.databaseService.updateSousTache(
          projetId: widget.projetId,
          tacheId: widget.tacheId,
          sousTacheId: sousTacheId,
          titre: result,
        );
        _chargerDonnees();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTacheCompletee() async {
    if (_tache == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.databaseService.updateTache(
        projetId: widget.projetId,
        tacheId: widget.tacheId,
        estCompletee: !_tache!.estCompletee,
      );
      _chargerDonnees();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterSousTache() async {
    if (_sousTacheController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await widget.databaseService.ajouterSousTache(
        projetId: widget.projetId,
        tacheId: widget.tacheId,
        titre: _sousTacheController.text.trim(),
      );
      _sousTacheController.clear();
      _chargerDonnees();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSousTacheCompletee(String sousTacheId) async {
    if (_tache == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.databaseService.toggleSousTacheCompletee(
        widget.projetId,
        widget.tacheId,
        sousTacheId,
      );
      _chargerDonnees();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _supprimerSousTache(String sousTacheId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la sous-tâche'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette sous-tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await widget.databaseService.supprimerSousTache(
          widget.projetId,
          widget.tacheId,
          sousTacheId,
        );
        _chargerDonnees();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mettreAJourChecklist(List<String> items) async {
    setState(() => _isLoading = true);
    try {
      await widget.databaseService.updateTache(
        projetId: widget.projetId,
        tacheId: widget.tacheId,
        checklist: items,
      );
      _chargerDonnees();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sauvegarderDescription() async {
    if (_tache == null) return;

    setState(() => _isLoading = true);
    try {
      await widget.databaseService.updateTache(
        projetId: widget.projetId,
        tacheId: widget.tacheId,
        description: _descriptionController.text.trim(),
      );
      _chargerDonnees();
      setState(() => _isEditingDescription = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _annulerEditionDescription() {
    setState(() {
      _descriptionController.text = _tache?.description ?? '';
      _isEditingDescription = false;
    });
  }




Widget _buildDescriptionAvecLiens(String description) {
  return Linkify(
    onOpen: (link) => _showLinkOptions(context, link.url),
    text: description,
    style: TextStyle(
      fontSize: 14,
      color: Colors.grey[700],
    ),
    linkStyle: TextStyle(
      fontSize: 14,
      color: AppTheme.primary,
      decoration: TextDecoration.underline,
    ),
  );
}

// REMPLACEZ cette méthode par :
void _showLinkOptions(BuildContext context, String url) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LinkActionsBottomSheet(
      url: url,
      linkTitle: 'Lien dans la tâche',
    ),
  );
}


 void _demanderEditionDescription() {
    setState(() => _isEditingDescription = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_tache == null || _projet == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.primary,
          title: const Text('Tâche non trouvée', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('La tâche n\'existe pas'),
        ),
      );
    }

    final sousTachesCompletees = _tache!.sousTaches?.where((st) => st.estCompletee).length ?? 0;
    final totalSousTaches = _tache!.sousTaches?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // CHANGEMENT : Utiliser Column au lieu de CustomScrollView
      body: Column(
        children: [
          // AppBar fixe
          Container(
            height: MediaQuery.of(context).padding.top + 100, // Inclut la barre de statut
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Fond qui s'étend sous la barre de statut
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenu de l'AppBar
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Première ligne : Bouton retour et actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton retour
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            
                            // Titre et sous-titre
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _tache!.titre,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 20,
                                          ),
                                          onPressed: _modifierTitreTache,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Modifier le titre',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _projet!.titre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Bouton toggle statut
                            if (_isLoading)
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _tache!.estCompletee ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: _toggleTacheCompletee,
                                tooltip: _tache!.estCompletee ? 'Marquer comme incomplète' : 'Marquer comme complète',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statut
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _tache!.estCompletee
                                ? AppTheme.statusTermine.withOpacity(0.1)
                                : AppTheme.statusEnCours.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _tache!.estCompletee
                                  ? AppTheme.statusTermine.withOpacity(0.3)
                                  : AppTheme.statusEnCours.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _tache!.estCompletee ? Icons.check_circle : Icons.play_arrow,
                                color: _tache!.estCompletee ? AppTheme.statusTermine : AppTheme.statusEnCours,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _tache!.estCompletee ? 'Complétée' : 'En cours',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _tache!.estCompletee ? AppTheme.statusTermine : AppTheme.statusEnCours,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Créée le ${_formatDate(_tache!.dateCreation)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Description
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (!_isEditingDescription && (_tache!.description?.isNotEmpty ?? false))
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            onPressed: _demanderEditionDescription,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Modifier la description',
                          ),
                      ],
                    ),
                  ),

                  if (_isEditingDescription)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _descriptionController,
                            maxLines: 5,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Description de la tâche...',
                              helperText: 'Vous pouvez inclure des liens (http://...)',
                              helperStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _annulerEditionDescription,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _sauvegarderDescription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Sauvegarder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else if (_tache!.description != null && _tache!.description!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildDescriptionAvecLiens(_tache!.description!),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description,
                            color: Colors.grey[300],
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune description',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _demanderEditionDescription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16),
                                SizedBox(width: 8),
                                Text('Ajouter une description'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Section Sous-tâches
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sous-tâches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (totalSousTaches > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$sousTachesCompletees/$totalSousTaches',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Liste des sous-tâches
                  if (_tache!.sousTaches != null && _tache!.sousTaches!.isNotEmpty)
                    Column(
                      children: _tache!.sousTaches!.map((sousTache) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              GestureDetector(
                                onTap: () => _toggleSousTacheCompletee(sousTache.id),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: sousTache.estCompletee
                                          ? AppTheme.statusTermine
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: sousTache.estCompletee
                                        ? AppTheme.statusTermine
                                        : Colors.transparent,
                                  ),
                                  child: sousTache.estCompletee
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),

                              // Titre avec édition
                              Expanded(
                                child: InkWell(
                                  onTap: () => _modifierTitreSousTache(sousTache.id),
                                  child: Text(
                                    sousTache.titre,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: sousTache.estCompletee
                                          ? Colors.grey[500]
                                          : Colors.grey[800],
                                      decoration: sousTache.estCompletee
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ),

                              // Bouton d'édition
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                                onPressed: () => _modifierTitreSousTache(sousTache.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              // Bouton de suppression
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                  size: 18,
                                ),
                                onPressed: () => _supprimerSousTache(sousTache.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  // Ajout de sous-tâche
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _sousTacheController,
                            decoration: InputDecoration(
                              hintText: 'Ajouter une sous-tâche...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                            onSubmitted: (_) => _ajouterSousTache(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _ajouterSousTache,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ],
                  ),

                  // Checklist (optionnel - décommenter si besoin)
                  /*
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      'Checklist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ChecklistWidget(
                      items: _tache!.checklist ?? [],
                      onItemsChanged: _mettreAJourChecklist,
                      editable: true,
                    ),
                  ),
                  */

                  // Statistiques
                  if (totalSousTaches > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatCard(
                                title: 'Sous-tâches',
                                value: '$sousTachesCompletees/$totalSousTaches',
                                icon: Icons.list,
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: totalSousTaches > 0 ? sousTachesCompletees / totalSousTaches : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                sousTachesCompletees == totalSousTaches
                                    ? AppTheme.statusTermine
                                    : AppTheme.primary,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Progression des sous-tâches',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Espace en bas pour éviter les débordements
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sousTacheController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}