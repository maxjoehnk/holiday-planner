import 'package:flutter/material.dart';
import 'package:holiday_planner/date_format.dart';

class AccommodationSummaryCard extends StatelessWidget {
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const AccommodationSummaryCard({super.key, required this.checkInDate, required this.checkOutDate});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    var duration = checkOutDate.copyWith(hour: 0, minute: 0).difference(checkInDate.copyWith(hour: 0, minute: 0)).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Stay Summary",
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$duration night${duration != 1 ? 's' : ''}",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${formatDate(checkInDate)} - ${formatDate(checkOutDate)}",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
