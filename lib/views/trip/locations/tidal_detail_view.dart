import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:intl/intl.dart';

class TidalDetailView extends StatelessWidget {
  final TripLocationListModel location;

  const TidalDetailView({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    if (!location.isCoastal || location.tidalInformation.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${location.city} Tides'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('No tidal information available'),
        ),
      );
    }

    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${location.city} Tides'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.waves,
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
                              location.city,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location.country,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tidal Information Section
              Text(
                'Tide Times & Heights',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _buildTidalInformationCard(context, location.tidalInformation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTidalInformationCard(BuildContext context, List<dynamic> tidalInformation) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    if (tidalInformation.isEmpty) {
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 24,
                color: colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "No tidal data available",
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with update time
            Row(
              children: [
                Icon(
                  Icons.waves,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tidal Information",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Updated: ${location.tidalInformationLastUpdated != null ? DateFormat('MMM d, HH:mm').format(location.tidalInformationLastUpdated!.toLocal()) : 'Never'}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            if (tidalInformation.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              Text(
                'Tide Schedule',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              
              // All tide extremes
              ...(tidalInformation.map((tideInfo) {
                final DateTime tideTime = tideInfo?.date ?? DateTime.now();
                final String tideType = tideInfo?.tide.toString() == 'TideType.high' ? 'High' : 'Low';
                final double height = tideInfo?.height ?? 0.0;
                final bool isHigh = tideType == 'High';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHigh 
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHigh 
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isHigh ? Colors.blue : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isHigh ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$tideType Tide",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(tideTime.toLocal()),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(tideTime.toLocal()),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${height.toStringAsFixed(2)}m",
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isHigh ? Colors.blue : Colors.orange,
                            ),
                          ),
                          Text(
                            "Height",
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList()),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No tide data available',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
