import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
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
              child: _buildAttachmentCard(context, attachment),
            );
          },
          childCount: attachments.length,
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context, AttachmentListModel attachment) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openAttachment(attachment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileTypeColor(attachment).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileTypeIcon(attachment),
                  size: 24,
                  color: _getFileTypeColor(attachment),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attachment.fileName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: ask for confirmation
                  deleteAttachment(attachmentId: attachment.id)
                      .then((_) => refresh());
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                tooltip: "Delete attachment",
              ),
            ],
          ),
        ),
      ),
    );
  }

  _openAttachment(AttachmentListModel attachment) async {
    String dir = (await getTemporaryDirectory()).path;
    String path = "$dir/${attachment.fileName}";
    await readAttachment(attachmentId: attachment.id, targetPath: path);
    await OpenAppFile.open(path);
  }

  IconData _getFileTypeIcon(AttachmentListModel attachment) {
    if (attachment.contentType == "application/pdf") {
      return Bootstrap.filetype_pdf;
    }
    if (attachment.contentType.startsWith("image")) {
      return Bootstrap.image;
    }
    if (attachment.contentType.startsWith("text")) {
      return Icons.description_outlined;
    }
    if (attachment.contentType.contains("word") || attachment.contentType.contains("document")) {
      return Bootstrap.filetype_doc;
    }
    if (attachment.contentType.contains("excel") || attachment.contentType.contains("spreadsheet")) {
      return Bootstrap.filetype_xls;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _getFileTypeColor(AttachmentListModel attachment) {
    if (attachment.contentType == "application/pdf") {
      return Colors.red;
    }
    if (attachment.contentType.startsWith("image")) {
      return Colors.green;
    }
    if (attachment.contentType.startsWith("text")) {
      return Colors.blue;
    }
    if (attachment.contentType.contains("word") || attachment.contentType.contains("document")) {
      return Colors.blue;
    }
    if (attachment.contentType.contains("excel") || attachment.contentType.contains("spreadsheet")) {
      return Colors.green;
    }
    return Colors.grey;
  }
}
