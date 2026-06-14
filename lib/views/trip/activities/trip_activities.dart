import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/points_of_interest.dart';
import 'package:holiday_planner/src/rust/api/routes.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:holiday_planner/views/trip/activities/add_point_of_interest.dart';
import 'package:holiday_planner/views/trip/activities/edit_point_of_interest.dart';
import 'package:holiday_planner/views/trip/activities/route_card.dart';
import 'package:holiday_planner/views/trip/activities/route_detail.dart';
import 'package:holiday_planner/views/share_receiver/komoot_route_import_flow.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class TripActivities extends StatefulWidget {
  final UuidValue tripId;

  const TripActivities({super.key, required this.tripId});

  @override
  State<TripActivities> createState() => _TripActivitiesState();
}

class _TripActivitiesState extends State<TripActivities> {
  late final _pointsOfInterest = RefreshableData<List<PointOfInterestModel>>(
    fetch: () => getTripPointsOfInterest(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onPoisChanged(widget.tripId)],
  );
  late final _routes = RefreshableData<List<RouteModel>>(
    fetch: () => getTripRoutes(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onRoutesChanged(widget.tripId)],
  );

  @override
  void dispose() {
    _pointsOfInterest.dispose();
    _routes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activities"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<PointOfInterestModel>>(
        stream: _pointsOfInterest.stream,
        builder: (context, poiSnapshot) {
          return StreamBuilder<List<RouteModel>>(
            stream: _routes.stream,
            builder: (context, routesSnapshot) {
              if (poiSnapshot.hasError) {
                return _ErrorView(error: poiSnapshot.error);
              }
              if (routesSnapshot.hasError) {
                return _ErrorView(error: routesSnapshot.error);
              }
              if (!poiSnapshot.hasData || !routesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final pois = poiSnapshot.requireData;
              final routes = routesSnapshot.requireData;

              if (pois.isEmpty && routes.isEmpty) {
                return _EmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (pois.isNotEmpty) ...[
                    _SectionHeader(label: "Points of Interest"),
                    const SizedBox(height: 8),
                    for (final poi in pois) ...[
                      PointOfInterestCard(
                        pointOfInterest: poi,
                        onEdit: () => _editPointOfInterest(context, poi),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (routes.isNotEmpty) ...[
                    if (pois.isNotEmpty) const SizedBox(height: 12),
                    _SectionHeader(label: "Routes"),
                    const SizedBox(height: 8),
                    for (final route in routes) ...[
                      RouteCard(
                        route: route,
                        onTap: () => _openRouteDetail(context, route),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_activity_fab",
        onPressed: () => _showAddActivityMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddActivityMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenContext = context;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Add activity"),
          contentPadding: const EdgeInsets.only(top: 20.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.explore,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: const Text("Point of interest"),
                subtitle: const Text("Add an attraction, restaurant, or other place to visit"),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _addPointOfInterest(screenContext);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.route,
                    color: colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                title: const Text("Komoot route"),
                subtitle: const Text("Paste a Komoot tour URL to import the route"),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _addRoute(screenContext);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _addPointOfInterest(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddPointOfInterest(tripId: widget.tripId)));
  }

  void _editPointOfInterest(BuildContext context, PointOfInterestModel pointOfInterest) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditPointOfInterest(pointOfInterest: pointOfInterest)));
  }

  void _addRoute(BuildContext context) {
    KomootRouteImportFlow.startFromTripScreen(context, widget.tripId);
  }

  void _openRouteDetail(BuildContext context, RouteModel route) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => RouteDetail(route: route)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            "No activities yet",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Add a point of interest, or share a Komoot route into the app to plan hikes and rides.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
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
            AppLocalizations.of(context)!.errorWithMessage(error.toString()),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
