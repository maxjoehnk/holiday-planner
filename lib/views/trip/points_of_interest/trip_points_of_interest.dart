import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/views/trip/points_of_interest/add_point_of_interest.dart';
import 'package:holiday_planner/views/trip/points_of_interest/edit_point_of_interest.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class TripPointsOfInterest extends StatefulWidget {
  final UuidValue tripId;

  const TripPointsOfInterest({super.key, required this.tripId});

  @override
  State<TripPointsOfInterest> createState() => _TripPointsOfInterestState();
}

class _TripPointsOfInterestState extends State<TripPointsOfInterest> {
  late StreamController<List<PointOfInterestModel>> _pointsOfInterest;
  late Stream<List<PointOfInterestModel>>? _pointsOfInterest$;

  @override
  void initState() {
    super.initState();
    _pointsOfInterest = StreamController();
    _pointsOfInterest$ = _pointsOfInterest.stream;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Points of Interest"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _pointsOfInterest$,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var pointsOfInterest = snapshot.requireData;
          if (pointsOfInterest.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No points of interest",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add attractions, restaurants, and other places to visit",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: pointsOfInterest.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var poi = pointsOfInterest[index];
                return PointOfInterestCard(
                  pointOfInterest: poi,
                  onEdit: () => _editPointOfInterest(context, poi),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "points_of_interest_fab",
        onPressed: () => _addPointOfInterest(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Point of Interest"),
      ),
    );
  }

  void _addPointOfInterest(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddPointOfInterest(tripId: widget.tripId)));
    _fetch();
  }

  void _editPointOfInterest(BuildContext context, PointOfInterestModel pointOfInterest) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditPointOfInterest(pointOfInterest: pointOfInterest)));
    _fetch();
  }


  _fetch() {
    _pointsOfInterest.addStream(getTripPointsOfInterest(tripId: widget.tripId).asStream());
  }
}

class PointOfInterestCard extends StatelessWidget {
  final PointOfInterestModel pointOfInterest;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PointOfInterestCard({
    required this.pointOfInterest,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            pointOfInterest.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pointOfInterest.address,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (pointOfInterest.phoneNumber != null)
                      IconButton(
                        onPressed: () => _launchPhone(pointOfInterest.phoneNumber!),
                        icon: Icon(
                          Icons.phone,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Call',
                      ),
                    IconButton(
                      onPressed: () => _launchNavigation(pointOfInterest.address),
                      icon: Icon(
                        Icons.directions,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Open in navigation app',
                    ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        tooltip: 'Delete point of interest',
                      ),
                  ],
                ),
                if (pointOfInterest.website != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _launchWebsite(pointOfInterest.website!),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                              pointOfInterest.website!,
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
                  ),
                ],
                if (pointOfInterest.openingHours != null) ...[
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
                          pointOfInterest.openingHours!,
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
                if (pointOfInterest.price != null) ...[
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
                        pointOfInterest.price!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (pointOfInterest.note != null && pointOfInterest.note!.isNotEmpty) ...[
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
                          pointOfInterest.note!,
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
              ],
            ),
          ),
        ));
  }

  void _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchNavigation(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
