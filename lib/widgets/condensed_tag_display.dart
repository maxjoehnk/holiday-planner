import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/tags.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:uuid/uuid_value.dart';

class CondensedTagDisplay extends StatefulWidget {
  final UuidValue tripId;
  final int maxTags;
  final double chipHeight;
  final TextStyle? textStyle;

  const CondensedTagDisplay({
    super.key,
    required this.tripId,
    this.maxTags = 3,
    this.chipHeight = 20,
    this.textStyle,
  });

  @override
  State<CondensedTagDisplay> createState() => _CondensedTagDisplayState();
}

class _CondensedTagDisplayState extends State<CondensedTagDisplay> {
  List<TagModel> _tags = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await getTripTags(tripId: widget.tripId);
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _hasError || _tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTags = _tags.take(widget.maxTags).toList();
    final hasMoreTags = _tags.length > widget.maxTags;
    final remainingCount = _tags.length - widget.maxTags;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...displayTags.map((tag) => _TagChip(
          tag: tag,
          height: widget.chipHeight,
          textStyle: widget.textStyle,
        )),
        if (hasMoreTags)
          _MoreTagsChip(
            count: remainingCount,
            height: widget.chipHeight,
            textStyle: widget.textStyle,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final TagModel tag;
  final double height;
  final TextStyle? textStyle;

  const _TagChip({
    required this.tag,
    required this.height,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label,
            size: height * 0.6,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 2),
          Text(
            tag.name,
            style: textStyle ?? defaultTextStyle?.copyWith(
              color: colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MoreTagsChip extends StatelessWidget {
  final int count;
  final double height;
  final TextStyle? textStyle;

  const _MoreTagsChip({
    required this.count,
    required this.height,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '+$count',
        style: textStyle ?? defaultTextStyle?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
