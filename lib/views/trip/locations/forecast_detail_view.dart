import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class ForecastDetailView extends StatefulWidget {
  final TripLocationListModel location;

  const ForecastDetailView({super.key, required this.location});

  @override
  State<ForecastDetailView> createState() => _ForecastDetailViewState();
}

class _ForecastDetailViewState extends State<ForecastDetailView> {
  late TripLocationListModel location;
  StreamSubscription<void>? _changeSub;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    location = widget.location;
    _changeSub = DataChangeBus.instance
        .onLocationDataChanged(widget.location.id)
        .listen((_) => _refresh());
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final updated = await getLocationDetails(locationId: widget.location.id);
      if (mounted) {
        setState(() {
          location = updated;
        });
      }
    } catch (_) {
      // ignore — keep showing the existing forecast
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final forecast = location.forecast;
    final title = '${location.city} Forecast';

    if (forecast == null || forecast.dailyForecast.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: const Center(child: Text('No forecast data available')),
      );
    }

    final days = forecast.dailyForecast;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Temperature trend',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: _TempTrendChart(days: days),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < days.length; i++) ...[
            _TimelineDayRow(
              day: days[i],
              hourly: forecast.hourlyForecast
                  .where((h) => _sameDay(h.time, days[i].day))
                  .toList(),
              expanded: _expandedIndex == i,
              onToggle: () => setState(() {
                _expandedIndex = _expandedIndex == i ? null : i;
              }),
            ),
            if (i < days.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TempTrendChart extends StatelessWidget {
  final List<DailyWeatherForecast> days;

  const _TempTrendChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomPaint(
      painter: _TempTrendPainter(
        days: days,
        lineMax: Colors.red.shade400,
        lineMin: Colors.blue.shade400,
        axis: colorScheme.outlineVariant,
        text: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.bodySmall ?? const TextStyle(fontSize: 11),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TempTrendPainter extends CustomPainter {
  final List<DailyWeatherForecast> days;
  final Color lineMax;
  final Color lineMin;
  final Color axis;
  final Color text;
  final TextStyle labelStyle;

  _TempTrendPainter({
    required this.days,
    required this.lineMax,
    required this.lineMin,
    required this.axis,
    required this.text,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 12.0;
    const bottomPad = 28.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final maxT = days.map((d) => d.maxTemperature).reduce(math.max);
    final minT = days.map((d) => d.minTemperature).reduce(math.min);
    final span = (maxT - minT).clamp(1.0, double.infinity);

    double x(int i) =>
        leftPad + (days.length == 1 ? chartW / 2 : (i / (days.length - 1)) * chartW);
    double y(double t) => topPad + (1 - (t - minT) / span) * chartH;

    final baselinePaint = Paint()
      ..color = axis
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(leftPad, topPad + chartH),
      Offset(size.width - rightPad, topPad + chartH),
      baselinePaint,
    );

    final maxPath = Path();
    final minPath = Path();
    for (var i = 0; i < days.length; i++) {
      final px = x(i);
      final yMax = y(days[i].maxTemperature);
      final yMin = y(days[i].minTemperature);
      if (i == 0) {
        maxPath.moveTo(px, yMax);
        minPath.moveTo(px, yMin);
      } else {
        maxPath.lineTo(px, yMax);
        minPath.lineTo(px, yMin);
      }
    }

    final maxLinePaint = Paint()
      ..color = lineMax
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final minLinePaint = Paint()
      ..color = lineMin
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(maxPath, maxLinePaint);
    canvas.drawPath(minPath, minLinePaint);

    final dotMax = Paint()..color = lineMax;
    final dotMin = Paint()..color = lineMin;
    final fmt = DateFormat('EEE');
    for (var i = 0; i < days.length; i++) {
      final px = x(i);
      canvas.drawCircle(Offset(px, y(days[i].maxTemperature)), 3, dotMax);
      canvas.drawCircle(Offset(px, y(days[i].minTemperature)), 3, dotMin);

      _drawLabel(
        canvas,
        '${days[i].maxTemperature.toStringAsFixed(0)}°',
        Offset(px, y(days[i].maxTemperature) - 6),
        labelStyle.copyWith(color: lineMax, fontWeight: FontWeight.w600),
        anchorBottom: true,
      );

      _drawLabel(
        canvas,
        fmt.format(days[i].day),
        Offset(px, topPad + chartH + 6),
        labelStyle.copyWith(color: text),
        anchorBottom: false,
      );
    }
  }

  void _drawLabel(Canvas canvas, String s, Offset center, TextStyle style,
      {required bool anchorBottom}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final dy = anchorBottom ? -tp.height : 0.0;
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + dy));
  }

  @override
  bool shouldRepaint(covariant _TempTrendPainter old) =>
      old.days != days ||
      old.lineMax != lineMax ||
      old.lineMin != lineMin ||
      old.axis != axis;
}

class _TimelineDayRow extends StatelessWidget {
  final DailyWeatherForecast day;
  final List<HourlyWeatherForecast> hourly;
  final bool expanded;
  final VoidCallback onToggle;

  const _TimelineDayRow({
    required this.day,
    required this.hourly,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dayName = formatDate(day.day, format: DateFormat.EEEE());
    final dayDate = formatDate(day.day, format: DateFormat.MMMd());

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: expanded
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  weatherIcons[day.condition] ?? Icons.wb_sunny,
                  size: 28,
                  color: weatherColors[day.condition] ?? colorScheme.primary,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dayDate,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.water_drop, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  '${(day.precipitationProbability * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${day.minTemperature.toStringAsFixed(0)}° / ${day.maxTemperature.toStringAsFixed(0)}°',
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConditionsRow(day: day),
                    if (hourly.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _SectionLabel(text: 'Hourly'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 104,
                        child: _HourlyStrip(hourly: hourly),
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      text.toUpperCase(),
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ConditionsRow extends StatelessWidget {
  final DailyWeatherForecast day;

  const _ConditionsRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _chip(context, Icons.air, 'Wind',
            '${day.windSpeed.toStringAsFixed(1)} m/s'),
        _chip(
          context,
          Icons.umbrella,
          'Chance',
          '${(day.precipitationProbability * 100).toStringAsFixed(0)}%',
        ),
        _chip(context, Icons.water_drop, 'Amount',
            '${day.precipitationAmount.toStringAsFixed(1)} mm'),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HourlyStrip extends StatelessWidget {
  final List<HourlyWeatherForecast> hourly;

  const _HourlyStrip({required this.hourly});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: hourly.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final h = hourly[index];
        return SizedBox(
          width: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatTime(h.time),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                weatherIcons[h.condition] ?? Icons.wb_sunny,
                size: 22,
                color: weatherColors[h.condition] ?? colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                '${h.temperature.toStringAsFixed(0)}°',
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              if (h.precipitationProbability > 0)
                Text(
                  '${(h.precipitationProbability * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelSmall
                      ?.copyWith(color: Colors.blue.shade600),
                ),
            ],
          ),
        );
      },
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Map<WeatherCondition, IconData> weatherIcons = {
  WeatherCondition.sunny: MdiIcons.weatherSunny,
  WeatherCondition.clouds: MdiIcons.weatherCloudy,
  WeatherCondition.rain: MdiIcons.weatherRainy,
  WeatherCondition.snow: MdiIcons.weatherSnowy,
  WeatherCondition.thunderstorm: MdiIcons.weatherLightning,
};

Map<WeatherCondition, Color> weatherColors = {
  WeatherCondition.sunny: Colors.yellowAccent.shade700,
  WeatherCondition.clouds: Colors.grey.shade600,
  WeatherCondition.rain: Colors.blue.shade700,
  WeatherCondition.snow: Colors.black,
  WeatherCondition.thunderstorm: Colors.grey.shade800,
};
