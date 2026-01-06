import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jprojets/services/pdf_service.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/screens/projets/edit_projet_screen.dart';
import 'package:jprojets/screens/projets/tache_detail_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/widgets/link_actions_bottom_sheet.dart';
import 'package:jprojets/widgets/tache_widget.dart';

class DetailProjetScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String projetId;
  
  const DetailProjetScreen({
    Key? key,
    required this.databaseService,
    required this.projetId,
  }) : super(key: key);
  
  @override
  _DetailProjetScreenState createState() => _DetailProjetScreenState();
}

class _DetailProjetScreenState extends State<DetailProjetScreen> {
  late Projet? _projet;
  bool _isExporting = false;
  
  @override
  void initState() {
    super.initState();
    _chargerProjet();
  }
  
  void _chargerProjet() {
    setState(() {
      _projet = widget.databaseService.getProjetParId(widget.projetId);
    });
  }
  
  Future<void> _supprimerProjet() async {
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
      await widget.databaseService.supprimerProjet(widget.projetId);
      Navigator.pop(context);
      
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
  
  Future<void> _exporterProjet() async {
    if (_projet == null) return;
    
    try {
      setState(() {
        _isExporting = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final jsonData = await widget.databaseService.exporterProjetEnJson(widget.projetId);
      
      final date = DateTime.now();
      final fileName = 'projet_${_projet!.titre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.json';
      
      final bytes = utf8.encode(jsonData);
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter ce projet',
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
              content: Text('Projet "${_projet!.titre}" exporté avec succès !'),
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
          print('Erreur lors de l\'export du projet : $e');
        
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
  
  Future<void> _ajouterTache() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTacheDialog(
        projetId: widget.projetId,
        databaseService: widget.databaseService,
      ),
    );
    
    if (result != null && result['success'] == true) {
      _chargerProjet();
    }
  }
  
  Future<void> _toggleTache(String tacheId) async {
    await widget.databaseService.toggleTacheCompletee(widget.projetId, tacheId);
    _chargerProjet();
  }
  
  Future<void> _toggleSousTache(String tacheId, String sousTacheId) async {
    await widget.databaseService.toggleSousTacheCompletee(widget.projetId, tacheId, sousTacheId);
    _chargerProjet();
  }
  
  Future<void> _supprimerTache(String tacheId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
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
      await widget.databaseService.supprimerTache(widget.projetId, tacheId);
      _chargerProjet();
    }
  }
  
  Future<void> _exporterEnPdf() async {
  if (_projet == null) return;
  
  try {
    // Créer une instance du service PDF
    final pdfService = PdfExportService();
    
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Générer le PDF
    final pdfBytes = await pdfService.generateProjetPdf(_projet!);
    
    // Fermer le loader
    Navigator.pop(context);
    
    // Demander à l'utilisateur ce qu'il veut faire
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF généré'),
        content: const Text('Que souhaitez-vous faire avec le PDF ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'preview'),
            child: const Text('Prévisualiser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (action == 'preview') {
      // Prévisualiser
      await pdfService.previewPdf(pdfBytes, _projet!.titre);
    } else if (action == 'share') {
      // Sauvegarder et partager
      final fileName = 'projet_${_projet!.titre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await pdfService.savePdfLocally(pdfBytes, fileName);
      
      // Partager
      await pdfService.sharePdf(filePath, 'Projet: ${_projet!.titre}');
    }
    
  } catch (e) {
    // Fermer le loader si encore ouvert
    if (Navigator.canPop(context)) Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la génération du PDF: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

  void _showLinkOptions(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LinkActionsBottomSheet(
        url: url,
        linkTitle: 'Lien dans le projet',
      ),
    );
  }

  Widget _buildDescriptionAvecLiens(String description) {
    return Linkify(
      onOpen: (link) => _showLinkOptions(context, link.url),
      text: description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      linkStyle: TextStyle(
        fontSize: 14,
        color: AppTheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  void _showImagePreview(int index) {
    if (_projet?.images == null || _projet!.images!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3,
                  child: Image.file(
                    File(_projet!.images![index]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${index + 1}/${_projet!.images!.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Navigation entre les images
            if (_projet!.images!.length > 1) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: index > 0
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _showImagePreview(index - 1);
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: index < _projet!.images!.length - 1
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _showImagePreview(index + 1);
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ],
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
                Icon(
                  Icons.cloud_upload,
                  color: AppTheme.primary,
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
  
  @override
  Widget build(BuildContext context) {
    if (_projet == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.primary,
          title: const Text('Projet non trouvé', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Le projet n\'existe pas'),
        ),
      );
    }
    
    final tachesCompletees = _projet!.taches.where((t) => t.estCompletee).length;
    final progress = _projet!.taches.isEmpty ? 0.0 : tachesCompletees / _projet!.taches.length;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // AppBar fixe avec SystemOverlayStyle
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
                            // Première ligne : Boutons gauche et droite
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Bouton retour à gauche
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                
                                // Espace vide au centre
                                const Spacer(),
                                
                                // Boutons à droite
                                Row(
                                  children: [
                                    // Bouton exporter
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.cloud_upload,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      onPressed: _exporterProjet,
                                      tooltip: 'Exporter ce projet',
                                    ),
                                    
                                    // Bouton modifier
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditProjetScreen(
                                              databaseService: widget.databaseService,
                                              projetId: widget.projetId,
                                            ),
                                          ),
                                        ).then((_) => _chargerProjet());
                                      },
                                      tooltip: 'Modifier',
                                    ),
                                    
                                    // Menu plus d'options
                                    PopupMenuButton<String>(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onSelected: (value) async {
                                          if (value == 'delete') {
                                            _supprimerProjet();
                                          } else if (value == 'export_pdf') {
                                            await _exporterEnPdf();
                                          }
                                        },
                                      itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'export_pdf',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 20),
                                                  const SizedBox(width: 12),
                                                  const Text('Exporter en PDF'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: AppTheme.error),
                                              SizedBox(width: 12),
                                              Text('Supprimer'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Deuxième ligne : Titre et tâches
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _projet!.titre,
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
                                    '${tachesCompletees}/${_projet!.taches.length} tâches',
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
              
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec statut et date
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_projet!.statut).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(_projet!.statut).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(_projet!.statut),
                                    color: _getStatusColor(_projet!.statut),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getStatusText(_projet!.statut),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(_projet!.statut),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Créé le ${_formatDate(_projet!.dateCreation)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Barre de progression
                      const SizedBox(height: 24),
                      
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progression',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0 ? AppTheme.statusTermine : AppTheme.primary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              '$tachesCompletees tâches complétées sur ${_projet!.taches.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Description
                      if (_projet!.description != null && _projet!.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              width: double.infinity,
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
                              child: _buildDescriptionAvecLiens(_projet!.description!),
                            ),
                          ],
                        ),
                      
                      // Images
                      if (_projet!.images != null && _projet!.images!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            
                            Text(
                              'Images (${_projet!.images!.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _projet!.images!.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showImagePreview(index),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: index < _projet!.images!.length - 1 ? 12 : 0,
                                      ),
                                      width: 250,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(File(_projet!.images![index])),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Indicateur de position
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${index + 1}/${_projet!.images!.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Icône de zoom
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Message d'information
                            if (_projet!.images!.length > 1) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Cliquez sur une image pour la voir en grand',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      
                      // Section Tâches
                      Container(
                        margin: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tâches',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _ajouterTache,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, size: 16),
                                  SizedBox(width: 8),
                                  Text('Ajouter'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Liste des tâches ou message vide
                      if (_projet!.taches.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.checklist,
                                  color: Colors.grey[300],
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune tâche',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez votre première tâche',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _ajouterTache,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Ajouter une tâche'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _projet!.taches.map((tache) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.only(bottom: 2),
                              child: TacheWidget(
                                tache: tache,
                                onToggle: () => _toggleTache(tache.id),
                                onToggleSousTache: (sousTacheId) => _toggleSousTache(tache.id, sousTacheId),
                                onDelete: () => _supprimerTache(tache.id),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TacheDetailScreen(
                                        databaseService: widget.databaseService,
                                        projetId: widget.projetId,
                                        tacheId: tache.id,
                                      ),
                                    ),
                                  ).then((_) => _chargerProjet());
                                },
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
        ),
        
        // Loader overlay
        if (_isExporting) _buildLoaderOverlay(),
      ],
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
  
  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'en_cours': return 'En cours';
      case 'termine': return 'Terminé';
      default: return 'Inconnu';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AddTacheDialog extends StatefulWidget {
  final String projetId;
  final DatabaseService databaseService;
  
  const AddTacheDialog({
    Key? key,
    required this.projetId,
    required this.databaseService,
  }) : super(key: key);
  
  @override
  _AddTacheDialogState createState() => _AddTacheDialogState();
}

class _AddTacheDialogState extends State<AddTacheDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle tâche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: 'Titre de la tâche',
                      labelStyle: TextStyle(color: Colors.grey[600]),
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      labelStyle: TextStyle(color: Colors.grey[600]),
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await widget.databaseService.ajouterTache(
                        projetId: widget.projetId,
                        titre: _titreController.text.trim(),
                        description: _descriptionController.text.trim(),
                      );
                      
                      Navigator.pop(context, {'success': true});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}