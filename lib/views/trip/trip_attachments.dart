
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';

class TripAttachments extends StatelessWidget {
  final Trip trip;

  const TripAttachments({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    if (trip.attachments.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text("No Attachments"),
        ),
      );
    }
    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            var attachment = trip.attachments[index];
            return ListTile(
              leading: _fileIcon(attachment),
              title: Text(attachment.name),
              subtitle: Text(attachment.fileName),
              trailing: IconButton(onPressed: () {
                deleteAttachment(attachmentId: attachment.id);
              }, icon: const Icon(Icons.delete)),
              onTap: () => _openAttachment(attachment),
            );
          },
          childCount: trip.attachments.length,
        ));
  }

  _openAttachment(TripAttachment attachment) async {
    String dir = (await getTemporaryDirectory()).path;
    String path = "$dir/${attachment.fileName}";
    await readAttachment(attachmentId: attachment.id, targetPath: path);
    await OpenAppFile.open(path);
  }

  Widget? _fileIcon(TripAttachment attachment) {
    if (attachment.contentType == "application/pdf") {
      return const Icon(Bootstrap.filetype_pdf);
    }
    if (attachment.contentType.startsWith("image")) {
      return const Icon(Bootstrap.image);
    }
    return null;
  }
}
