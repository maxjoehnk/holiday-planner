
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/attachments.dart';
import 'package:holiday_planner/src/rust/commands/add_trip_attachment.dart';
import 'package:uuid/uuid.dart';

class AddAttachmentView extends StatefulWidget {
  final UuidValue tripId;

  const AddAttachmentView({super.key, required this.tripId});

  @override
  State<AddAttachmentView> createState() => _AddAttachmentViewState();
}

class _AddAttachmentViewState extends State<AddAttachmentView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  XFile? file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Attachment"),
        actions: [
          FilledButton(
            onPressed: _submit,
            child: const Text("Save"),
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                    labelText: "Name", border: OutlineInputBorder()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (file != null) ...[
                    const Icon(Icons.check),
                    const SizedBox(width: 8),
                    Text(file!.name),
                  ],
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text("Pick File"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (file == null) {
      return;
    }
    await addTripAttachment(
        command: AddTripAttachment(
            name: _nameController.text,
            tripId: widget.tripId,
            path: file!.path,
        ));
    Navigator.pop(context);
  }

  _pickFile() async {
    var pickedFile = await openFile();
    if (pickedFile == null) {
      return;
    }
    setState(() {
      file = pickedFile;
    });
  }
}
