import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/views/trip/map/sheet_top_bar.dart';

class PointOfInterestMapDetails extends StatelessWidget {
  final PointOfInterestModel poi;
  final ScrollController scrollController;
  final VoidCallback? onEdit;

  const PointOfInterestMapDetails(
      {required this.poi, required this.scrollController, this.onEdit, super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTopBar(
              onEdit: onEdit,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place,
                      color: POINTS_OF_INTERESTS_COLOR, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.pointOfInterestLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              poi.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colorScheme.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    poi.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                  ),
                ),
              ],
            ),
            if (poi.website != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.language, size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.website!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (poi.openingHours != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.openingHours!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (poi.price != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money,
                      size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.price!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (poi.phoneNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.phoneNumber!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (poi.note != null) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.notesLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                poi.note!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
