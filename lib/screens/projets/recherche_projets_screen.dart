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
            height: MediaQuery.of(context).padding.top + 80, // Inclut la barre de statut
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
                  
                  // Section Filtres (optionnel - décommenter si besoin)
                  /*
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  
                  // Filtres Statut
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statut',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterButton(
                                'en_attente',
                                'En attente',
                                Icons.pending,
                                AppTheme.statusEnAttente,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFilterButton(
                                'en_cours',
                                'En cours',
                                Icons.play_arrow,
                                AppTheme.statusEnCours,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFilterButton(
                                'termine',
                                'Terminé',
                                Icons.check_circle,
                                AppTheme.statusTermine,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filtres Images & Tâches
                  const SizedBox(height: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contenu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildContentFilterButton(
                                'avec_images',
                                'Avec images',
                                Icons.photo,
                                true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildContentFilterButton(
                                'sans_images',
                                'Sans images',
                                Icons.photo_library,
                                false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildContentFilterButton(
                                'avec_taches',
                                'Avec tâches',
                                Icons.checklist,
                                true,
                                isTasks: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildContentFilterButton(
                                'sans_taches',
                                'Sans tâches',
                                Icons.list,
                                false,
                                isTasks: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dates
                  const SizedBox(height: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Période',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                isStart: true,
                                label: 'Début',
                                selectedDate: _selectedDateDebut,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDateButton(
                                isStart: false,
                                label: 'Fin',
                                selectedDate: _selectedDateFin,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tri
                  const SizedBox(height: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tri',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _triPar,
                          onChanged: (value) {
                            setState(() => _triPar = value!);
                            _rechercher();
                          },
                          decoration: InputDecoration(
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
                          items: const [
                            DropdownMenuItem(value: 'date_creation', child: Text('Date de création')),
                            DropdownMenuItem(value: 'date_modification', child: Text('Date de modification')),
                            DropdownMenuItem(value: 'titre', child: Text('Titre')),
                            DropdownMenuItem(value: 'nombre_taches', child: Text('Nombre de tâches')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ordre décroissant',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Switch(
                              value: _ordreDecroissant,
                              onChanged: (value) {
                                setState(() => _ordreDecroissant = value);
                                _rechercher();
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  */
                  
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
  
  Widget _buildFilterButton(String value, String text, IconData icon, Color color) {
    final isSelected = _selectedStatut == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedStatut = isSelected ? null : value);
        _rechercher();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentFilterButton(String id, String text, IconData icon, bool value, {bool isTasks = false}) {
    final isSelected = isTasks 
        ? _avecTaches == value
        : _avecImages == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (isTasks) {
            _avecTaches = isSelected ? null : value;
          } else {
            _avecImages = isSelected ? null : value;
          }
        });
        _rechercher();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.primary,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateButton({
    required bool isStart,
    required String label,
    required DateTime? selectedDate,
  }) {
    return ElevatedButton(
      onPressed: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        
        if (date != null) {
          if (isStart) {
            setState(() => _selectedDateDebut = date);
          } else {
            setState(() => _selectedDateFin = date);
          }
          _rechercher();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: selectedDate != null ? AppTheme.primary : Colors.grey[700],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selectedDate != null ? AppTheme.primary : Colors.grey[300]!,
            width: selectedDate != null ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        selectedDate != null
            ? '$label: ${_formatDate(selectedDate!)}'
            : label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.w500,
        ),
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