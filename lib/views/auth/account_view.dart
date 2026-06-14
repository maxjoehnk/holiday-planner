import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/auth_service.dart';
import 'package:holiday_planner/src/rust/api/sync.dart' as rust_sync;
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  bool _deleting = false;
  rust_sync.MyProfile? _profile;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await rust_sync.getMyProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _profileLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: AuthService.instance.changes,
          initialData: AuthService.instance.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              // Signed out (e.g. from another tab or via delete) — close.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) Navigator.pop(context);
              });
              return const SizedBox.shrink();
            }
            final displayName = _profile?.displayName;
            final email = _profile?.email ?? user.email ?? user.id;
            return ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Signed in as'),
                  subtitle: Text(email),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Display name'),
                  subtitle: _profileLoading
                      ? const Text('Loading…')
                      : Text(displayName ?? 'Not set'),
                  trailing: _profileLoading
                      ? null
                      : const Icon(Icons.edit_outlined),
                  onTap: _profileLoading || _deleting
                      ? null
                      : () => _editDisplayName(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: _deleting ? null : () => _confirmSignOut(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  title: Text(
                    'Delete account',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text(
                    'Removes all data from the cloud. Local trips stay but are unlinked.',
                  ),
                  trailing: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _deleting ? null : () => _confirmDelete(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: _profile?.displayName ?? '');
    final next = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Shown to people you share trips with',
          ),
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
    if (next == null) return;
    try {
      await rust_sync.updateMyProfile(displayName: next);
      await _loadProfile();
    } catch (error, stack) {
      log('updateMyProfile failed: $error', stackTrace: stack);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to save: $error')),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your trips stay on this device. Sign back in to keep syncing across devices.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.signOut();
    navigator.pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your account and every trip you created '
          'from the cloud. Other members lose access too. The local copies on '
          'this device stay, but get unlinked — you can keep editing them '
          'offline or sync them again under a new account later.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await rust_sync.deleteAccount();
      messenger.showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
      navigator.pop();
    } catch (error, stack) {
      log('deleteAccount failed: $error', stackTrace: stack);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete account: $error')),
        );
        setState(() => _deleting = false);
      }
    }
  }
}
