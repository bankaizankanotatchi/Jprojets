import 'package:flutter/material.dart';
import 'package:jprojets/models/sous_tache.dart';
import 'package:jprojets/theme/app_theme.dart';

class SousTacheWidget extends StatelessWidget {
  final SousTache sousTache;
  final VoidCallback onToggle;
  
  const SousTacheWidget({
    Key? key,
    required this.sousTache,
    required this.onToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: sousTache.estCompletee 
                    ? AppTheme.statusTermine.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: sousTache.estCompletee 
                      ? AppTheme.statusTermine
                      : AppTheme.textTertiary,
                  width: 1,
                ),
              ),
              child: sousTache.estCompletee
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppTheme.statusTermine,
                    )
                  : null,
            ),
          ),
          
          // Titre
          Expanded(
            child: Text(
              sousTache.titre,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: sousTache.estCompletee
                    ? TextDecoration.lineThrough
                    : null,
                color: sousTache.estCompletee
                    ? AppTheme.textTertiary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          
          // Date
          Text(
            _formatDate(sousTache.dateCreation),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}