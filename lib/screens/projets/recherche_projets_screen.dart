import 'package:flutter/material.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/screens/projets/detail_projet_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';

class RechercheProjetsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const RechercheProjetsScreen({
    Key? key,
    required this.databaseService,
  }) : super(key: key);
  
  @override
  _RechercheProjetsScreenState createState() => _RechercheProjetsScreenState();
}

class _RechercheProjetsScreenState extends State<RechercheProjetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Projet> _resultats = [];
  String? _selectedStatut;
  DateTime? _selectedDateDebut;
  DateTime? _selectedDateFin;
  bool? _avecImages;
  bool? _avecTaches;
  String _triPar = 'date_creation';
  bool _ordreDecroissant = true;
  bool _isSearching = false;
  
  void _rechercher() async {
    if (_searchController.text.isEmpty && 
        _selectedStatut == null && 
        _selectedDateDebut == null && 
        _selectedDateFin == null &&
        _avecImages == null &&
        _avecTaches == null) {
      return;
    }
    
    setState(() => _isSearching = true);
    
    final resultats = await widget.databaseService.rechercherProjets(
      motCle: _searchController.text.isNotEmpty ? _searchController.text : null,
      statut: _selectedStatut,
      dateDebut: _selectedDateDebut,
      dateFin: _selectedDateFin,
      avecImages: _avecImages,
      avecTaches: _avecTaches,
      triPar: _triPar,
      ordreDecroissant: _ordreDecroissant,
    );
    
    setState(() {
      _resultats = resultats;
      _isSearching = false;
    });
  }
  
  void _reinitialiserFiltres() {
    setState(() {
      _searchController.clear();
      _selectedStatut = null;
      _selectedDateDebut = null;
      _selectedDateFin = null;
      _avecImages = null;
      _avecTaches = null;
      _triPar = 'date_creation';
      _ordreDecroissant = true;
      _resultats = [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // CHANGEMENT : Utiliser Column au lieu de CustomScrollView
      body: Column(
        children: [
          // AppBar fixe
          Container(
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
                                    Text(
                                      'Recherche avancée',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Trouvez vos projets',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Bouton réinitialiser
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.clear_all,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: _reinitialiserFiltres,
                              tooltip: 'Réinitialiser',
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
                  // Champ de recherche
                  Container(
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par mot-clé...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  _rechercher();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => _rechercher(),
                    ),
                  ),
                  
                  // Résultats
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Résultats (${_resultats.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (_isSearching)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Liste des résultats ou message vide
                  if (_resultats.isEmpty && !_isSearching)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.grey[300],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Utilisez les filtres pour affiner votre recherche',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Recherche en cours...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _resultats.map((projet) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getStatusColor(projet.statut).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(projet.statut),
                                color: _getStatusColor(projet.statut),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              projet.titre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${projet.taches.length} tâches • ${_formatDate(projet.dateCreation)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                            onTap: () => _naviguerVersDetail(projet.id),
                          ),
                        );
                      }).toList(),
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
  
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente': return AppTheme.statusEnAttente;
      case 'en_cours': return AppTheme.statusEnCours;
      case 'termine': return AppTheme.statusTermine;
      default: return AppTheme.primary;
    }
  }
  
  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'en_attente': return Icons.pending;
      case 'en_cours': return Icons.play_arrow;
      case 'termine': return Icons.check_circle;
      default: return Icons.folder;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _naviguerVersDetail(String projetId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailProjetScreen(
          databaseService: widget.databaseService,
          projetId: projetId,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}