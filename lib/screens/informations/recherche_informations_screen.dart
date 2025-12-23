import 'package:flutter/material.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/screens/informations/detail_information_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';

class RechercheInformationsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const RechercheInformationsScreen({
    Key? key,
    required this.databaseService,
  }) : super(key: key);
  
  @override
  _RechercheInformationsScreenState createState() => _RechercheInformationsScreenState();
}

class _RechercheInformationsScreenState extends State<RechercheInformationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Information> _resultats = [];
  DateTime? _selectedDateDebut;
  DateTime? _selectedDateFin;
  bool? _avecImages;
  String _triPar = 'date_creation';
  bool _ordreDecroissant = true;
  bool _isSearching = false;
  
  void _rechercher() async {
    if (_searchController.text.isEmpty && 
        _selectedDateDebut == null && 
        _selectedDateFin == null &&
        _avecImages == null) {
      return;
    }
    
    setState(() => _isSearching = true);
    
    final resultats = await widget.databaseService.rechercherInformations(
      motCle: _searchController.text.isNotEmpty ? _searchController.text : null,
      dateDebut: _selectedDateDebut,
      dateFin: _selectedDateFin,
      avecImages: _avecImages,
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
      _selectedDateDebut = null;
      _selectedDateFin = null;
      _avecImages = null;
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
                  AppTheme.secondary,
                  AppTheme.secondary.withOpacity(0.8),
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
                          AppTheme.secondary,
                          AppTheme.secondary.withOpacity(0.8),
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
                                      'Trouvez vos connaissances',
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
                        prefixIcon: Icon(Icons.search, color: AppTheme.secondary),
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
                  
                  // Filtres Images
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
                          'Images',
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
                              child: _buildImageFilterButton(
                                'avec_images',
                                'Avec images',
                                Icons.photo,
                                true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildImageFilterButton(
                                'sans_images',
                                'Sans images',
                                Icons.photo_library,
                                false,
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
                              borderSide: BorderSide(color: AppTheme.secondary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'date_creation', child: Text('Date de création')),
                            DropdownMenuItem(value: 'date_modification', child: Text('Date de modification')),
                            DropdownMenuItem(value: 'titre', child: Text('Titre')),
                            DropdownMenuItem(value: 'nombre_points', child: Text('Nombre de points')),
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
                              activeColor: AppTheme.secondary,
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
                              color: AppTheme.secondary,
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
                          CircularProgressIndicator(color: AppTheme.secondary),
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
                      children: _resultats.map((info) {
                        final hasImages = info.images != null && info.images!.isNotEmpty;
                        
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
                                color: AppTheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                hasImages ? Icons.photo_library : Icons.lightbulb_outline,
                                color: AppTheme.secondary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              info.titre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${info.points.length} point${info.points.length > 1 ? 's' : ''} • ${_formatDate(info.dateCreation)}',
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
                            onTap: () => _naviguerVersDetail(info.id),
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
  
  Widget _buildImageFilterButton(String id, String text, IconData icon, bool value) {
    final isSelected = _avecImages == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _avecImages = isSelected ? null : value;
        });
        _rechercher();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.secondary : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.secondary,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppTheme.secondary : Colors.grey[300]!,
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
        foregroundColor: selectedDate != null ? AppTheme.secondary : Colors.grey[700],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selectedDate != null ? AppTheme.secondary : Colors.grey[300]!,
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final infoDate = DateTime(date.year, date.month, date.day);
    
    if (infoDate == today) {
      return 'Aujourd\'hui';
    }
    
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (infoDate == yesterday) {
      return 'Hier';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _naviguerVersDetail(String infoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailInformationScreen(
          databaseService: widget.databaseService,
          infoId: infoId,
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