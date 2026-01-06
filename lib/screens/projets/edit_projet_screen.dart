import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/widgets/gradient_button.dart';
import 'package:jprojets/widgets/image_picker_bottom_sheet.dart';
import 'dart:io';

class EditProjetScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String projetId;

  const EditProjetScreen({
    Key? key,
    required this.databaseService,
    required this.projetId,
  }) : super(key: key);

  @override
  _EditProjetScreenState createState() => _EditProjetScreenState();
}

class _EditProjetScreenState extends State<EditProjetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _images = [];
  String _selectedStatut = 'en_attente';
  bool _isLoading = false;
  late Projet? _projet;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chargerProjet();
  }

  void _chargerProjet() {
    final projet = widget.databaseService.getProjetParId(widget.projetId);
    if (projet != null) {
      setState(() {
        _projet = projet;
        _titreController.text = projet.titre;
        _descriptionController.text = projet.description ?? '';
        _images = List.from(projet.images ?? []);
        _selectedStatut = projet.statut;
      });
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => ImagePickerBottomSheet(),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _images.add(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _mettreAJourProjet() async {
    if (_formKey.currentState!.validate() && _projet != null) {
      setState(() => _isLoading = true);

      try {
        await widget.databaseService.updateProjet(
          id: widget.projetId,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          images: _images,
          statut: _selectedStatut,
        );

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Projet mis à jour avec succès'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette image ?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _images.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(int index) {
    if (_images.isEmpty) return;
    
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
                    File(_images[index]),
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
                  '${index + 1}/${_images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Bouton supprimer depuis la preview
            Positioned(
              bottom: 10,
              right: 10,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    _removeImage(index);
                  },
                ),
              ),
            ),
            // Navigation entre les images
            if (_images.length > 1) ...[
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
                  child: index < _images.length - 1
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // CHANGEMENT : Utiliser Column au lieu de CustomScrollView
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
                        // Première ligne : Bouton retour et bouton enregistrer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton retour
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                            ),
                            
                            // Titre et sous-titre
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modifier le projet',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _projet!.titre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Bouton enregistrer
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(_isLoading ? 0.1 : 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: _isLoading 
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        Icons.save,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                              onPressed: _isLoading ? null : _mettreAJourProjet,
                              tooltip: 'Enregistrer',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Titre
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
                          Text(
                            'Titre du projet *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titreController,
                            decoration: InputDecoration(
                              hintText: 'Entrez le titre du projet',
                              filled: true,
                              fillColor: Colors.grey[50],
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un titre';
                              }
                              return null;
                            },
                            maxLines: 3,
                            minLines: 2,
                          ),
                        ],
                      ),
                    ),

                    // Section Description
                    const SizedBox(height: 16),
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
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Décrivez votre projet...',
                              helperText: 'Vous pouvez inclure des liens (http://...)',
                              helperStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 5,
                            minLines: 3,
                          ),
                        ],
                      ),
                    ),

                    // Section Statut
                    const SizedBox(height: 16),
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
                          Text(
                            'Statut',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatutButton(
                                  'en_attente',
                                  'En attente',
                                  Icons.pending,
                                  AppTheme.statusEnAttente,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatutButton(
                                  'en_cours',
                                  'En cours',
                                  Icons.play_arrow,
                                  AppTheme.statusEnCours,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatutButton(
                                  'termine',
                                  'Terminé',
                                  Icons.check_circle,
                                  AppTheme.statusTermine,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Section Images - MODIFIÉ avec preview
                    const SizedBox(height: 16),
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
                                'Images',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _pickImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add, size: 16),
                                        SizedBox(width: 4),
                                        Text('Ajouter'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_images.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucune image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ajoutez des images pour illustrer votre projet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _images.asMap().entries.map((entry) {
                                final index = entry.key;
                                final path = entry.value;
                                return GestureDetector(
                                  onTap: () => _showImagePreview(index),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(path)),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Icône de zoom
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.zoom_in,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    // Informations du projet
                    const SizedBox(height: 16),
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
                          Text(
                            'Informations du projet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoItem(
                                icon: Icons.calendar_today,
                                label: 'Créé le',
                                value: _formatDate(_projet!.dateCreation),
                              ),
                              const Spacer(),
                              _buildInfoItem(
                                icon: Icons.checklist,
                                label: 'Tâches',
                                value: '${_projet!.taches.length}',
                              ),
                            ],
                          ),
                          if (_projet!.dateModification != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildInfoItem(
                                icon: Icons.edit,
                                label: 'Dernière modification',
                                value: _formatDate(_projet!.dateModification!),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Bouton d'enregistrement
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: _isLoading ? null : _mettreAJourProjet,
                      text: _isLoading ? 'Mise à jour...' : 'Mettre à jour',
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primaryDark,
                        ],
                      ),
                      icon: Icons.save,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      '* Champs obligatoires',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    // Espace en bas pour éviter les débordements
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutButton(String value, String text, IconData icon, Color color) {
    final isSelected = _selectedStatut == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedStatut = value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}