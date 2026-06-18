import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/sync.dart' as rust_sync;

/// Lists mutations the push worker has given up on (`attempts >=
/// MAX_ATTEMPTS`). The user / developer can inspect the last error and
/// either retry the mutation (resets attempts to 0) or discard it.
class StuckMutationsView extends StatefulWidget {
  const StuckMutationsView({super.key});

  @override
  State<StuckMutationsView> createState() => _StuckMutationsViewState();
}

class _StuckMutationsViewState extends State<StuckMutationsView> {
  late Future<List<rust_sync.DeadLetter>> _future = rust_sync.listDeadLetters();

  void _refresh() {
    setState(() {
      _future = rust_sync.listDeadLetters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stuck mutations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<rust_sync.DeadLetter>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Failed to load: ${snap.error}'));
            }
            final rows = snap.data ?? const [];
            if (rows.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _DeadLetterTile(
                row: rows[i],
                onChanged: _refresh,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No stuck mutations.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Edits the sync worker had to give up on would show here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadLetterTile extends StatelessWidget {
  final rust_sync.DeadLetter row;
  final VoidCallback onChanged;
  const _DeadLetterTile({required this.row, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = '${row.operation} · ${row.entityType}';
    return ExpansionTile(
      leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text(title),
      subtitle: Text(
        '${row.attempts} attempts · ${_relative(row.createdAt)}',
        style: theme.textTheme.bodySmall,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          row.lastError ?? '(no error message captured)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _retry(context),
              child: const Text('Retry'),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _discard(context),
              child: const Text('Discard'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _retry(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await rust_sync.retryDeadLetter(mutationId: row.id);
      onChanged();
    } catch (e, stack) {
      log('retryDeadLetter failed: $e', stackTrace: stack);
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Retry failed: $e')));
      }
    }
  }

  Future<void> _discard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard mutation?'),
        content: const Text(
          'The change will not be pushed to the cloud. Local state stays as it is.',
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
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await rust_sync.discardDeadLetter(mutationId: row.id);
      onChanged();
    } catch (e, stack) {
      log('discardDeadLetter failed: $e', stackTrace: stack);
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Discard failed: $e')));
      }
    }
  }
}

String _relative(DateTime when) {
  final delta = DateTime.now().toUtc().difference(when.toUtc());
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  return '${delta.inDays}d ago';
}
