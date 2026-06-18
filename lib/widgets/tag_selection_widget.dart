import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/tags.dart';
import 'package:holiday_planner/src/rust/commands/create_tag.dart';
import 'package:holiday_planner/src/rust/models.dart';

class TagSelectionWidget extends StatefulWidget {
  final List<TagModel> selectedTags;
  final Function(List<TagModel>) onTagsChanged;

  const TagSelectionWidget({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  State<TagSelectionWidget> createState() => _TagSelectionWidgetState();
}

class _TagSelectionWidgetState extends State<TagSelectionWidget> {
  List<TagModel> _allTags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await getAllTags();
      setState(() {
        _allTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tags",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateTagDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("New Tag"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContent(colorScheme, textTheme),
      ],
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                "Failed to load tags",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loadTags,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_allTags.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.label_outline,
                color: colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                "No tags available",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Create your first tag",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allTags.map((tag) => _TagChip(
          tag: tag,
          isSelected: widget.selectedTags.any((t) => t.id == tag.id),
          onToggle: () => _toggleTag(tag),
          onRename: () => _renameTag(tag),
          onDelete: () => _deleteTag(tag),
        )).toList(),
      ),
    );
  }

  void _toggleTag(TagModel tag) {
    final selectedTags = List<TagModel>.from(widget.selectedTags);
    final isSelected = selectedTags.any((t) => t.id == tag.id);

    if (isSelected) {
      selectedTags.removeWhere((t) => t.id == tag.id);
    } else {
      selectedTags.add(tag);
    }

    widget.onTagsChanged(selectedTags);
  }

  Future<void> _showCreateTagDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CreateTagDialog(),
    );

    if (result != null) {
      _loadTags(); // Refresh the tag list
    }
  }

  Future<void> _renameTag(TagModel tag) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: tag.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tag name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == tag.name) return;
    try {
      final renamed = await renameTag(tagId: tag.id, newName: trimmed);
      // Reflect the swap in the parent's selectedTags too: if the
      // user had the old tag picked on this trip, the rename also
      // re-tagged the trip on the server, so the new id should
      // replace the old in the picker state.
      if (widget.selectedTags.any((t) => t.id == tag.id)) {
        final next = widget.selectedTags
            .where((t) => t.id != tag.id)
            .toList()
          ..add(renamed);
        widget.onTagsChanged(next);
      }
      await _loadTags();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Rename failed: $e')));
    }
  }

  Future<void> _deleteTag(TagModel tag) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${tag.name}"?'),
        content: const Text(
          'The tag will be removed from your library and from every trip you own. '
          'Trips owned by other people that use this tag aren\'t affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteTag(tagId: tag.id);
      if (widget.selectedTags.any((t) => t.id == tag.id)) {
        widget.onTagsChanged(
          widget.selectedTags.where((t) => t.id != tag.id).toList(),
        );
      }
      await _loadTags();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _TagChip extends StatelessWidget {
  final TagModel tag;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: FilterChip(
        label: Text(tag.name),
        selected: isSelected,
        onSelected: (_) => onToggle(),
        avatar: Icon(
          Icons.label,
          size: 16,
          color: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.secondaryContainer,
        checkmarkColor: colorScheme.onSecondaryContainer,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                tag.name,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                onRename();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTagDialog extends StatefulWidget {
  @override
  State<_CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<_CreateTagDialog> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Tag"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Tag Name",
            hintText: "e.g., Beach, City, Adventure",
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter a tag name";
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _createTag,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Create"),
        ),
      ],
    );
  }

  Future<void> _createTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await createTag(
        command: CreateTag(name: _nameController.text.trim()),
      );
      Navigator.pop(context, _nameController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create tag: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
}
