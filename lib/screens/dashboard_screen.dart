import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/user.dart';
import 'package:jprojets/screens/informations/list_informations_screen.dart';
import 'package:jprojets/screens/projets/list_projets_screen.dart';
import 'package:jprojets/screens/login_screen.dart';
import 'package:jprojets/services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const DashboardScreen({Key? key, required this.databaseService}) : super(key: key);
  
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late User? _currentUser;
  Map<String, int> _projetStats = {};
  Map<String, int> _infoStats = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          Text(
                            'Bonjour, Otaku sama !',
                            style: const TextStyle(
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
                    // IconButton(
                    //   onPressed: _afficherDialogueDeconnexion,
                    //   icon: const Icon(
                    //     Icons.logout,
                    //     color: Colors.white,
                    //     size: 24,
                    //   ),
                    //   tooltip: 'Se déconnecter',
                    // ),
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
              child: Text(
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