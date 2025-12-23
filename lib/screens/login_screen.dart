import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/screens/dashboard_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const LoginScreen({Key? key, required this.databaseService}) : super(key: key);
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  bool _isLoading = false;
  bool _hasCheckedExistingLogin = false;
  
  @override
  void initState() {
    super.initState();
    
    // Planifier la vérification après le premier rendu complet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifierConnexionExistante();
    });
  }
  
  void _verifierConnexionExistante() async {
    // Éviter de vérifier plusieurs fois
    if (_hasCheckedExistingLogin || !mounted) return;
    _hasCheckedExistingLogin = true;
    
    try {
      if (widget.databaseService.estConnecte()) {
        // Petit délai pour s'assurer que l'interface est stable
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          await _naviguerVersDashboard();
        }
      }
    } catch (e) {
      print("Erreur lors de la vérification de connexion: $e");
    }
  }
  
  Future<void> _connecterUtilisateur() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await widget.databaseService.connexion(_nomController.text.trim());
        
        // Attendre un court instant avant de naviguer
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (mounted) {
          await _naviguerVersDashboard();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de connexion: $e'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  Future<void> _naviguerVersDashboard() async {
    // Double vérification que le widget est toujours monté
    if (!mounted) return;
    
    // Utiliser pushAndRemoveUntil pour une navigation propre
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(databaseService: widget.databaseService),
      ),
      (route) => false, // Supprime toutes les routes précédentes
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingXLarge),
            child: Column(
              children: [
                // Logo et titre
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                
                // Logo
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/logo.png', 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.work_outline,
                        size: 60,
                        color: AppTheme.primary,
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXSmall),
                
                Text(
                  'Gérez vos projets et connaissances',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spacingXLarge),
                
                // Formulaire
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Votre nom',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            if (value.trim().length < 2) {
                              return 'Le nom doit contenir au moins 2 caractères';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _connecterUtilisateur();
                            }
                          },
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        GradientButton(
                          onPressed: _isLoading ? null : _connecterUtilisateur,
                          text: _isLoading ? 'Connexion...' : 'Commencer',
                          gradient: AppTheme.primaryGradient,
                          icon: Icons.login,
                          isLoading: _isLoading,
                        ),
                        
                        const SizedBox(height: AppTheme.spacingMedium),
                       
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

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }
}