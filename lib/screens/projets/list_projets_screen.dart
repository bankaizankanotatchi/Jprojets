import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jprojets/screens/projets/bibliotheque_pdf_projet_screen.dart';
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
  bool _isExporting = false;
  bool _isImporting = false;
  
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
  
  Future<void> _exporterTousProjets() async {
    try {
      setState(() {
        _isExporting = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final jsonData = await widget.databaseService.exporterProjetsEnJson();
      
      final date = DateTime.now();
      final fileName = 'jprojets_projets_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour}${date.minute}.json';
      
      final bytes = utf8.encode(jsonData);
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter tous les projets',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(bytes),
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_projets.length} projets exportés avec succès !'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Erreur lors de l\'export : $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
  
  Future<void> _importerProjets() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Importer des projets',
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return;
      
      setState(() {
        _isImporting = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final jsonData = await file.readAsString();
      
      final projetsImportes = await widget.databaseService.importerProjetsDepuisJson(jsonData);
      
      _chargerProjets();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${projetsImportes.length} projets importés avec succès !'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print('Erreur lors de l\'import : $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
  
  void _afficherMenuExportImport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Export/Import',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Gérer vos projets',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Option Export
            _buildMenuOption(
              icon: Icons.cloud_upload_outlined,
              iconColor: AppTheme.primary,
              title: 'Exporter tous les projets',
              subtitle: 'Sauvegarder tous les projets dans un fichier JSON',
              onTap: () {
                Navigator.pop(context);
                _exporterTousProjets();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Option Import
            _buildMenuOption(
              icon: Icons.cloud_download_outlined,
              iconColor: AppTheme.secondary,
              title: 'Importer des projets',
              subtitle: 'Ajouter des projets depuis un fichier JSON',
              onTap: () {
                Navigator.pop(context);
                _importerProjets();
              },
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Annuler
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
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
                                
                                Row(
                                  children: [
                                    // Bouton Export/Import
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.cloud,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: _afficherMenuExportImport,
                                      tooltip: 'Export/Import',
                                    ),
                                    
                                    // Bouton Recherche
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
                                            builder: (context) => RechercheProjetsScreen(
                                              databaseService: widget.databaseService,
                                            ),
                                          ),
                                        );
                                        _chargerProjets();
                                      },
                                      tooltip: 'Recherche avancée',
                                    ),
                                  ],
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
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateProjetScreen(
                                        databaseService: widget.databaseService,
                                      ),
                                    ),
                                  );
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
                      
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Premier FAB (créer projet)
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // FAB Bibliothèque PDF
              Container(
                margin: const EdgeInsets.only(bottom: 16, right: 16),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BibliothequePdfProjetsScreen(
                          databaseService: widget.databaseService,
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  heroTag: 'pdf_library',
                  child: const Icon(Icons.picture_as_pdf),
                ),
              ),
              
              // FAB Créer projet (existant)
              Container(
                margin: const EdgeInsets.only(bottom: 16, right: 16),
                child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateProjetScreen(
                          databaseService: widget.databaseService,
                        ),
                      ),
                    );
                    _chargerProjets();
                  },
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  heroTag: 'create_project',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
        
        // Loaders overlay
        if (_isExporting || _isImporting) _buildLoaderOverlay(),
      ],
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
  
  Widget _buildLoaderOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isExporting)
                  Icon(
                    Icons.cloud_upload,
                    color: AppTheme.primary,
                    size: 30,
                  )
                else
                  Icon(
                    Icons.cloud_download,
                    color: AppTheme.secondary,
                    size: 30,
                  ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
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