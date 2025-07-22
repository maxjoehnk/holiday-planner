import 'dart:async';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/accommodations.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/commands/update_trip_accommodation.dart';
import 'package:holiday_planner/src/rust/commands/add_accommodation_attachment.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/widgets/accommodation_summary_card.dart';
import 'package:holiday_planner/widgets/date_time_picker.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';

class EditAccommodation extends StatefulWidget {
  final AccommodationModel accommodation;

  const EditAccommodation({super.key, required this.accommodation});

  @override
  State<EditAccommodation> createState() => _EditAccommodationState();
}

class _EditAccommodationState extends State<EditAccommodation> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  late DateTime checkInDate;
  late DateTime checkOutDate;
  bool _isLoading = false;
  String? _errorMessage;

  // Attachment related state
  late StreamController<List<AttachmentListModel>> _attachments;
  late Stream<List<AttachmentListModel>>? _attachments$;
  bool _isAddingAttachment = false;
  final TextEditingController _attachmentNameController = TextEditingController();
  XFile? _attachmentFile;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.accommodation.name;
    _addressController.text = widget.accommodation.address ?? '';
    checkInDate = widget.accommodation.checkIn.toLocal();
    checkOutDate = widget.accommodation.checkOut.toLocal();

    // Initialize attachment related state
    _attachments = StreamController();
    _attachments$ = _attachments.stream;
    _fetchAttachments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _attachmentNameController.dispose();
    _attachments.close();
    super.dispose();
  }

  void _fetchAttachments() {
    _attachments.addStream(
      getAccommodationAttachments(accommodationId: widget.accommodation.id).asStream()
    );
  }

  Future<void> _addAttachment() async {
    if (_attachmentFile == null) {
      setState(() {
        _errorMessage = "Please select a file to attach";
      });
      return;
    }

    if (_attachmentNameController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a name for the attachment";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await addAccommodationAttachment(
        command: AddAccommodationAttachment(
          name: _attachmentNameController.text,
          accommodationId: widget.accommodation.id,
          path: _attachmentFile!.path,
        ),
      );

      // Reset attachment form
      setState(() {
        _isAddingAttachment = false;
        _attachmentNameController.clear();
        _attachmentFile = null;
      });

      // Refresh attachments list
      _fetchAttachments();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add attachment: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeAttachment(AttachmentListModel attachment) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await removeAccommodationAttachment(
        accommodationId: widget.accommodation.id,
        attachmentId: attachment.id,
      );

      // Refresh attachments list
      _fetchAttachments();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to remove attachment: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAttachment(AttachmentListModel attachment) async {
    try {
      String dir = (await getTemporaryDirectory()).path;
      String path = "$dir/${attachment.fileName}";
      await readAttachment(attachmentId: attachment.id, targetPath: path);
      await OpenAppFile.open(path);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to open attachment: ${e.toString()}";
      });
    }
  }

  Future<void> _pickAttachmentFile() async {
    try {
      var pickedFile = await openFile();
      if (pickedFile == null) {
        return;
      }
      setState(() {
        _attachmentFile = pickedFile;
        _errorMessage = null; // Clear any previous errors
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to select file: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Accommodation"),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Save"),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                "Accommodation Details",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Name",
                  hintText: "Hotel, Airbnb, etc.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.hotel_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Address (Optional)",
                  hintText: "Street address or location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Check-in & Check-out",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildDateTimeCard(
                context,
                title: "Check-in",
                subtitle: "When you'll arrive",
                icon: Icons.login,
                dateTime: checkInDate,
                onDateTimeChanged: (newDateTime) {
                  setState(() {
                    checkInDate = newDateTime;
                  });
                },
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildDateTimeCard(
                context,
                title: "Check-out",
                subtitle: "When you'll leave",
                icon: Icons.logout,
                dateTime: checkOutDate,
                onDateTimeChanged: (newDateTime) {
                  setState(() {
                    checkOutDate = newDateTime;
                  });
                },
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              AccommodationSummaryCard(checkInDate: checkInDate, checkOutDate: checkOutDate),
              const SizedBox(height: 24),

              // Attachments section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Attachments",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _isAddingAttachment = true;
                        _attachmentNameController.clear();
                        _attachmentFile = null;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add attachment form
              if (_isAddingAttachment) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add New Attachment",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _attachmentNameController,
                          decoration: InputDecoration(
                            labelText: "Name",
                            hintText: "Enter attachment name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _attachmentFile != null
                                ? colorScheme.primaryContainer.withOpacity(0.3)
                                : colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _attachmentFile != null
                                  ? colorScheme.primary.withOpacity(0.5)
                                  : colorScheme.outlineVariant,
                              width: _attachmentFile != null ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_attachmentFile != null) ...[
                                Text(
                                  _attachmentFile!.name,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _pickAttachmentFile,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Choose Different File"),
                                ),
                              ] else ...[
                                FilledButton.icon(
                                  onPressed: _pickAttachmentFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text("Choose File"),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isAddingAttachment = false;
                                  _attachmentNameController.clear();
                                  _attachmentFile = null;
                                });
                              },
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isLoading ? null : _addAttachment,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Add Attachment"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Attachments list
              StreamBuilder<List<AttachmentListModel>>(
                stream: _attachments$,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          "Error loading attachments: ${snapshot.error}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final attachments = snapshot.data!;

                  if (attachments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          "No attachments added yet",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _openAttachment(attachment),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getFileTypeColor(attachment).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getFileTypeIcon(attachment),
                                    size: 20,
                                    color: _getFileTypeColor(attachment),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachment.name,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
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
                                  onPressed: () => _removeAttachment(attachment),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  tooltip: "Remove attachment",
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _deleteAccommodation(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Accommodation"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime dateTime,
    required Function(DateTime) onDateTimeChanged,
    required Color color,
  }) {
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
        onTap: () => _selectDateTime(dateTime, onDateTimeChanged),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDate(dateTime),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatTime(dateTime),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(DateTime currentDateTime, Function(DateTime) onChanged) async {
    final DateTime? newDateTime = await selectDateTime(context, initialDate: currentDateTime);

    if (newDateTime == null) {
      return;
    }

    onChanged(newDateTime);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final command = UpdateTripAccommodation(
        id: widget.accommodation.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        checkIn: checkInDate,
        checkOut: checkOutDate,
      );

      await updateTripAccommodation(command: command);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccommodation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Accommodation'),
        content: Text('Are you sure you want to delete "${widget.accommodation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await deleteAccommodation(accommodationId: widget.accommodation.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to the previous screen
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
