import 'package:flutter/material.dart';

class DayTitleField extends StatefulWidget {
  final String? initialTitle;
  final String placeholder;
  final ValueChanged<String?> onSubmitted;
  final TextStyle? style;

  const DayTitleField({
    super.key,
    required this.initialTitle,
    required this.placeholder,
    required this.onSubmitted,
    this.style,
  });

  @override
  State<DayTitleField> createState() => _DayTitleFieldState();
}

class _DayTitleFieldState extends State<DayTitleField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant DayTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTitle != widget.initialTitle && !_focusNode.hasFocus) {
      _controller.text = widget.initialTitle ?? '';
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final value = _controller.text.trim();
      widget.onSubmitted(value.isEmpty ? null : value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style =
        widget.style ?? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: style,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: style?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (value) {
        final trimmed = value.trim();
        widget.onSubmitted(trimmed.isEmpty ? null : trimmed);
        _focusNode.unfocus();
      },
      textInputAction: TextInputAction.done,
    );
  }
}
