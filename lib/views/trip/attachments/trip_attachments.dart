import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/widgets/attachment_card.dart';
import 'package:uuid/uuid.dart';

class TripAttachments extends StatefulWidget {
  final UuidValue tripId;

  const TripAttachments({super.key, required this.tripId});

  @override
  State<TripAttachments> createState() => _TripAttachmentsState();
}

class _TripAttachmentsState extends State<TripAttachments> {
  late StreamController<List<AttachmentListModel>> _attachments;
  late Stream<List<AttachmentListModel>>? _attachments$;

  @override
  void initState() {
    super.initState();
    _attachments = StreamController();
    _attachments$ = _attachments.stream;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: _attachments$, builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
      }
      return TripAttachmentList(attachments: snapshot.data ?? [], refresh: () => _fetch(),);
    });
  }

  _fetch() {
    _attachments.addStream(getTripAttachments(tripId: widget.tripId).asStream());
  }
}

class TripAttachmentList extends StatelessWidget {
  final List<AttachmentListModel> attachments;
  final Function() refresh;

  const TripAttachmentList({super.key, required this.attachments, required this.refresh});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.attachment_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                "No attachments",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                "Add files to keep important documents with your trip",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            var attachment = attachments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AttachmentCard(attachment: attachment, onDelete: () => deleteAttachment(attachmentId: attachment.id).then((_) => refresh())),
            );
          },
          childCount: attachments.length,
        ),
      ),
    );
  }
}
