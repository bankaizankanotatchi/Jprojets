import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/services/database_service.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/widgets/gradient_button.dart';
import 'package:jprojets/widgets/image_picker_bottom_sheet.dart';
import 'dart:io';

class EditInformationScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final String infoId;

  const EditInformationScreen({
    Key? key,
    required this.databaseService,
    required this.infoId,
  }) : super(key: key);

  @override
  _EditInformationScreenState createState() => _EditInformationScreenState();
}

class _EditInformationScreenState extends State<EditInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final List<TextEditingController> _pointControllers = [];
  List<String> _images = [];
  bool _isLoading = false;
  late Information? _information;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chargerInformation();
  }

  void _chargerInformation() {
    final info = widget.databaseService.getInformationParId(widget.infoId);
    if (info != null) {
      setState(() {
        _information = info;
        _titreController.text = info.titre;
        _pointControllers.clear();
        _pointControllers.addAll(
          info.points.map((point) => TextEditingController(text: point)),
        );
        _images = List.from(info.images ?? []);
      });
    } else {
      setState(() {
        _information = null;
      });
    }
  }

  void _addPoint() {
    setState(() {
      _pointControllers.add(TextEditingController());
    });
  }

  void _removePoint(int index) {
    if (_pointControllers.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer ce point ?'),
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
                  _pointControllers.removeAt(index);
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

  Future<void> _mettreAJourInformation() async {
    if (_formKey.currentState!.validate() && _information != null) {
      final points = _pointControllers
          .map((c) => c.text.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      if (points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ajoutez au moins un point'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await widget.databaseService.updateInformation(
          id: widget.infoId,
          titre: _titreController.text.trim(),
          points: points,
          images: _images,
        );

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Information mise à jour avec succès'),
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

  void _supprimerToutesImages() {
    if (_images.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer toutes les images (${_images.length}) ?'),
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
                _images.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(int index) {
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
          title: const Text('Information non trouvée',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('L\'information n\'existe pas'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // AppBar fixe - Même structure que CreateInformationScreen
          Container(
            height: MediaQuery.of(context).padding.top + 70,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton retour
                            IconButton(
                              icon:
                                  const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                            ),
                            
                            // Titre centré
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Modifier l\'information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _information!.titre,
                                      style: TextStyle(
                                        fontSize: 12,
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
                                  color: Colors.white
                                      .withOpacity(_isLoading ? 0.1 : 0.2),
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
                              onPressed: _isLoading ? null : _mettreAJourInformation,
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
                            'Titre *',
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
                              hintText: 'Entrez le titre',
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
                                borderSide: BorderSide(color: AppTheme.secondary),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un titre';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Section Points
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
                            'Points à retenir',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          ..._pointControllers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final controller = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Numéro
                                  Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(top: 12),
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

                                  // Champ de texte
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            hintText: 'Point ${index + 1}',
                                            helperText: 'Vous pouvez inclure des liens (http://...)',
                                            helperStyle: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide:
                                                  BorderSide(color: Colors.grey[300]!),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide:
                                                  BorderSide(color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide:
                                                  BorderSide(color: AppTheme.secondary),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                            suffixIcon: _pointControllers.length > 1
                                                ? IconButton(
                                                    icon: Icon(
                                                      Icons.remove_circle,
                                                      color: AppTheme.error,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => _removePoint(index),
                                                    tooltip: 'Supprimer ce point',
                                                  )
                                                : null,
                                          ),
                                          maxLines: 3,
                                          minLines: 1,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Ce point ne peut pas être vide';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          
                          // Bouton Ajouter en bas - Même que CreateInformationScreen
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _addPoint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              minimumSize: const Size(double.infinity, 0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 8),
                                Text('Ajouter un point'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section Images - MODIFIÉ avec les nouvelles fonctionnalités
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
                                      backgroundColor: AppTheme.secondary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                    'Ajoutez des images si nécessaire',
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
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    // Section Informations (optionnel - garder uniquement si important)
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
                            'Informations',
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
                                label: 'Créée le',
                                value: _formatDate(_information!.dateCreation),
                              ),
                              const Spacer(),
                              _buildInfoItem(
                                icon: Icons.format_list_bulleted,
                                label: 'Points',
                                value: '${_information!.points.length}',
                              ),
                            ],
                          ),
                          if (_information!.dateModification != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildInfoItem(
                                icon: Icons.edit,
                                label: 'Dernière modification',
                                value: _formatDate(_information!.dateModification!),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Bouton d'enregistrement principal
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: _isLoading ? null : _mettreAJourInformation,
                      text: _isLoading ? 'Mise à jour...' : 'Mettre à jour',
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.secondary,
                          AppTheme.secondary.withOpacity(0.8),
                        ],
                      ),
                      icon: Icons.save,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      '* Champs obligatoires\nLes liens (http://...) seront cliquables',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titreController.dispose();
    for (var controller in _pointControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}