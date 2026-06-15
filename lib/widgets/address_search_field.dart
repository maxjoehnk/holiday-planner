import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/point_of_interests.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:uuid/uuid.dart';

class AddressSearchField extends StatefulWidget {
  final UuidValue tripId;
  final String? initialAddress;
  final Coordinate? initialCoordinate;
  final void Function(String address, Coordinate? coordinate) onChanged;
  final bool required;
  final String? labelText;
  final String? hintText;

  const AddressSearchField({
    super.key,
    required this.tripId,
    required this.onChanged,
    this.initialAddress,
    this.initialCoordinate,
    this.required = false,
    this.labelText,
    this.hintText,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  late final TextEditingController _controller;
  Coordinate? _coordinate;
  bool _isSelectedFromAutocomplete = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress ?? '');
    _coordinate = widget.initialCoordinate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_controller.text.trim(), _coordinate);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Autocomplete<PointOfInterestSearchModel>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty || _isSelectedFromAutocomplete) {
          return const Iterable<PointOfInterestSearchModel>.empty();
        }
        if (textEditingValue.text == "Instance of 'PointOfInterestSearchModel'") {
          return const Iterable<PointOfInterestSearchModel>.empty();
        }
        try {
          final results = await searchPointOfInterests(
            query: textEditingValue.text,
            tripId: widget.tripId,
          );
          return results;
        } catch (e) {
          return const Iterable<PointOfInterestSearchModel>.empty();
        }
      },
      displayStringForOption: (option) => option.address ?? option.name,
      onSelected: (PointOfInterestSearchModel selection) {
        final addressText = (selection.address != null && selection.address!.isNotEmpty)
            ? selection.address!
            : selection.name;
        _controller.text = addressText;
        setState(() {
          _coordinate = selection.coordinate;
          _isSelectedFromAutocomplete = true;
        });
        _emit();
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<PointOfInterestSearchModel> onSelected,
          Iterable<PointOfInterestSearchModel> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.name,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (option.address != null && option.address!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    option.address!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  option.country,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        if (textEditingController.text != _controller.text) {
          textEditingController.text = _controller.text;
        }
        textEditingController.addListener(() {
          if (_controller.text != textEditingController.text) {
            _controller.text = textEditingController.text;
            if (_isSelectedFromAutocomplete) {
              setState(() {
                _isSelectedFromAutocomplete = false;
                _coordinate = null;
              });
            } else if (_coordinate != null) {
              setState(() {
                _coordinate = null;
              });
            }
            _emit();
          }
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          maxLines: 2,
          validator: (value) {
            if (widget.required && (value == null || value.trim().isEmpty)) {
              return "Please enter an address";
            }
            return null;
          },
          decoration: AppInputDecoration(
            labelText: widget.labelText ?? "Address",
            hintText: widget.hintText ?? "Search address or place",
            icon: Icons.location_on_outlined,
            required: widget.required,
          ),
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
    );
  }
}
