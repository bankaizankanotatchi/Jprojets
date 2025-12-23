import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/screens/informations/edit_information_screen.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/widgets/link_actions_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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
  
  @override
  void initState() {
    super.initState();
    _chargerInformation();
  }
  
  void _chargerInformation() {
    setState(() {
      _information = widget.databaseService.getInformationParId(widget.infoId);
    });
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
  
  Future<void> _ouvrirLien(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir ce lien'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL invalide'),
          backgroundColor: AppTheme.error,
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
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // CHANGEMENT : Utiliser Column au lieu de CustomScrollView
      body: Column(
        children: [
          // AppBar fixe
          Container(
            height: MediaQuery.of(context).padding.top + 70, // Inclut la barre de statut
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
                            Text(
                              'Détail',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // Boutons à droite
                            Row(
                              children: [
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
                                    ).then((_) => _chargerInformation());
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
                                    }
                                  },
                                  itemBuilder: (context) => [
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
                  
                  // Section Points
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
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
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                
                                const SizedBox(width: 12),
                                
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
                  
                  // Images - MODIFIÉ pour ajouter les previews
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
                    
                    // Indicateurs sous les images (optionnel)
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
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}