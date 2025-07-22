import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';

class AttachmentCard extends StatelessWidget {
  final AttachmentListModel attachment;
  final Function() onDelete;

  const AttachmentCard({super.key, required this.attachment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                onPressed: onDelete,
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
