import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:holiday_planner/services/map_tile_cache.dart';
import 'package:holiday_planner/src/rust/api/routes.dart';
import 'package:holiday_planner/src/rust/commands/update_route.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteDetail extends StatefulWidget {
  final RouteModel route;

  const RouteDetail({super.key, required this.route});

  @override
  State<RouteDetail> createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail> {
  late final _noteController = TextEditingController(text: widget.route.note ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final points = route.polyline
        .map((p) => LatLng(p.coordinate.latitude, p.coordinate.longitude))
        .toList();
    final center = LatLng(route.startCoordinate.latitude, route.startCoordinate.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Delete route',
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                minZoom: 1.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'me.maxjoehnk.holiday_planner',
                  tileProvider: FMTCTileProvider(
                    stores: {mapTileStore.storeName: BrowseStoreStrategy.readUpdateCreate},
                  ),
                ),
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4.0,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.flag,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SimpleAttributionWidget(source: Text("OpenStreetMap Contributors")),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetaChip(icon: Icons.straighten, label: _formatDistance(route.distanceMeters)),
                    _MetaChip(
                      icon: Icons.schedule,
                      label: _formatDuration(route.durationSeconds.toInt()),
                    ),
                    if (route.elevationUpMeters != null)
                      _MetaChip(
                        icon: Icons.trending_up,
                        label: "${route.elevationUpMeters!.round()} m",
                      ),
                    if (route.elevationDownMeters != null)
                      _MetaChip(
                        icon: Icons.trending_down,
                        label: "${route.elevationDownMeters!.round()} m",
                      ),
                    if (route.sport != null)
                      _MetaChip(icon: Icons.category, label: route.sport!),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Note", style: textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Add a note (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveNote,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save note'),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(_openButtonLabel()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _openButtonLabel() {
    switch (widget.route.provider) {
      case RouteProvider.komoot:
        return "Open in Komoot";
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.route.externalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final note = _noteController.text.trim();
      await updateRoute(
        command: UpdateRoute(
          id: widget.route.id,
          note: note.isEmpty ? null : note,
        ),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Note saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: const Text('This removes the route from this trip. The original tour on Komoot is not affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await deleteRoute(routeId: widget.route.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000;
    return "${km.toStringAsFixed(km < 10 ? 2 : 1)} km";
  }
  return "${meters.round()} m";
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) {
    return "$minutes min";
  }
  final mm = minutes.toString().padLeft(2, '0');
  return "$hours:$mm h";
}
