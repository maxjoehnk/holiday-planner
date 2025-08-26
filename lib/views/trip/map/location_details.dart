import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';

class LocationMapDetails extends StatelessWidget {
  final TripLocationListModel location;
  final ScrollController scrollController;

  const LocationMapDetails({required this.location, required this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Container(
    decoration: const BoxDecoration(
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
                color: colorScheme.secondaryFixedDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            location.city,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                location.country,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (location.forecast?.dailyForecast.isNotEmpty == true) ...[
            Text(
              AppLocalizations.of(context)!.weatherLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildWeatherInfo(context, location.forecast!.dailyForecast.first),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildWeatherInfo(BuildContext context, DailyWeatherForecast forecast) {
    var colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getWeatherIcon(forecast.condition),
            size: 32,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${forecast.minTemperature.round()}° - ${forecast.maxTemperature.round()}°C',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getWeatherConditionText(context, forecast.condition),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (forecast.precipitationProbability > 0.1)
                  Text(
                    '${(forecast.precipitationProbability * 100).round()}% ${AppLocalizations.of(context)!.weatherRain.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.rain:
        return Icons.grain;
      case WeatherCondition.clouds:
        return Icons.cloud;
      case WeatherCondition.snow:
        return Icons.ac_unit;
      case WeatherCondition.thunderstorm:
        return Icons.thunderstorm;
    }
  }

  String _getWeatherConditionText(BuildContext context, WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return AppLocalizations.of(context)!.weatherSunny;
      case WeatherCondition.rain:
        return AppLocalizations.of(context)!.weatherRain;
      case WeatherCondition.clouds:
        return AppLocalizations.of(context)!.weatherCloudy;
      case WeatherCondition.snow:
        return AppLocalizations.of(context)!.weatherSnow;
      case WeatherCondition.thunderstorm:
        return AppLocalizations.of(context)!.weatherThunderstorm;
    }
  }

}
