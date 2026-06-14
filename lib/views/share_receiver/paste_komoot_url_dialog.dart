import 'package:flutter/material.dart';

final RegExp komootTourUrlRegex =
    RegExp(r'komoot\.(?:com|de)/.*(?:tour|smarttour)/[a-zA-Z0-9]+');

class PasteKomootUrlDialog extends StatefulWidget {
  const PasteKomootUrlDialog({super.key});

  @override
  State<PasteKomootUrlDialog> createState() => _PasteKomootUrlDialogState();
}

class _PasteKomootUrlDialogState extends State<PasteKomootUrlDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!komootTourUrlRegex.hasMatch(value)) {
      setState(() {
        _errorText = "Please paste a valid Komoot tour URL";
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Komoot route"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Paste a Komoot tour URL to import the route."),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "https://www.komoot.com/tour/...",
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
