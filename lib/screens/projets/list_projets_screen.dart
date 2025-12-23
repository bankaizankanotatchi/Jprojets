import 'package:flutter/material.dart';
import 'package:jprojets/screens/projets/edit_projet_screen.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/screens/projets/create_projet_screen.dart';
import 'package:jprojets/screens/projets/detail_projet_screen.dart';
import 'package:jprojets/screens/projets/recherche_projets_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/widgets/projet_card.dart';

class ListProjetsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String? statutFiltre;
  
  const ListProjetsScreen({
    Key? key,
    required this.databaseService,
    this.statutFiltre,
  }) : super(key: key);
  
  @override
  _ListProjetsScreenState createState() => _ListProjetsScreenState();
}

class _ListProjetsScreenState extends State<ListProjetsScreen> with WidgetsBindingObserver {
  late List<Projet> _projets;
  String _filtreActif = 'tous';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filtreActif = widget.statutFiltre ?? 'tous';
    _chargerProjets();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chargerProjets();
    }
  }
  
  void _chargerProjets() {
    final tousProjets = widget.databaseService.getTousProjets();
    
    if (_filtreActif == 'tous') {
      setState(() {
        _projets = tousProjets;
      });
    } else {
      setState(() {
        _projets = tousProjets.where((p) => p.statut == _filtreActif).toList();
      });
    }
  }
  
  void _changerFiltre(String filtre) {
    setState(() {
      _filtreActif = filtre;
    });
    _chargerProjets();
  }
  
  Future<void> _supprimerProjet(String projetId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.'),
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
      await widget.databaseService.supprimerProjet(projetId);
      _chargerProjets();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Projet supprimé avec succès'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _changerStatutProjet(String projetId, String nouveauStatut) async {
    await widget.databaseService.changerStatutProjet(projetId, nouveauStatut);
    _chargerProjets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut changé en $nouveauStatut'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // AppBar fixe
          Container(
            height: 120,
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
                
                SafeArea(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mes Projets',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_projets.length} projets',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: () async {
                                // Utiliser await pour attendre le retour de la navigation
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RechercheProjetsScreen(
                                      databaseService: widget.databaseService,
                                    ),
                                  ),
                                );
                                // Rafraîchir après retour
                                _chargerProjets();
                              },
                              tooltip: 'Recherche avancée',
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
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtres horizontaux avec scroll
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFiltreButton('tous', 'Tous', Icons.all_inclusive),
                        const SizedBox(width: 8),
                        _buildFiltreButton('en_attente', 'En attente', Icons.pending),
                        const SizedBox(width: 8),
                        _buildFiltreButton('en_cours', 'En cours', Icons.play_arrow),
                        const SizedBox(width: 8),
                        _buildFiltreButton('termine', 'Terminés', Icons.check_circle),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_projets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            color: Colors.grey[300],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun projet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par créer votre premier projet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              // Utiliser await pour attendre le retour de la création
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateProjetScreen(
                                    databaseService: widget.databaseService,
                                  ),
                                ),
                              );
                              // Rafraîchir après retour
                              _chargerProjets();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Créer un projet'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _projets.map((projet) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ProjetCard(
                            projet: projet,
                            onTap: () async {
                              await _naviguerVersDetail(projet.id);
                              _chargerProjets();
                            },
                            onEdit: () async {
                              await _naviguerVersEdition(projet.id);
                              _chargerProjets();
                            },
                            onDelete: () => _supprimerProjet(projet.id),
                            onChangeStatus: (nouveauStatut) =>
                                _changerStatutProjet(projet.id, nouveauStatut),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: () async {
            // Utiliser await pour attendre le retour de la création
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateProjetScreen(
                  databaseService: widget.databaseService,
                ),
              ),
            );
            // Rafraîchir après retour
            _chargerProjets();
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildFiltreButton(String filtre, String texte, IconData icone) {
    final estActif = _filtreActif == filtre;
    
    return ElevatedButton(
      onPressed: () => _changerFiltre(filtre),
      style: ElevatedButton.styleFrom(
        backgroundColor: estActif ? _getStatusColor(filtre) : Colors.white,
        foregroundColor: estActif ? Colors.white : Colors.grey[700],
        elevation: estActif ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: estActif ? _getStatusColor(filtre) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icone, size: 16),
          const SizedBox(width: 8),
          Text(
            texte,
            style: TextStyle(
              fontSize: 14,
              fontWeight: estActif ? FontWeight.w600 : FontWeight.w500,
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
  
  Future<void> _naviguerVersDetail(String projetId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailProjetScreen(
          databaseService: widget.databaseService,
          projetId: projetId,
        ),
      ),
    );
  }
  
  Future<void> _naviguerVersEdition(String projetId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjetScreen(
          databaseService: widget.databaseService,
          projetId: projetId,
        ),
      ),
    );
  }
}