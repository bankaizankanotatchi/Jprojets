import 'package:flutter/material.dart';
import 'package:jprojets/screens/login_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.init();
  
  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatefulWidget {
  final DatabaseService? databaseService;
  
  // Constructeur pour l'application réelle
  const MyApp({Key? key, required this.databaseService}) : super(key: key);
  
  // Constructeur pour les tests
  MyApp.test({Key? key}) : databaseService = null, super(key: key);
  
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Quand l'app passe en background (inactive, paused, detached)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _deconnecterUtilisateur();
    }
  }

  Future<void> _deconnecterUtilisateur() async {
    try {
      // Vérifier si l'utilisateur est connecté
      if (widget.databaseService != null) {
        final utilisateurConnecte = widget.databaseService!.getUtilisateurConnecte();
        if (utilisateurConnecte != null) {
          // Appeler la méthode de déconnexion
          await widget.databaseService!.deconnexion();
          print('Utilisateur déconnecté automatiquement');
        }
      }
    } catch (e) {
      print('Erreur lors de la déconnexion automatique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JProjets',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: widget.databaseService != null 
          ? LoginScreen(databaseService: widget.databaseService!)
          : const Placeholder(), // Pour les tests
    );
  }
}