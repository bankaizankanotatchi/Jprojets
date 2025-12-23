import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/screens/informations/create_information_screen.dart';
import 'package:jprojets/screens/informations/detail_information_screen.dart';
import 'package:jprojets/screens/informations/edit_information_screen.dart';
import 'package:jprojets/screens/informations/recherche_informations_screen.dart';
import 'package:jprojets/services/database_service.dart';

class ListInformationsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const ListInformationsScreen({
    Key? key,
    required this.databaseService,
  }) : super(key: key);
  
  @override
  _ListInformationsScreenState createState() => _ListInformationsScreenState();
}

class _ListInformationsScreenState extends State<ListInformationsScreen> with WidgetsBindingObserver {
  late List<Information> _informations;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chargerInformations();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chargerInformations();
    }
  }
  
  void _chargerInformations() {
    final toutesInfos = widget.databaseService.getToutesInformations();
    // Trier par date décroissante
    toutesInfos.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    
    setState(() {
      _informations = toutesInfos;
    });
  }
  
  Future<void> _supprimerInformation(String infoId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'information'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette information ?'),
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
      await widget.databaseService.supprimerInformation(infoId);
      _chargerInformations();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Information supprimée avec succès'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  Future<void> _rechercheParDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (date == null) return;
    
    final resultats = widget.databaseService.rechercherInformations(
      dateDebut: DateTime(date.year, date.month, date.day),
      dateFin: DateTime(date.year, date.month, date.day + 1),
    );
    
    setState(() {
      _informations = resultats;
      // Trier par date décroissante
      _informations.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    });
  }
  
  void _resetFiltres() {
    _chargerInformations();
  }
  
  String _getPreviewFromPoints(List<String> points) {
    if (points.isEmpty) return '';
    // Prendre le premier point et le limiter à 100 caractères
    final firstPoint = points.first;
    if (firstPoint.length <= 100) return firstPoint;
    return '${firstPoint.substring(0, 100)}...';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // AppBar fixe
          Container(
            height: MediaQuery.of(context).padding.top + 130,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            
                            const Spacer(),
                            
                            Row(
                              children: [
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
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RechercheInformationsScreen(databaseService: widget.databaseService),
                                      ),
                                    );
                                    _chargerInformations();
                                  },
                                  tooltip: 'Recherche avancée',
                                ),
                                
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: _rechercheParDate,
                                  tooltip: 'Filtrer par date',
                                ),
                                
                                // Bouton pour réinitialiser les filtres
                                if (_informations.length != widget.databaseService.getToutesInformations().length)
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
                                    onPressed: _resetFiltres,
                                    tooltip: 'Réinitialiser les filtres',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes Connaissances',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_informations.length} informations',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_informations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.grey[300],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par enregistrer ce que vous apprenez',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateInformationScreen(databaseService: widget.databaseService),
                                ),
                              );
                              _chargerInformations();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Ajouter une information'),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _informations.map((info) {
                        final hasImages = info.images != null && info.images!.isNotEmpty;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            color: Colors.white,
                            child: InkWell(
                              onTap: () async {
                                await _naviguerVersDetail(info.id);
                                _chargerInformations();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
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
                                        
                                        const SizedBox(width: 12),
                                        
                                        Expanded(
                                          child: Text(
                                            info.titre,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        
                                        // Menu avec options modifier/supprimer
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.grey[500],
                                            size: 18,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              await _naviguerVersEdition(info.id);
                                              _chargerInformations();
                                            } else if (value == 'delete') {
                                              await _supprimerInformation(info.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 16, color: AppTheme.secondary),
                                                  const SizedBox(width: 8),
                                                  const Text('Modifier'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 16, color: AppTheme.error),
                                                  const SizedBox(width: 8),
                                                  const Text('Supprimer'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    if (info.points.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, left: 52),
                                        child: Text(
                                          _getPreviewFromPoints(info.points),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, left: 52),
                                      child: Row(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.list,
                                                size: 12,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${info.points.length} point${info.points.length > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(width: 16),
                                          
                                          if (hasImages)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.photo,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${info.images!.length} image${info.images!.length > 1 ? 's' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          
                                          const Spacer(),
                                          
                                          Text(
                                            _formatDate(info.dateCreation),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateInformationScreen(databaseService: widget.databaseService),
              ),
            );
            _chargerInformations();
          },
          backgroundColor: AppTheme.secondary,
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
  
  Future<void> _naviguerVersDetail(String infoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailInformationScreen(
          databaseService: widget.databaseService,
          infoId: infoId,
        ),
      ),
    );
  }
  
  Future<void> _naviguerVersEdition(String infoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInformationScreen(
          databaseService: widget.databaseService,
          infoId: infoId,
        ),
      ),
    );
  }
}