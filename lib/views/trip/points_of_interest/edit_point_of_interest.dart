import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/commands/update_trip_point_of_interest.dart';
import 'package:holiday_planner/src/rust/models.dart';

class EditPointOfInterest extends StatefulWidget {
  final PointOfInterestModel pointOfInterest;

  const EditPointOfInterest({super.key, required this.pointOfInterest});

  @override
  State<EditPointOfInterest> createState() => _EditPointOfInterestState();
}

class _EditPointOfInterestState extends State<EditPointOfInterest> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate form with existing point of interest data
    _nameController.text = widget.pointOfInterest.name;
    _addressController.text = widget.pointOfInterest.address;
    _websiteController.text = widget.pointOfInterest.website ?? '';
    _openingHoursController.text = widget.pointOfInterest.openingHours ?? '';
    _priceController.text = widget.pointOfInterest.price ?? '';
    
    // Listen to text changes to update preview
    _nameController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
    _websiteController.addListener(() => setState(() {}));
    _openingHoursController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _openingHoursController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Point of Interest"),
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
                "Point of Interest Details",
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
                  hintText: "Restaurant, Museum, Park, etc.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.explore_outlined),
                ),
              ),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  labelText: "Address",
                  hintText: "Street address or location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic URL validation
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return "Please enter a valid URL (starting with http:// or https://)";
                    }
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Website (Optional)",
                  hintText: "https://example.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.language_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openingHoursController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Opening Hours (Optional)",
                  hintText: "Mon-Fri: 9:00-17:00, Sat-Sun: 10:00-16:00",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.access_time_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: "Price (Optional)",
                  hintText: "\$15, €20, Free, etc.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _buildPreviewCard(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _deletePointOfInterest(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Point of Interest"),
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
                        _nameController.text.isEmpty ? "Point of Interest Name" : _nameController.text,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _nameController.text.isEmpty ? colorScheme.onSurfaceVariant : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addressController.text.isEmpty ? "Address will appear here" : _addressController.text,
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
          ],
        ),
      ),
    );
  }

  Future<void> _deletePointOfInterest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Point of Interest'),
        content: Text('Are you sure you want to delete "${widget.pointOfInterest.name}"?'),
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
        await deletePointOfInterest(pointOfInterestId: widget.pointOfInterest.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to the list
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting point of interest: $e';
          _isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting point of interest: $e')),
          );
        }
      }
    }
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
      final command = UpdateTripPointOfInterest(
        id: widget.pointOfInterest.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        openingHours: _openingHoursController.text.trim().isEmpty ? null : _openingHoursController.text.trim(),
        price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
      );

      await updateTripPointOfInterest(command: command);
      
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
}
