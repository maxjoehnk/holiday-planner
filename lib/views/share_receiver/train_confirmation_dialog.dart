import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models/transits.dart';

class TrainConfirmationDialog extends StatelessWidget {
  final ParsedTrainJourney parsedJourney;

  const TrainConfirmationDialog({
    super.key,
    required this.parsedJourney,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Train Information'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${parsedJourney.segments.length} train segment${parsedJourney.segments.length == 1 ? '' : 's'}:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: parsedJourney.segments.map((segment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (segment.trainNumber != null)
                              Text(
                                segment.trainNumber!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From: ${segment.departureStationName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      if (segment.departureScheduledPlatform !=
                                          null)
                                        Text(
                                          'Platform ${segment.departureScheduledPlatform}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      Text(
                                        '${segment.scheduledDepartureTime.toLocal().hour.toString().padLeft(2, '0')}:${segment.scheduledDepartureTime.toLocal().minute.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'To: ${segment.arrivalStationName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.end,
                                      ),
                                      if (segment.arrivalScheduledPlatform !=
                                          null)
                                        Text(
                                          'Platform ${segment.arrivalScheduledPlatform}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          textAlign: TextAlign.end,
                                        ),
                                      Text(
                                        '${segment.scheduledArrivalTime.toLocal().hour.toString().padLeft(2, '0')}:${segment.scheduledArrivalTime.toLocal().minute.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => (BuildContext context) {
            Navigator.of(context).pop(true);
          }(context),
          child: const Text('Confirm & Select Trip'),
        ),
      ],
    );
  }
}
