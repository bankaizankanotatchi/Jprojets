import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BibliothequePdfProjetsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  
  const BibliothequePdfProjetsScreen({
    Key? key,
    required this.databaseService,
  }) : super(key: key);
  
  @override
  _BibliothequePdfProjetsScreenState createState() => _BibliothequePdfProjetsScreenState();
}

class _BibliothequePdfProjetsScreenState extends State<BibliothequePdfProjetsScreen> {
  List<Map<String, dynamic>> _pdfList = [];
  List<Map<String, dynamic>> _pdfListFiltree = [];
  bool _isLoading = true;
  bool _rechercheActive = false;
  final TextEditingController _rechercheController = TextEditingController();
  final FocusNode _rechercheFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _chargerPdf();
    
    _rechercheController.addListener(() {
      _filtrerPdf();
    });
  }
  
  @override
  void dispose() {
    _rechercheController.dispose();
    _rechercheFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _chargerPdf() async {
    setState(() {
      _isLoading = true;
    });
    
    // Obtenir tous les PDF et filtrer pour ne garder que ceux des projets
    final tousPdf = await widget.databaseService.getListeTousPdf();
    final pdfProjets = tousPdf.where((pdf) => pdf['type'] == 'projet').toList();
    
    setState(() {
      _pdfList = pdfProjets;
      _pdfListFiltree = List.from(pdfProjets);
      _isLoading = false;
    });
  }
  
  void _filtrerPdf() {
    final query = _rechercheController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _pdfListFiltree = List.from(_pdfList);
      });
      return;
    }
    
    final resultats = _pdfList.where((pdf) {
      final nom = pdf['display_name']?.toString().toLowerCase() ?? '';
      final nomFichier = pdf['name']?.toString().toLowerCase() ?? '';
      final date = _formatDate(pdf['date']).toLowerCase();
      
      return nom.contains(query) || 
             nomFichier.contains(query) ||
             date.contains(query);
    }).toList();
    
    setState(() {
      _pdfListFiltree = resultats;
    });
  }
  
  void _activerRecherche() {
    setState(() {
      _rechercheActive = true;
    });
    
    // Donner le focus au champ de recherche après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _rechercheFocusNode.requestFocus();
      }
    });
  }
  
  void _desactiverRecherche() {
    setState(() {
      _rechercheActive = false;
      _rechercheController.clear();
    });
    _filtrerPdf();
  }
  
  Future<void> _supprimerPdf(String filePath, String fileName) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le PDF'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$fileName" ?'),
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
      final success = await widget.databaseService.supprimerPdf(filePath);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF "$fileName" supprimé'),
            backgroundColor: AppTheme.success,
          ),
        );
        _chargerPdf();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la suppression'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
  

  Future<void> _previsualiserPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fichier PDF non trouvé'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      
      final pdfBytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: path.basename(filePath),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de prévisualisation: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
  
  Future<void> _partagerPdf(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fichier PDF non trouvé'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'PDF Projet: $fileName',
        text: 'Voici le PDF du projet "$fileName" généré par JProjets',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de partage: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
  
  void _afficherOptionsPdf(Map<String, dynamic> pdf) {
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
              color: Colors.black.withOpacity(0.2),
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
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                pdf['display_name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'PDF Projets • ${_formatSize(pdf['size'])}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Option Prévisualiser
            _buildMenuOption(
              icon: Icons.remove_red_eye_outlined,
              iconColor: AppTheme.secondary,
              title: 'Prévisualiser',
              onTap: () {
                Navigator.pop(context);
                _previsualiserPdf(pdf['path']);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Option Partager
            _buildMenuOption(
              icon: Icons.share_outlined,
              iconColor: AppTheme.primary,
              title: 'Partager sur WhatsApp',
              onTap: () {
                Navigator.pop(context);
                _partagerPdf(pdf['path'], pdf['display_name']);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Option Supprimer
            _buildMenuOption(
              icon: Icons.delete_outline,
              iconColor: AppTheme.error,
              title: 'Supprimer',
              onTap: () {
                Navigator.pop(context);
                _supprimerPdf(pdf['path'], pdf['display_name']);
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  Widget _buildPdfCard(Map<String, dynamic> pdf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _previsualiserPdf(pdf['path']),
        onLongPress: () => _afficherOptionsPdf(pdf),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône PDF
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: AppTheme.error,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Détails du PDF
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf['display_name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        
                        Text(
                          _formatSize(pdf['size']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          _formatDate(pdf['date']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      pdf['name'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Menu d'options
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'preview') {
                    _previsualiserPdf(pdf['path']);
                  } else if (value == 'share') {
                    _partagerPdf(pdf['path'], pdf['display_name']);
                  } else if (value == 'delete') {
                    _supprimerPdf(pdf['path'], pdf['display_name']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.remove_red_eye, size: 18),
                        SizedBox(width: 8),
                        Text('Prévisualiser'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Partager'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    if (_rechercheActive) {
      return Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: 16,
              top: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => _desactiverRecherche(),
                    ),
                    
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                
                                controller: _rechercheController,
                                focusNode: _rechercheFocusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un PDF...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                ),
                                cursorColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bouton pour désactiver la recherche
                    TextButton(
                      onPressed: _desactiverRecherche,
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Indicateur de résultats
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${_pdfListFiltree.length} résultat${_pdfListFiltree.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
              top: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PDF des Projets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_pdfList.length} projet${_pdfList.length > 1 ? 's' : ''} PDF',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _chargerPdf,
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // AppBar dynamique
          _buildAppBar(),
          
          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_rechercheActive && _pdfListFiltree.isEmpty && _rechercheController.text.isNotEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              color: Colors.grey[300],
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun résultat trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Aucun PDF ne correspond à votre recherche "${_rechercheController.text}"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _pdfListFiltree.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.grey[300],
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun PDF de projet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Les PDF générés pour vos projets apparaîtront ici',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Retour aux Projets'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                // Liste des PDF
                                if (!_rechercheActive)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Projets PDF (${_pdfListFiltree.length})',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                if (_rechercheActive && _rechercheController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      'Résultats pour "${_rechercheController.text}" (${_pdfListFiltree.length})',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Liste
                                Column(
                                  children: _pdfListFiltree.map((pdf) => _buildPdfCard(pdf)).toList(),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Guide d'utilisation
                                if (!_rechercheActive)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: AppTheme.secondary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Guide rapide',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[900],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        _buildGuideItem(
                                          icon: Icons.touch_app,
                                          text: 'Toucher pour prévisualiser',
                                        ),
                                        _buildGuideItem(
                                          icon: Icons.touch_app,
                                          text: 'Appuyer long pour options',
                                        ),
                                        _buildGuideItem(
                                          icon: Icons.share,
                                          text: 'Partager sur WhatsApp',
                                        ),
                                        _buildGuideItem(
                                          icon: Icons.delete,
                                          text: 'Supprimer libère l\'espace',
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
          ),
        ],
      ),
      
      // Floating Action Button pour la recherche
      floatingActionButton: !_rechercheActive
          ? FloatingActionButton(
              onPressed: _activerRecherche,
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 4,
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
  

  Widget _buildGuideItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}