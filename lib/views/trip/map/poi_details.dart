import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/models.dart';

class PointOfInterestMapDetails extends StatelessWidget {
  final PointOfInterestModel poi;
  final ScrollController scrollController;

  const PointOfInterestMapDetails({required this.poi, required this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.place, color: POINTS_OF_INTERESTS_COLOR, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Point of Interest',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
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
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    poi.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
            if (poi.website != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.language, size: 16, color: Colors.grey[600]),
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.openingHours!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
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
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.price!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
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
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      poi.phoneNumber!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (poi.note != null) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
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
