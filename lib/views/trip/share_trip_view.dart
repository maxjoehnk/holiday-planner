import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/auth_service.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/sharing.dart';
import 'package:uuid/uuid.dart';

class ShareTripView extends StatefulWidget {
  final UuidValue tripId;
  final String tripName;
  /// `true` when the original owner deleted the trip and we're keeping
  /// the local snapshot read-only. Members can re-claim it; sharing
  /// actions don't work until they do.
  final bool isDetached;

  const ShareTripView({
    required this.tripId,
    required this.tripName,
    this.isDetached = false,
    super.key,
  });

  @override
  State<ShareTripView> createState() => _ShareTripViewState();
}

class _ShareTripViewState extends State<ShareTripView> {
  late final RefreshableData<List<TripMemberModel>> _members =
      RefreshableData<List<TripMemberModel>>(
    fetch: () => listTripMembers(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onTripMembersChanged(widget.tripId)],
  );
  late final RefreshableData<List<PendingInviteModel>> _invites =
      RefreshableData<List<PendingInviteModel>>(
    fetch: () => listOutboundInvites(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onTripMembersChanged(widget.tripId)],
  );

  @override
  void dispose() {
    _members.dispose();
    _invites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share trip')),
        body: const _SignInPrompt(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Share "${widget.tripName}"')),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isDetached) const _DetachedBanner(),
            Expanded(
              child: StreamBuilder<List<TripMemberModel>>(
                stream: _members.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data!;
                  return CustomScrollView(
                    slivers: [
                      SliverList.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _MemberTile(
                          tripId: widget.tripId,
                          member: members[i],
                          isDetached: widget.isDetached,
                        ),
                      ),
                      StreamBuilder<List<PendingInviteModel>>(
                        stream: _invites.stream,
                        builder: (context, snap) {
                          final invites = snap.data ?? const [];
                          if (invites.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            );
                          }
                          return SliverMainAxisGroup(
                            slivers: [
                              const SliverToBoxAdapter(
                                child: _SectionHeader(label: 'Pending invites'),
                              ),
                              SliverList.separated(
                                itemCount: invites.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) => _PendingInviteTile(
                                  tripId: widget.tripId,
                                  invite: invites[i],
                                  isDetached: widget.isDetached,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _InviteForm(
              tripId: widget.tripId,
              isDetached: widget.isDetached,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetachedBanner extends StatelessWidget {
  const _DetachedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This trip is read-only because the original owner deleted it. '
              'Sync it to your account to share again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PendingInviteTile extends StatelessWidget {
  final UuidValue tripId;
  final PendingInviteModel invite;
  final bool isDetached;

  const _PendingInviteTile({
    required this.tripId,
    required this.invite,
    required this.isDetached,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.mail_outline, color: theme.colorScheme.secondary),
      title: Text(invite.email),
      subtitle: Text(_formatRelativeInvited(invite.createdAt)),
      trailing: TextButton(
        onPressed: isDetached ? null : () => _revoke(context),
        child: const Text('Revoke'),
      ),
    );
  }

  Future<void> _revoke(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await revokeInvite(tripId: tripId, inviteId: invite.id);
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Revoke failed: $e')));
      }
    }
  }
}

String _formatRelativeInvited(DateTime when) {
  final delta = DateTime.now().toUtc().difference(when.toUtc());
  if (delta.inMinutes < 1) return 'Invited just now';
  if (delta.inHours < 1) {
    final m = delta.inMinutes;
    return 'Invited $m minute${m == 1 ? '' : 's'} ago';
  }
  if (delta.inDays < 1) {
    final h = delta.inHours;
    return 'Invited $h hour${h == 1 ? '' : 's'} ago';
  }
  if (delta.inDays < 30) {
    final d = delta.inDays;
    return 'Invited $d day${d == 1 ? '' : 's'} ago';
  }
  final months = (delta.inDays / 30).floor();
  if (months < 12) {
    return 'Invited $months month${months == 1 ? '' : 's'} ago';
  }
  final years = (delta.inDays / 365).floor();
  return 'Invited $years year${years == 1 ? '' : 's'} ago';
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Sign in from the home screen to share trips with other people.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UuidValue tripId;
  final TripMemberModel member;
  final bool isDetached;

  const _MemberTile({
    required this.tripId,
    required this.member,
    required this.isDetached,
  });

  String get _displayName =>
      member.displayName ?? member.email ?? member.userId.toString();

  String? get _subtitle {
    if (member.email == null || member.displayName == null) return null;
    return member.email;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle;
    return ListTile(
      leading: CircleAvatar(child: Text(_displayName.characters.first.toUpperCase())),
      title: Row(
        children: [
          Flexible(child: Text(_displayName + (member.isSelf ? ' (you)' : ''))),
          if (member.isOwner) ...[
            const SizedBox(width: 8),
            const _OwnerBadge(),
          ],
        ],
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: member.isOwner || isDetached
          ? null
          : PopupMenuButton<_MemberAction>(
              onSelected: (action) => _handle(context, action),
              itemBuilder: (context) => [
                if (member.isSelf)
                  const PopupMenuItem(
                    value: _MemberAction.leave,
                    child: Text('Leave trip'),
                  )
                else
                  const PopupMenuItem(
                    value: _MemberAction.remove,
                    child: Text('Remove'),
                  ),
              ],
            ),
    );
  }

  Future<void> _handle(BuildContext context, _MemberAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case _MemberAction.leave:
          await leaveTrip(tripId: tripId);
          if (context.mounted) Navigator.of(context).pop();
          break;
        case _MemberAction.remove:
          await removeTripMember(tripId: tripId, userId: member.userId);
          break;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

enum _MemberAction { leave, remove }

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Owner',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _InviteForm extends StatefulWidget {
  final UuidValue tripId;
  final bool isDetached;

  const _InviteForm({required this.tripId, required this.isDetached});

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await inviteTripMember(tripId: widget.tripId, email: email);
      _controller.clear();
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Invited $email — they\'ll see the trip the next time they sign in.',
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Invite failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDetached;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !disabled,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: disabled || _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Invite'),
          ),
        ],
      ),
    );
  }
}
