import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

class AccommodationMapDetails extends StatelessWidget {
  final AccommodationModel accommodation;
  final ScrollController scrollController;

  const AccommodationMapDetails(
      {required this.accommodation, required this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var l10n = AppLocalizations.of(context)!;

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryFixedDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.hotel,
                    color: ACCOMMODATIONS_COLOR, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.accommodationLabel,
                  style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              accommodation.name,
              style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (accommodation.address != null && accommodation.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      accommodation.address!,
                      style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _stayRow(
              context,
              icon: Icons.login,
              label: l10n.checkInLabel,
              dateTime: accommodation.checkIn.toLocal(),
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _stayRow(
              context,
              icon: Icons.logout,
              label: l10n.checkOutLabel,
              dateTime: accommodation.checkOut.toLocal(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stayRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime dateTime,
    required Color color,
  }) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '${formatDate(dateTime)} · ${formatTime(dateTime)}',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
