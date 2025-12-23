import 'package:flutter/material.dart';
import 'package:jprojets/models/tache.dart';
import 'package:jprojets/theme/app_theme.dart';
import 'package:jprojets/widgets/sous_tache_widget.dart';

class TacheWidget extends StatefulWidget {
  final Tache tache;
  final VoidCallback onToggle;
  final Function(String) onToggleSousTache;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback? onEditTitle;
  
  const TacheWidget({
    Key? key,
    required this.tache,
    required this.onToggle,
    required this.onToggleSousTache,
    required this.onDelete,
    required this.onTap,
    this.onEditTitle,
  }) : super(key: key);
  
  @override
  _TacheWidgetState createState() => _TacheWidgetState();
}

class _TacheWidgetState extends State<TacheWidget> {
  bool _expanded = false;
  bool _isDeleting = false;
  
  void _handleDelete() {
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.tache.estCompletee 
                            ? AppTheme.statusTermine.withOpacity(0.2)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.tache.estCompletee 
                              ? AppTheme.statusTermine
                              : AppTheme.border,
                          width: widget.tache.estCompletee ? 2 : 1,
                        ),
                      ),
                      child: widget.tache.estCompletee
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.statusTermine,
                            )
                          : null,
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.spacingMedium),
                  
                  // Titre avec bouton d'édition
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.tache.titre,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              decoration: widget.tache.estCompletee
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: widget.tache.estCompletee
                                  ? AppTheme.textTertiary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.onEditTitle != null)
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppTheme.primary,
                              size: 16,
                            ),
                            onPressed: widget.onEditTitle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                  
                  // Bouton de suppression
                  IconButton(
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.delete_outline,
                            color: AppTheme.error,
                            size: 20,
                          ),
                    onPressed: _isDeleting ? null : _handleDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  
                  // Bouton expand/collapse pour sous-tâches
                  if (widget.tache.sousTaches != null && widget.tache.sousTaches!.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              // Description
              if (widget.tache.description != null && widget.tache.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingSmall,
                    left: 40, // Align with title
                  ),
                  child: Text(
                    widget.tache.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              
              // Sous-tâches
              if (_expanded && widget.tache.sousTaches != null && widget.tache.sousTaches!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingMedium,
                    left: 40,
                  ),
                  child: Column(
                    children: widget.tache.sousTaches!.map((sousTache) {
                      return SousTacheWidget(
                        sousTache: sousTache,
                        onToggle: () => widget.onToggleSousTache(sousTache.id),
                      );
                    }).toList(),
                  ),
                ),
              
              // Checklist
              if (widget.tache.checklist != null && widget.tache.checklist!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingMedium,
                    left: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checklist:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXSmall),
                      ...widget.tache.checklist!.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacingXSmall),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: AppTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              
              // Statistiques
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
                child: Row(
                  children: [
                    if (widget.tache.sousTaches != null && widget.tache.sousTaches!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.list, size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            '${widget.tache.sousTaches!.where((st) => st.estCompletee).length}/${widget.tache.sousTaches!.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                        ],
                      ),
                    
                    if (widget.tache.checklist != null && widget.tache.checklist!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.checklist, size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            '${widget.tache.checklist!.length} items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    
                    const Spacer(),
                    
                    Text(
                      'Créée le ${_formatDate(widget.tache.dateCreation)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}