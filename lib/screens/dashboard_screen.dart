import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/user.dart';
import 'package:jprojets/screens/informations/list_informations_screen.dart';
import 'package:jprojets/screens/projets/list_projets_screen.dart';
import 'package:jprojets/screens/login_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const DashboardScreen({Key? key, required this.databaseService}) : super(key: key);
  
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late User? _currentUser;
  Map<String, int> _projetStats = {};
  Map<String, int> _infoStats = {};
  bool _showSidebar = false;
  bool _isExporting = false;
  bool _isImporting = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    _currentUser = widget.databaseService.getUtilisateurConnecte();
    _projetStats = widget.databaseService.getStatistiquesProjets();
    _infoStats = widget.databaseService.getStatistiquesInformationsParPeriode();
    setState(() {});
  }
  
  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
    
    if (_showSidebar) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // En-tête avec couleur qui couvre la barre de statut
              Container(
                width: double.infinity,
                color: AppTheme.primary,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bonjour,',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Que souhaitez-vous faire aujourd\'hui ?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Menu hamburger
                        GestureDetector(
                          onTap: _toggleSidebar,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Card Projets
                      _buildMainCard(
                        title: 'Projets',
                        subtitle: '${_projetStats['total'] ?? 0} au total',
                        icon: Icons.work_outline,
                        color: AppTheme.primary,
                        stats: [
                          _buildMiniStat('En attente', _projetStats['en_attente'] ?? 0, AppTheme.statusEnAttente),
                          _buildMiniStat('En cours', _projetStats['en_cours'] ?? 0, AppTheme.statusEnCours),
                          _buildMiniStat('Terminés', _projetStats['termines'] ?? 0, AppTheme.statusTermine),
                        ],
                        onTap: () async {
                          await _naviguerVersProjets();
                          _loadData();
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Card Connaissances
                      _buildMainCard(
                        title: 'Connaissances',
                        subtitle: '${_infoStats['total'] ?? 0} au total',
                        icon: Icons.lightbulb_outline,
                        color: AppTheme.secondary,
                        stats: [
                          _buildMiniStat('Aujourd\'hui', _infoStats['aujourdhui'] ?? 0, AppTheme.statusEnCours),
                          _buildMiniStat('Cette semaine', _infoStats['cette_semaine'] ?? 0, AppTheme.primaryLight),
                          _buildMiniStat('Ce mois', _infoStats['ce_mois'] ?? 0, AppTheme.primary),
                        ],
                        onTap: () async {
                          await _naviguerVersInformations();
                          _loadData();
                        },
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Overlay pour fermer la sidebar avec animation
        if (_showSidebar)
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        
        // Sidebar avec animation
        if (_showSidebar) _buildSidebar(),
        
        // Loader pour export/import
        if (_isExporting || _isImporting) _buildLoaderOverlay(),
      ],
    );
  }
  
  Widget _buildSidebar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        child: Material(
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // En-tête de la sidebar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _toggleSidebar,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        
                        // Option Export
                        _buildSidebarItem(
                          icon: Icons.cloud_upload_outlined,
                          iconColor: AppTheme.primary,
                          title: 'Exporter toutes les données',
                          subtitle: 'Sauvegarder un backup complet',
                          onTap: _exporterToutesDonnees,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Option Import
                        _buildSidebarItem(
                          icon: Icons.cloud_download_outlined,
                          iconColor: AppTheme.secondary,
                          title: 'Importer des données',
                          subtitle: 'Restaurer depuis un backup',
                          onTap: _importerToutesDonnees,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Séparateur
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(
                            color: Colors.grey[300],
                            height: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Option Déconnexion
                        _buildSidebarItem(
                          icon: Icons.logout,
                          iconColor: AppTheme.error,
                          title: 'Déconnexion',
                          subtitle: 'Quitter l\'application',
                          onTap: _afficherDialogueDeconnexion,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Information version
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                'JProjets v1.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '© ${DateTime.now().year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSidebarItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _toggleSidebar();
            // Petit délai pour laisser l'animation se terminer
            Future.delayed(const Duration(milliseconds: 300), onTap);
          },
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
                _isExporting
                    ? const Icon(
                        Icons.cloud_upload,
                        color: AppTheme.primary,
                        size: 30,
                      )
                    : const Icon(
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
  Widget _buildMainCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> stats,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // En-tête de la carte
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Divider subtile
              Container(
                height: 1,
                color: Colors.grey[100],
              ),
              
              const SizedBox(height: 20),
              
              // Statistiques
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Future<void> _naviguerVersProjets({String? statut}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListProjetsScreen(
          databaseService: widget.databaseService,
          statutFiltre: statut,
        ),
      ),
    );
  }
  
  Future<void> _naviguerVersInformations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListInformationsScreen(databaseService: widget.databaseService),
      ),
    );
  }
  
Future<void> _exporterToutesDonnees() async {
  try {
    setState(() {
      _isExporting = true;
    });
    
    // Attendre un peu pour montrer l'animation
    await Future.delayed(const Duration(milliseconds: 500));
    
    final jsonData = await widget.databaseService.exporterToutesDonneesEnJson();
    
    final date = DateTime.now();
    final fileName = 'jprojets_backup_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour}${date.minute}.json';
    
    // Convertir en bytes pour file_picker
    final bytes = utf8.encode(jsonData);
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Sauvegarder le backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(bytes), // ← CORRECTION ICI
    );
    
    if (result != null) {
      final file = File(result);
      await file.writeAsString(jsonData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup sauvegardé avec succès !'),
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
  Future<void> _importerToutesDonnees() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Sélectionner le fichier de backup',
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final jsonData = await file.readAsString();
      
      setState(() {
        _isImporting = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      await widget.databaseService.importerToutesDonneesDepuisJson(jsonData);
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Données importées avec succès !'),
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
  
  void _afficherDialogueDeconnexion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deconnecter();
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deconnecter() async {
    try {
      await widget.databaseService.deconnexion();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(databaseService: widget.databaseService),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}