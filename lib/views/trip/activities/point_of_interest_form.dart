import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/widgets/form_field.dart';
import 'package:holiday_planner/widgets/required_fields_hint.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/models/point_of_interests.dart';
import 'package:uuid/uuid.dart';

class PointOfInterestFormData {
  final String name;
  final String address;
  final String? website;
  final String? openingHours;
  final String? price;
  final String? phoneNumber;
  final String? note;
  final UuidValue? id;
  final Coordinate? coordinate;

  PointOfInterestFormData({
    required this.name,
    required this.address,
    this.website,
    this.openingHours,
    this.price,
    this.phoneNumber,
    this.note,
    this.id,
    this.coordinate,
  });
}

class PointOfInterestForm extends StatefulWidget {
  final UuidValue tripId;
  final PointOfInterestFormData? initialData;
  final Function(PointOfInterestFormData) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onErrorDismiss;

  const PointOfInterestForm({
    super.key,
    required this.tripId,
    this.initialData,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.onErrorDismiss,
  });

  @override
  State<PointOfInterestForm> createState() => PointOfInterestFormState();
}

class PointOfInterestFormState extends State<PointOfInterestForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _openingHoursController;
  late final TextEditingController _priceController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _noteController;
  Coordinate? _selectedCoordinate;
  bool _isSelectedFromAutocomplete = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _nameController = TextEditingController(text: data?.name ?? '');
    _addressController = TextEditingController(text: data?.address ?? '');
    _websiteController = TextEditingController(text: data?.website ?? '');
    _openingHoursController =
        TextEditingController(text: data?.openingHours ?? '');
    _priceController = TextEditingController(text: data?.price ?? '');
    _phoneNumberController = TextEditingController(text: data?.phoneNumber ?? '');
    _noteController = TextEditingController(text: data?.note ?? '');

    _nameController.addListener(() => setState(() {
      _isSelectedFromAutocomplete = false;
    }));
    _addressController.addListener(() => setState(() {}));
    _websiteController.addListener(() => setState(() {}));
    _openingHoursController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
    _phoneNumberController.addListener(() => setState(() {}));
    _noteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _openingHoursController.dispose();
    _priceController.dispose();
    _phoneNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            if (widget.errorMessage != null) ...[
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
                        widget.errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onErrorDismiss,
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
              "Point of Interest Details",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Autocomplete<PointOfInterestSearchModel>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty || _isSelectedFromAutocomplete) {
                  return const Iterable<PointOfInterestSearchModel>.empty();
                }
                // HACK: workaround to reduce unwanted api queries
                // This value appears when selecting an option from the autocomplete
                if (textEditingValue.text == "Instance of 'PointOfInterestSearchModel'") {
                  return const Iterable<PointOfInterestSearchModel>.empty();
                }
                try {
                  final results = await searchPointOfInterests(query: textEditingValue.text, tripId: widget.tripId);
                  return results;
                } catch (e) {
                  return const Iterable<PointOfInterestSearchModel>.empty();
                }
              },
              onSelected: (PointOfInterestSearchModel selection) {
                searchPointOfInterestDetails(id: selection.id)
                .then((details) {
                  if (details.openingHours != null && _openingHoursController.text.isEmpty) {
                    _openingHoursController.text = details.openingHours!;
                  }
                  if (details.website != null && _websiteController.text.isEmpty) {
                    _websiteController.text = details.website!;
                  }
                  if (details.phoneNumber != null && _phoneNumberController.text.isEmpty) {
                    _phoneNumberController.text = details.phoneNumber!;
                  }
                });
                _nameController.text = selection.name;
                if (selection.address != null && selection.address!.isNotEmpty) {
                  _addressController.text = selection.address!;
                }
                setState(() {
                  _selectedCoordinate = selection.coordinate;
                  _isSelectedFromAutocomplete = true;
                });
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<PointOfInterestSearchModel> onSelected, Iterable<PointOfInterestSearchModel> options) {
                var colorScheme = Theme.of(context).colorScheme;
                var textTheme = Theme.of(context).textTheme;
                
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
                                      Icons.explore,
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
                                        const SizedBox(height: 2),
                                        if (option.address != null && option.address!.isNotEmpty) ...[
                                          Text(
                                            option.address!,
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                        ],
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
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
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
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                if (textEditingController.text != _nameController.text) {
                  textEditingController.text = _nameController.text;
                }
                textEditingController.addListener(() {
                  if (_nameController.text != textEditingController.text) {
                    _nameController.text = textEditingController.text;
                  }
                });
                
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a name";
                    }
                    return null;
                  },
                  decoration: AppInputDecoration(
                    labelText: "Name",
                    hintText: "Restaurant, Museum, Park, etc.",
                    required: true,
                    icon: Icons.explore_outlined
                  ),
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
            ),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter an address";
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Address",
              hintText: "Street address or location",
              icon: Icons.location_on_outlined,
              required: true,
              ),
            ),
            TextFormField(
              controller: _websiteController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return "Please enter a valid URL (starting with http:// or https://)";
                  }
                }
                return null;
              },
              decoration: AppInputDecoration(
                labelText: "Website",
                hintText: "https://example.com",
                icon: Icons.language_outlined,
              ),
            ),
            TextFormField(
              controller: _openingHoursController,
              textInputAction: TextInputAction.next,
              maxLines: 2,
              decoration: AppInputDecoration(
                labelText: "Opening Hours",
                hintText: "Mon-Fri: 9:00-17:00, Sat-Sun: 10:00-16:00",
                icon: Icons.access_time_outlined,
              ),
            ),
            TextFormField(
              controller: _priceController,
              textInputAction: TextInputAction.next,
              decoration: AppInputDecoration(
                labelText: "Price",
                hintText: "\$15, €20, Free, etc.",
                icon: Icons.attach_money_outlined,
              ),
            ),
            TextFormField(
              controller: _phoneNumberController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: AppInputDecoration(
                labelText: "Phone Number",
                hintText: "+1 (555) 123-4567",
                icon: Icons.phone_outlined,
              ),
            ),
            TextFormField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: AppInputDecoration(
                labelText: "Note",
                hintText: "Additional information, tips, or personal notes",
                icon: Icons.note_outlined,
              ),
            ),
            _buildPreviewCard(context),
            const SizedBox(width: 16),
            const RequiredFieldsHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  "Preview",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.explore,
                    size: 24,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isEmpty
                            ? "Point of Interest Name"
                            : _nameController.text,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _nameController.text.isEmpty
                              ? colorScheme.onSurfaceVariant
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addressController.text.isEmpty
                            ? "Address will appear here"
                            : _addressController.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_websiteController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _websiteController.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
            if (_openingHoursController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _openingHoursController.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (_priceController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _priceController.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (_phoneNumberController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _phoneNumberController.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (_noteController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _noteController.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool validate() {
    return _formKey.currentState!.validate();
  }

  PointOfInterestFormData getFormData() {
    return PointOfInterestFormData(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      openingHours: _openingHoursController.text.trim().isEmpty
          ? null
          : _openingHoursController.text.trim(),
      price: _priceController.text.trim().isEmpty
          ? null
          : _priceController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim().isEmpty
          ? null
          : _phoneNumberController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      id: widget.initialData?.id,
      coordinate: _selectedCoordinate,
    );
  }

  void submit() {
    if (validate()) {
      widget.onSubmit(getFormData());
    }
  }
}
