import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jprojets/theme/app_theme.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir une source',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: AppTheme.spacingLarge),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  context: context,
                  icon: Icons.camera_alt,
                  label: 'Appareil photo',
                  source: ImageSource.camera,
                ),
                
                _buildSourceButton(
                  context: context,
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  source: ImageSource.gallery,
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSourceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: IconButton(
            icon: Icon(icon, color: AppTheme.primary, size: 30),
            onPressed: () => Navigator.pop(context, source),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingSmall),
        
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}