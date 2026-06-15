import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:holiday_planner/views/trip/map/sheet_top_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteMapDetails extends StatelessWidget {
  final RouteModel route;
  final ScrollController scrollController;
  final VoidCallback? onEdit;

  const RouteMapDetails({
    super.key,
    required this.route,
    required this.scrollController,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  Icon(_sportIcon(route.sport),
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _providerLabel(route.provider),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              route.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (route.sport != null) ...[
              const SizedBox(height: 4),
              Text(
                route.sport!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Stat(icon: Icons.straighten, label: _formatDistance(route.distanceMeters)),
                _Stat(
                  icon: Icons.schedule,
                  label: _formatDuration(route.durationSeconds.toInt()),
                ),
                if (route.elevationUpMeters != null)
                  _Stat(
                    icon: Icons.trending_up,
                    label: "${route.elevationUpMeters!.round()} m",
                  ),
                if (route.elevationDownMeters != null)
                  _Stat(
                    icon: Icons.trending_down,
                    label: "${route.elevationDownMeters!.round()} m",
                  ),
              ],
            ),
            if (route.note != null && route.note!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Note",
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(route.note!, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openExternal(route.externalUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(_openButtonLabel(route.provider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.secondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

IconData _sportIcon(String? sport) {
  if (sport == null) {
    return Icons.route;
  }
  final s = sport.toLowerCase();
  if (s.contains("hike") || s.contains("touring")) return Icons.hiking;
  if (s.contains("run") || s.contains("jog")) return Icons.directions_run;
  if (s.contains("mtb") || s.contains("mountain")) return Icons.terrain;
  if (s.contains("bike") || s.contains("cycle") || s.contains("racebike")) {
    return Icons.directions_bike;
  }
  return Icons.route;
}

String _providerLabel(RouteProvider provider) {
  switch (provider) {
    case RouteProvider.komoot:
      return "Komoot";
  }
}

String _openButtonLabel(RouteProvider provider) {
  switch (provider) {
    case RouteProvider.komoot:
      return "Open in Komoot";
  }
}

Future<void> _openExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
