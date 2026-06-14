import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/auth_service.dart';
import 'package:holiday_planner/src/rust/api/sync.dart' as rust_sync;
import 'package:holiday_planner/views/trip/trip_activity_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Compact sync indicator/button for a single trip card.
///
/// * Anonymous users see nothing — sharing is gated on sign-in.
/// * Signed in + trip not yet uploaded → cloud-upload icon. Tap prompts
///   the user to confirm and then claims the trip for their account.
/// * Signed in + trip already linked → a quiet cloud-done indicator.
class TripSyncChip extends StatefulWidget {
  final UuidValue tripId;
  final String tripName;
  final UuidValue? ownerId;
  final bool isDetached;

  const TripSyncChip({
    required this.tripId,
    required this.tripName,
    required this.ownerId,
    this.isDetached = false,
    super.key,
  });

  @override
  State<TripSyncChip> createState() => _TripSyncChipState();
}

class _TripSyncChipState extends State<TripSyncChip> {
  bool _uploading = false;

  Future<void> _handleDetached(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<_DetachedChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No longer in your account'),
        content: const Text(
          'The trip\'s previous owner removed it from the cloud. This '
          'device still has the last fetched snapshot. You can keep '
          'browsing it locally, or claim it under your account so it '
          'syncs to your other devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DetachedChoice.dismiss),
            child: const Text('Keep local only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DetachedChoice.upload),
            child: const Text('Sync to my account'),
          ),
        ],
      ),
    );
    if (choice != _DetachedChoice.upload) return;

    setState(() => _uploading = true);
    try {
      await rust_sync.uploadTrip(tripId: widget.tripId);
      messenger.showSnackBar(
        SnackBar(content: Text('Syncing "${widget.tripName}" to your account…')),
      );
    } catch (error, stack) {
      log('uploadTrip (detached) failed: $error', stackTrace: stack);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync "${widget.tripName}"?'),
        content: const Text(
          'This trip will be linked to your account, synced to your other devices, '
          'and become shareable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _uploading = true);
    try {
      await rust_sync.uploadTrip(tripId: widget.tripId);
      messenger.showSnackBar(
        SnackBar(content: Text('Syncing "${widget.tripName}"…')),
      );
    } catch (error, stack) {
      log('uploadTrip failed: $error', stackTrace: stack);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.changes,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        // Anonymous users get nothing — sync is sign-in-only.
        if (snapshot.data == null) {
          return const SizedBox.shrink();
        }

        if (widget.isDetached) {
          return _ChipShell(
            tooltip: 'No longer in your account',
            onTap: _uploading
                ? null
                : () => _handleDetached(context),
            child: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.cloud_off_outlined,
                    size: 18,
                    color: Colors.amber,
                  ),
          );
        }

        if (widget.ownerId == null) {
          return _ChipShell(
            tooltip: 'Sync this trip',
            onTap: _uploading ? null : _confirmAndUpload,
            child: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
          );
        }

        return _ChipShell(
          tooltip: 'Recent activity',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripActivityView(
                tripId: widget.tripId,
                tripName: widget.tripName,
              ),
            ),
          ),
          child: const Icon(
            Icons.cloud_done_outlined,
            size: 18,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

enum _DetachedChoice { dismiss, upload }

class _ChipShell extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;

  const _ChipShell({required this.child, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    );
  }
}
