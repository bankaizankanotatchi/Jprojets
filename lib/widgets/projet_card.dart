import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/models/projet.dart';

class ProjetCard extends StatelessWidget {
  final Projet projet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onChangeStatus;
  
  const ProjetCard({
    Key? key,
    required this.projet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final tachesCompletees = projet.taches.where((t) => t.estCompletee).length;
    final progress = projet.taches.isEmpty ? 0.0 : tachesCompletees / projet.taches.length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec titre et menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      projet.titre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value.startsWith('status_')) {
                        final status = value.replaceFirst('status_', '');
                        onChangeStatus(status);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'status_en_attente',
                        child: Row(
                          children: [
                            Icon(Icons.pause_circle, color: AppTheme.statusEnAttente, size: 20),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text('En attente'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'status_en_cours',
                        child: Row(
                          children: [
                            Icon(Icons.play_circle, color: AppTheme.statusEnCours, size: 20),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text('En cours'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'status_termine',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.statusTermine, size: 20),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text('Terminé'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppTheme.error, size: 20),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(Icons.more_vert, size: 20),
                    ),
                  ),
                ],
              ),
              
              // Description
              if (projet.description != null && projet.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingSmall),
                  child: Text(
                    projet.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Statut et date
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        _getStatusText(projet.statut),
                        style: TextStyle(
                          color: _getStatusColor(projet.statut),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getStatusColor(projet.statut).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      'Créé le ${_formatDate(projet.dateCreation)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Progress bar
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${tachesCompletees}/${projet.taches.length} tâches',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXSmall),
                    
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(projet.statut),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXSmall),
                    
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Images preview
              if (projet.images != null && projet.images!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
                  child: SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: projet.images!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(
                            right: index < projet.images!.length - 1 ? AppTheme.spacingSmall : 0,
                          ),
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            image: DecorationImage(
                              image: FileImage(File(projet.images![index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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