import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/models.dart';

class LocationMapDetails extends StatelessWidget {
  final TripLocationListModel location;
  final ScrollController scrollController;

  const LocationMapDetails({required this.location, required this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
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
                color: Colors.grey[300],
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
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                location.country,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (location.forecast?.dailyForecast.isNotEmpty == true) ...[
            Text(
              'Weather Forecast',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getWeatherIcon(forecast.condition),
            size: 32,
            color: Colors.teal,
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
                  _getWeatherConditionText(forecast.condition),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (forecast.precipitationProbability > 0.1)
                  Text(
                    '${(forecast.precipitationProbability * 100).round()}% chance of rain',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  String _getWeatherConditionText(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return "Sunny";
      case WeatherCondition.rain:
        return "Rain";
      case WeatherCondition.clouds:
        return "Cloudy";
      case WeatherCondition.snow:
        return "Snow";
      case WeatherCondition.thunderstorm:
        return "Thunderstorm";
    }
  }

}
