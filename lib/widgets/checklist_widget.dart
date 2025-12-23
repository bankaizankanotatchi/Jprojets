import 'package:flutter/material.dart';
import 'package:jprojets/theme/app_theme.dart';

class ChecklistWidget extends StatefulWidget {
  final List<String> items;
  final Function(List<String>) onItemsChanged;
  final bool editable;

  const ChecklistWidget({
    Key? key,
    required this.items,
    required this.onItemsChanged,
    this.editable = true,
  }) : super(key: key);

  @override
  _ChecklistWidgetState createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  late List<ChecklistItem> _checklistItems;
  final TextEditingController _newItemController = TextEditingController();
  bool _isReorderable = false;

  @override
  void initState() {
    super.initState();
    _checklistItems = widget.items
        .map((item) => ChecklistItem(text: item, isCompleted: false))
        .toList();
  }

  @override
  void didUpdateWidget(ChecklistWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _checklistItems = widget.items
            .map((item) => ChecklistItem(text: item, isCompleted: false))
            .toList();
      });
    }
  }

  void _addItem() {
    if (_newItemController.text.trim().isEmpty) return;

    setState(() {
      _checklistItems.add(
        ChecklistItem(
          text: _newItemController.text.trim(),
          isCompleted: false,
        ),
      );
      _newItemController.clear();
    });

    _notifyParent();
  }

  void _removeItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });

    _notifyParent();
  }

  void _toggleItem(int index) {
    setState(() {
      _checklistItems[index].isCompleted = !_checklistItems[index].isCompleted;
    });
  }

  void _updateItem(int index, String newText) {
    if (newText.trim().isEmpty) {
      _removeItem(index);
      return;
    }

    setState(() {
      _checklistItems[index].text = newText.trim();
    });

    _notifyParent();
  }

  void _notifyParent() {
    final items = _checklistItems.map((item) => item.text).toList();
    widget.onItemsChanged(items);
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _checklistItems.removeAt(oldIndex);
      _checklistItems.insert(newIndex, item);
    });

    _notifyParent();
  }

  void _toggleReorderable() {
    setState(() {
      _isReorderable = !_isReorderable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _checklistItems.where((item) => item.isCompleted).length;
    final totalCount = _checklistItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checklist',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              
              Row(
                children: [
                  if (widget.editable && totalCount > 1)
                    IconButton(
                      icon: Icon(
                        _isReorderable ? Icons.done : Icons.reorder,
                        color: _isReorderable ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      onPressed: _toggleReorderable,
                      tooltip: _isReorderable ? 'Terminer le réarrangement' : 'Réarranger les items',
                    ),
                  
                  if (totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '$completedCount/$totalCount',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Liste des items
        if (_checklistItems.isNotEmpty)
          _isReorderable && widget.editable
            ? ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (int index = 0; index < _checklistItems.length; index++)
                    _buildReorderableChecklistItem(_checklistItems[index], index),
                ],
                onReorder: (oldIndex, newIndex) {
                  _reorderItems(oldIndex, newIndex);
                },
              )
            : Column(
                children: [
                  for (int index = 0; index < _checklistItems.length; index++)
                    _buildChecklistItem(_checklistItems[index], index),
                ],
              )
        else
          _buildEmptyState(),

        // Champ d'ajout
        if (widget.editable)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un item...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingSmall),
                
                FloatingActionButton.small(
                  onPressed: _addItem,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

        // Progress bar
        if (totalCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completedCount == totalCount
                        ? AppTheme.statusTermine
                        : AppTheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                
                const SizedBox(height: AppTheme.spacingXSmall),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${totalCount > 0 ? ((completedCount / totalCount) * 100).toStringAsFixed(0) : 0}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReorderableChecklistItem(ChecklistItem item, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey('checklist_item_$index'),
      index: index,
      child: _buildChecklistItemContent(item, index, true),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return Container(
      key: ValueKey('checklist_item_$index'),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: _buildChecklistItemContent(item, index, false),
    );
  }

  Widget _buildChecklistItemContent(ChecklistItem item, int index, bool isReorderable) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: AppTheme.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.border),
      ),
      child: widget.editable
          ? _buildEditableItem(item, index, isReorderable)
          : _buildReadOnlyItem(item),
    );
  }

  Widget _buildEditableItem(ChecklistItem item, int index, bool showDragHandle) {
    final textController = TextEditingController(text: item.text);
    final focusNode = FocusNode();

    return Row(
      children: [
        // Bouton drag (seulement en mode réarrangement)
        if (showDragHandle)
          const Icon(
            Icons.drag_handle,
            color: AppTheme.textTertiary,
            size: 20,
          ),

        // Checkbox
        GestureDetector(
          onTap: () => _toggleItem(index),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? AppTheme.statusTermine.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: item.isCompleted
                    ? AppTheme.statusTermine
                    : AppTheme.border,
                width: item.isCompleted ? 2 : 1,
              ),
            ),
            child: item.isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.statusTermine,
                  )
                : null,
          ),
        ),

        // Texte
        Expanded(
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              decoration: item.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: item.isCompleted
                  ? AppTheme.textTertiary
                  : AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
            onChanged: (value) => _updateItem(index, value),
            onSubmitted: (_) => focusNode.unfocus(),
            maxLines: 3,
            minLines: 1,
          ),
        ),

        // Bouton de suppression (seulement quand pas en mode réarrangement)
        if (!showDragHandle)
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppTheme.error,
              size: 20,
            ),
            onPressed: () => _removeItem(index),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildReadOnlyItem(ChecklistItem item) {
    return Row(
      children: [
        // Checkbox statique
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: item.isCompleted
                ? AppTheme.statusTermine.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: item.isCompleted
                  ? AppTheme.statusTermine
                  : AppTheme.border,
              width: item.isCompleted ? 2 : 1,
            ),
          ),
          child: item.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: AppTheme.statusTermine,
                )
              : null,
        ),

        // Texte
        Expanded(
          child: Text(
            item.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              decoration: item.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: item.isCompleted
                  ? AppTheme.textTertiary
                  : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rtl,
            color: AppTheme.textTertiary,
            size: 48,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Checklist vide',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            widget.editable
                ? 'Ajoutez des items à votre checklist'
                : 'Aucun item dans cette checklist',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }
}

class ChecklistItem {
  String text;
  bool isCompleted;

  ChecklistItem({
    required this.text,
    required this.isCompleted,
  });
}