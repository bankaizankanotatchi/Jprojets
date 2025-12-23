import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Pour Clipboard
import 'package:jprojets/theme/app_theme.dart';

class LinkActionsBottomSheet extends StatelessWidget {
  final String url;
  final String? linkTitle; // Optionnel : titre du lien à afficher
  
  const LinkActionsBottomSheet({
    Key? key,
    required this.url,
    this.linkTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Uri uri;
    
    try {
      // Essayer de parser l'URL
      uri = Uri.parse(url);
    } catch (e) {
      // Si l'URL est invalide
      return _buildErrorSheet(context, "URL invalide");
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            topRight: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Aperçu du lien (optionnel)
            if (linkTitle != null) ...[
              Text(
                linkTitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
            ],
            
            // URL tronquée
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                _truncateUrl(url),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLarge),
            
            // Boutons d'actions
            _buildActionTile(
              context: context,
              icon: Icons.open_in_browser,
              title: 'Ouvrir le lien',
              subtitle: 'Ouvrir dans le navigateur',
              onTap: () => _openLink(context, uri),
            ),
            
            const Divider(height: AppTheme.spacingMedium),
            
            _buildActionTile(
              context: context,
              icon: Icons.content_copy,
              title: 'Copier le lien',
              subtitle: 'Copier dans le presse-papier',
              onTap: () => _copyLink(context, url),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Bouton Annuler
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSheet(BuildContext context, String errorMessage) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingMedium),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        Navigator.pop(context); // Fermer le bottom sheet
      } else {
        _showErrorSnackbar(context, 'Impossible d\'ouvrir ce lien');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      _showSuccessSnackbar(context, 'Lien copié !');
      Navigator.pop(context); // Fermer le bottom sheet
    } catch (e) {
      _showErrorSnackbar(context, 'Erreur lors de la copie');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  String _truncateUrl(String url) {
    const maxLength = 50;
    if (url.length <= maxLength) return url;
    
    return '${url.substring(0, maxLength - 3)}...';
  }
}