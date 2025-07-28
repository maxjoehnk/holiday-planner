import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ForecastDetailView extends StatelessWidget {
  final TripLocationListModel location;

  const ForecastDetailView({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    if (location.forecast == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${location.city} Forecast'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('No forecast data available'),
        ),
      );
    }

    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${location.city} Forecast'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          Icons.location_on,
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


              Text(
                'Daily Forecast',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: location.forecast!.dailyForecast.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  var dayForecast = location.forecast!.dailyForecast[index];

                  return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDate(dayForecast.day, format: DateFormat.yMMMMEEEEd()),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                weatherIcons[dayForecast.condition] ?? Icons.wb_sunny,
                                size: 32,
                                color: weatherColors[dayForecast.condition] ?? colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTemperatureItem(
                                context,
                                'Min',
                                '${dayForecast.minTemperature.toStringAsFixed(0)}°',
                                Icons.arrow_downward,
                                Colors.blue.shade700,
                              ),
                              _buildTemperatureItem(
                                context,
                                'Max',
                                '${dayForecast.maxTemperature.toStringAsFixed(0)}°',
                                Icons.arrow_upward,
                                Colors.red.shade700,
                              ),
                              _buildTemperatureItem(
                                context,
                                'Morning',
                                '${dayForecast.morningTemperature.toStringAsFixed(0)}°',
                                Icons.wb_twilight,
                                Colors.amber.shade700,
                              ),
                              _buildTemperatureItem(
                                context,
                                'Evening',
                                '${dayForecast.eveningTemperature.toStringAsFixed(0)}°',
                                Icons.nights_stay_outlined,
                                Colors.indigo.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWeatherDetail(
                                context,
                                'Wind',
                                '${dayForecast.windSpeed.toStringAsFixed(1)} m/s',
                                Icons.air,
                              ),
                              _buildWeatherDetail(
                                context,
                                'Rain',
                                '${(dayForecast.precipitationProbability * 100).toStringAsFixed(0)}%',
                                Icons.water_drop,
                              ),
                              _buildWeatherDetail(
                                context,
                                'Precipitation',
                                '${dayForecast.precipitationAmount.toStringAsFixed(1)} mm',
                                Icons.opacity,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hourly Forecast',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 122,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: location.forecast!.hourlyForecast
                                  .where((f) => f.time.day == dayForecast.day.day)
                                  .length,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                var hourlyForecasts = location.forecast!.hourlyForecast
                                    .where((f) => f.time.day == dayForecast.day.day)
                                    .toList();
                                var hourForecast = hourlyForecasts[index];

                                return Container(
                                  width: 70,
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatTime(hourForecast.time),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Icon(
                                        weatherIcons[hourForecast.condition] ?? Icons.wb_sunny,
                                        size: 32,
                                        color: weatherColors[hourForecast.condition] ?? colorScheme.primary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "${hourForecast.temperature.toStringAsFixed(0)}°",
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (hourForecast.precipitationProbability > 0) ...[
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.water_drop,
                                              size: 14,
                                              color: Colors.blue.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${(hourForecast.precipitationProbability * 100).toStringAsFixed(0)}%",
                                              style: textTheme.bodySmall?.copyWith(
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureItem(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(BuildContext context, String label, String value, IconData icon) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

}

// Weather icons and colors
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
  WeatherCondition.thunderstorm: Colors.grey.shade800
};
