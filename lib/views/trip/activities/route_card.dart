import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback? onTap;

  const RouteCard({
    super.key,
    required this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
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
                      _sportIcon(route.sport),
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
                          route.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _providerLabel(route.provider),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openExternal(route.externalUrl),
                    icon: Icon(
                      Icons.open_in_new,
                      color: colorScheme.primary,
                    ),
                    tooltip: _openTooltip(route.provider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _RouteStat(
                    icon: Icons.straighten,
                    label: _formatDistance(route.distanceMeters),
                  ),
                  _RouteStat(
                    icon: Icons.schedule,
                    label: _formatDuration(route.durationSeconds.toInt()),
                  ),
                  if (route.elevationUpMeters != null)
                    _RouteStat(
                      icon: Icons.trending_up,
                      label: "${route.elevationUpMeters!.round()} m",
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RouteStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
  if (s.contains("hike") || s.contains("touring")) {
    return Icons.hiking;
  }
  if (s.contains("run") || s.contains("jog")) {
    return Icons.directions_run;
  }
  if (s.contains("mtb") || s.contains("mountain")) {
    return Icons.terrain;
  }
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

String _openTooltip(RouteProvider provider) {
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
