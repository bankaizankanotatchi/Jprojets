import 'package:flutter/material.dart';

/// Thème principal de l'application avec toutes les couleurs et styles
class AppTheme {
  // ==================== COULEURS PRINCIPALES ====================
  
  /// Couleur principale de l'application (violet moderne)
  static const Color primary = Color(0xFF6C63FF);
  
  /// Variante plus claire du primary
  static const Color primaryLight = Color(0xFF8B85FF);
  
  /// Variante plus foncée du primary
  static const Color primaryDark = Color(0xFF4A42E0);
  
  /// Couleur secondaire (turquoise)
  static const Color secondary = Color(0xFF6C63FF);
  
  /// Variante claire du secondary
  static const Color secondaryLight = Color(0xFF8B85FF);
  
  // ==================== COULEURS DE STATUT ====================
  
  /// Couleur pour les projets en attente (orange)
  static const Color statusEnAttente = Color(0xFFFF9800);
  
  /// Couleur pour les projets en cours (bleu)
  static const Color statusEnCours = Color(0xFF2196F3);
  
  /// Couleur pour les projets terminés (vert)
  static const Color statusTermine = Color(0xFF4CAF50);
  
  // ==================== COULEURS DE FOND ====================
  
  /// Fond principal de l'application (mode clair)
  static const Color background = Color(0xFFF5F7FA);
  
  /// Fond des cartes et conteneurs
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Fond pour les sections secondaires
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  
  // ==================== COULEURS DE TEXTE ====================
  
  /// Texte principal (noir)
  static const Color textPrimary = Color(0xFF1A1A1A);
  
  /// Texte secondaire (gris foncé)
  static const Color textSecondary = Color(0xFF6B6B6B);
  
  /// Texte tertiaire (gris clair)
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  /// Texte sur fond coloré
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // ==================== COULEURS UTILITAIRES ====================
  
  /// Couleur de succès
  static const Color success = Color(0xFF4CAF50);
  
  /// Couleur d'erreur
  static const Color error = Color(0xFFF44336);
  
  /// Couleur d'avertissement
  static const Color warning = Color(0xFFFF9800);
  
  /// Couleur d'information
  static const Color info = Color(0xFF2196F3);
  
  // ==================== COULEURS DE BORDURE ====================
  
  /// Bordure principale
  static const Color border = Color(0xFFE0E0E0);
  
  /// Bordure au focus
  static const Color borderFocus = primary;
  
  // ==================== DÉGRADÉS ====================
  
  /// Dégradé principal (violet vers bleu)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  
  /// Dégradé pour les cartes
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );
  
  /// Dégradé pour le fond d'écran
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF0)],
  );
  
  // ==================== OMBRES ====================
  
  /// Ombre légère pour les cartes
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Ombre pour les éléments flottants
  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Ombre pour les boutons
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ==================== RAYONS DE BORDURE ====================
  
  /// Rayon standard
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // ==================== ESPACEMENTS ====================
  
  /// Espacements standards
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // ==================== THÈME MATERIAL ====================
  
  /// Retourne le ThemeData complet pour l'application
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      
      // Schéma de couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      
      // Couleur du scaffold
      scaffoldBackgroundColor: background,
      
      // Style de l'AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Style des cartes
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Style des boutons élevés
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Style des champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
      ),
      
      // Style des icônes
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      
      // Style du texte
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Style du FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Style des dividers
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }
}