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
            child: Text("Error: ${snapshot.error}"),
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
      return const SliverFillRemaining(
        child: Center(
          child: Text("No Attachments"),
        ),
      );
    }
    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            var attachment = attachments[index];
            return ListTile(
              leading: _fileIcon(attachment),
              title: Text(attachment.name),
              subtitle: Text(attachment.fileName),
              trailing: IconButton(onPressed: () {
                // TODO: ask for confirmation
                deleteAttachment(attachmentId: attachment.id)
                  .then((_) => refresh());
              }, icon: const Icon(Icons.delete)),
              onTap: () => _openAttachment(attachment),
            );
          },
          childCount: attachments.length,
        ));
  }

  _openAttachment(AttachmentListModel attachment) async {
    String dir = (await getTemporaryDirectory()).path;
    String path = "$dir/${attachment.fileName}";
    await readAttachment(attachmentId: attachment.id, targetPath: path);
    await OpenAppFile.open(path);
  }

  Widget? _fileIcon(AttachmentListModel attachment) {
    if (attachment.contentType == "application/pdf") {
      return const Icon(Bootstrap.filetype_pdf);
    }
    if (attachment.contentType.startsWith("image")) {
      return const Icon(Bootstrap.image);
    }
    return null;
  }
}
