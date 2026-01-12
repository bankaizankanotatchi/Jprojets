import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jprojets/services/pdf_service.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/screens/informations/edit_information_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/widgets/link_actions_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class DetailInformationScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String infoId;
  
  const DetailInformationScreen({
    Key? key,
    required this.databaseService,
    required this.infoId,
  }) : super(key: key);
  
  @override
  _DetailInformationScreenState createState() => _DetailInformationScreenState();
}

class _DetailInformationScreenState extends State<DetailInformationScreen> {
  late Information? _information;
  bool _isExporting = false;
  List<Map<String, dynamic>> _pdfList = [];
  
  @override
  void initState() {
    super.initState();
    _chargerInformation();
    _chargerPdfsAssocies();
  }
  
  void _chargerInformation() {
    setState(() {
      _information = widget.databaseService.getInformationParId(widget.infoId);
    });
  }
  
Future<void> _chargerPdfsAssocies() async {
  if (_information == null) return;
  
  // Obtenir tous les PDFs et filtrer ceux qui sont associés à cette information
  final tousPdf = await widget.databaseService.getListeTousPdf();
  final pdfAssocies = tousPdf.where((pdf) {
    // Vérifier d'abord si c'est un PDF d'information
    if (pdf['type'] != 'information') return false;
    
    // 1. Essayer de matcher par nom de fichier
    final pdfFileName = pdf['display_name']?.toString().toLowerCase() ?? '';
    final infoTitre = _information!.titre.toLowerCase();
    
    // Logique de matching plus flexible
    final titreSansAccents = _removeAccents(infoTitre);
    final pdfSansAccents = _removeAccents(pdfFileName);
    
    // Remplacer les espaces et caractères spéciaux par underscores
    final titreSansAccentsUnderscore = titreSansAccents.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    
    // Recherche par différentes variations
    final variations = [
      infoTitre,
      infoTitre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_'), // Remplace tout ce qui n'est pas alphanumérique par '_'
      infoTitre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-'),
      titreSansAccents,
      titreSansAccentsUnderscore, // Version sans accents avec underscores
      titreSansAccents.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-'),
      
    ];
    
    // Normaliser aussi le nom du PDF
    final pdfNormalise = pdfSansAccents.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    
    // Vérifier si le nom du PDF contient une des variations
    for (final variation in variations) {
      final variationClean = variation.toLowerCase().trim();
      if (variationClean.isEmpty) continue;
      
      // Vérifier si le PDF contient la variation
      if (pdfNormalise.contains(variationClean)) {
        print('Match trouvé: PDF "$pdfNormalise" contient "$variationClean"');
        return true;
      }
      
      // Vérifier aussi si la variation contient le nom du PDF (pour les cas inverses)
      if (variationClean.contains(pdfNormalise)) {
        print('Match inverse trouvé: "$variationClean" contient PDF "$pdfNormalise"');
        return true;
      }
      
      // Vérifier les sous-chaînes (pour les noms longs)
      if (pdfNormalise.length > 10 && variationClean.length > 10) {
        // Prendre les premiers 10 caractères
        final pdfStart = pdfNormalise.substring(0, min(10, pdfNormalise.length));
        final variationStart = variationClean.substring(0, min(10, variationClean.length));
        
        if (pdfStart.contains(variationStart) || variationStart.contains(pdfStart)) {
          print('Match partiel trouvé: "$pdfStart" ≈ "$variationStart"');
          return true;
        }
      }
    }
    
    // 2. Vérifier si le nom du fichier contient l'ID de l'information
    final infoId = widget.infoId.toLowerCase();
    if (pdfFileName.contains(infoId) || pdfSansAccents.contains(infoId)) {
      print('Match par ID trouvé: PDF contient ID "$infoId"');
      return true;
    }
    
    // 3. Vérifier par timestamp (si présent dans le nom du fichier)
    final infoDate = _information!.dateCreation.millisecondsSinceEpoch.toString();
    if (pdfFileName.contains(infoDate.substring(0, min(10, infoDate.length)))) {
      print('Match par date trouvé: PDF contient timestamp "$infoDate"');
      return true;
    }
    
    print('Aucun match pour PDF: $pdfFileName avec info: ${_information!.titre}');
    return false;
  }).toList();
  
  // Ajouter un log pour déboguer
  print('PDFs trouvés: ${pdfAssocies.length} pour l\'information: ${_information!.titre}');
  for (final pdf in pdfAssocies) {
    print('PDF associé: ${pdf['display_name']}');
  }
  
  setState(() {
    _pdfList = pdfAssocies;
  });
}

// Fonction pour supprimer les accents et normaliser
String _removeAccents(String str) {
  var withAccents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
  var withoutAccents = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
  
  String result = str;
  for (int i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i]);
  }
  
  // Supprimer les apostrophes et guillemets
  result = result.replaceAll("'", '').replaceAll('"', '');
  
  return result;
}

int min(int a, int b) => a < b ? a : b;
  
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
        _chargerPdfsAssocies();
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
        subject: 'PDF Information: $fileName',
        text: 'Voici le PDF de l\'information "${_information?.titre}" généré par JProjets',
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
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String _formatDatePdf(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  Widget _buildPdfCard(Map<String, dynamic> pdf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _previsualiserPdf(pdf['path']),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône PDF
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: AppTheme.error,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Détails du PDF
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf['display_name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${_formatSize(pdf['size'])} • ${_formatDatePdf(pdf['date'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
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
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _exporterInformation() async {
    if (_information == null) return;
    
    try {
      setState(() {
        _isExporting = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final jsonData = await widget.databaseService.exporterInformationEnJson(widget.infoId);
      
      final date = DateTime.now();
      final fileName = 'information_${_information!.titre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.json';
      
      final bytes = utf8.encode(jsonData);
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter cette information',
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
              content: Text('Information "${_information!.titre}" exportée avec succès !'),
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
  
  Future<void> _supprimerInformation() async {
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
      await widget.databaseService.supprimerInformation(widget.infoId);
      Navigator.pop(context);
      
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
  
  Future<void> _copierTexte(String texte) async {
    await Clipboard.setData(ClipboardData(text: texte));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Texte copié dans le presse-papier'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showLinkOptions(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LinkActionsBottomSheet(
        url: url,
        linkTitle: 'Lien dans le point',
      ),
    );
  }

  Widget _buildPointAvecLiens(int index, String point) {
    return Linkify(
      onOpen: (link) => _showLinkOptions(context, link.url),
      text: point,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      linkStyle: TextStyle(
        fontSize: 14,
        color: AppTheme.secondary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Future<void> _exporterEnPdf() async {
    if (_information == null) return;
    
    try {
      final pdfService = PdfExportService();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final pdfBytes = await pdfService.generateInformationPdf(_information!);
      
      Navigator.pop(context);
      
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
        await pdfService.previewPdf(pdfBytes, _information!.titre);
      } else if (action == 'share') {
        final fileName = 'information_${_information!.titre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = await pdfService.savePdfLocally(pdfBytes, fileName);
        
        await pdfService.sharePdf(filePath, 'Information: ${_information!.titre}');
      }
      
    } catch (e) {
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
  
  void _showImagePreview(int index) {
    if (_information?.images == null || _information!.images!.isEmpty) return;
    
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
                    File(_information!.images![index]),
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
                  '${index + 1}/${_information!.images!.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Indicateurs de navigation
            if (_information!.images!.length > 1) ...[
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
                  child: index < _information!.images!.length - 1
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
  
  @override
  Widget build(BuildContext context) {
    if (_information == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppTheme.secondary,
          title: const Text('Information non trouvée', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('L\'information n\'existe pas'),
        ),
      );
    }
    
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
                                const Text('Détail', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                
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
                                      onPressed: _exporterInformation,
                                      tooltip: 'Exporter cette information',
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
                                            builder: (context) => EditInformationScreen(
                                              databaseService: widget.databaseService,
                                              infoId: widget.infoId,
                                            ),
                                          ),
                                        ).then((_) {
                                          _chargerInformation();
                                          _chargerPdfsAssocies();
                                        });
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
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _supprimerInformation();
                                        } else if (value == 'copy_all') {
                                          _copierTexte(_information!.points.join('\n'));
                                        } else if (value == 'export_pdf') {
                                          _exporterEnPdf();
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'export_pdf',
                                          child: Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf, color: AppTheme.secondary, size: 20),
                                              const SizedBox(width: 12),
                                              const Text('Exporter en PDF'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'copy_all',
                                          child: Row(
                                            children: [
                                              Icon(Icons.content_copy, size: 20, color: Colors.grey[700]),
                                              const SizedBox(width: 12),
                                              const Text('Copier tout'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: AppTheme.error, size: 20),
                                              const SizedBox(width: 12),
                                              const Text('Supprimer'),
                                            ],
                                          ),
                                        ),
                                      ],
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
              
              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
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
                            Expanded(
                              child: Text(
                                _information!.titre,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.content_copy,
                                color: AppTheme.secondary,
                                size: 18,
                              ),
                              onPressed: () => _copierTexte(_information!.titre),
                              tooltip: 'Copier le titre',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      
                      // Date
                      Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[500], size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Enregistrée le ${_formatDate(_information!.dateCreation)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_information!.dateModification != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.grey[500], size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Modifiée le ${_formatDate(_information!.dateModification!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Section PDFs Associés (TOUT EN HAUT, avant les points)
                      if (_pdfList.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PDFs Générés (${_pdfList.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (_pdfList.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        color: AppTheme.secondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_pdfList.length} fichier${_pdfList.length > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Liste des PDFs
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: _pdfList.map((pdf) => _buildPdfCard(pdf)).toList(),
                          ),
                        ),
                      ],
                      
                      // Section Points
                      Container(
                        margin: EdgeInsets.only(top: _pdfList.isNotEmpty ? 0 : 24, bottom: 8),
                        child: Text(
                          'Points (${_information!.points.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      
                      // Liste des Points
                      Column(
                        children: _information!.points.asMap().entries.map((entry) {
                          final index = entry.key;
                          final point = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Numéro
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondary,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),
                                    
                                    // Contenu
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildPointAvecLiens(index, point),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.content_copy,
                                                  color: Colors.grey[500],
                                                  size: 16,
                                                ),
                                                onPressed: () => _copierTexte(point),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Copier ce point',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      // Images
                      if (_information!.images != null && _information!.images!.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text(
                            'Images (${_information!.images!.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _information!.images!.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showImagePreview(index),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: index < _information!.images!.length - 1 
                                        ? 12 
                                        : 0,
                                  ),
                                  width: 250,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(File(_information!.images![index])),
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
                                            '${index + 1}/${_information!.images!.length}',
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
                        if (_information!.images!.length > 1) ...[
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}