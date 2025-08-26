import 'dart:io';

import 'package:flutter/material.dart';
import 'package:holiday_planner/l10n/app_localizations.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';
import 'package:holiday_planner/src/rust/models/tidal_information.dart';
import 'package:holiday_planner/views/trip/attachments/add_attachment.dart';
import 'package:holiday_planner/views/trip/attachments/trip_attachments.dart';
import 'package:holiday_planner/views/trip/edit_trip.dart';
import 'package:holiday_planner/views/trip/summary/trip_summary.dart';
import 'package:uuid/uuid.dart';

import 'timeline/trip_timeline.dart';
import 'map/trip_map.dart';

const overviewTabIndex = 0;
const timelineTabIndex = 1;
const mapTabIndex = 2;
const attachmentsTabIndex = 3;

class TripView extends StatefulWidget {
  final UuidValue tripId;

  const TripView({required this.tripId, super.key});

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  int _selectedTab = 0;
  late final _trip = RefreshableData<TripOverviewModel>(
    fetch: () => getTrip(id: widget.tripId),
    refreshOn: [DataChangeBus.instance.onAnyTripDataChanged(widget.tripId)],
  );

  @override
  void dispose() {
    _trip.dispose();
    super.dispose();
  }

  String _buildDateString(TripOverviewModel trip) {
    final isSameDate = trip.startDate.year == trip.endDate.year &&
        trip.startDate.month == trip.endDate.month &&
        trip.startDate.day == trip.endDate.day;

    if (isSameDate) {
      return formatDate(trip.startDate);
    } else {
      return '${formatDate(trip.startDate)} - ${formatDate(trip.endDate)}';
    }
  }

  String _buildWeatherTidalInfo(TripLocationListModel location) {
    List<String> infoParts = [];

    if (location.forecast?.dailyForecast.isNotEmpty == true) {
      final today = location.forecast!.dailyForecast.first;
      final tempRange = "${today.minTemperature.round()}° - ${today.maxTemperature.round()}°C";
      final condition = _getWeatherConditionText(today.condition);
      infoParts.add("$tempRange, $condition");

      if (today.precipitationProbability > 0.1) {
        final percent = (today.precipitationProbability * 100).round();
        infoParts.add(AppLocalizations.of(context)!.chanceOfRainPercent(percent));
      }
    } else {
      infoParts.add(AppLocalizations.of(context)!.noWeatherData);
    }

    if (location.isCoastal && location.tidalInformation.isNotEmpty) {
      final nextTide = location.tidalInformation.first;
      final isHigh = nextTide.tide == TideType.high;
      final time = formatTime(nextTide.date);
      final tide = isHigh
          ? AppLocalizations.of(context)!.highTide
          : AppLocalizations.of(context)!.lowTide;
      infoParts.add(AppLocalizations.of(context)!.tideAtTime(tide, time));
    }

    return infoParts.join(" • ");
  }

  IconData _getWeatherIcon(TripLocationListModel location) {
    if (location.forecast?.dailyForecast.isNotEmpty == true) {
      return _getWeatherConditionIcon(location.forecast!.dailyForecast.first.condition);
    }
    return Icons.wb_sunny;
  }

  IconData _getWeatherConditionIcon(WeatherCondition condition) {
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

  @override
  Widget build(BuildContext context) {
    bool isCupertino = Platform.isMacOS || Platform.isIOS;
    return Scaffold(
      floatingActionButton: _fab(),
      body: StreamBuilder(
          stream: _trip.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(AppLocalizations.of(context)!.errorWithMessage(snapshot.error.toString())),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var trip = snapshot.requireData;
            final headerImage = trip.headerImage != null ? MemoryImage(trip.headerImage!) : null;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditTripView(trip: trip),
                          ),
                        );
                      },
                      tooltip: AppLocalizations.of(context)!.editTripTitle, 
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Padding(
                      padding: EdgeInsets.only(right: 48.0, left: isCupertino ? 64 : 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _buildDateString(trip),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  trip.durationDays == 1
                                      ? AppLocalizations.of(context)!.oneDay
                                      : AppLocalizations.of(context)!
                                          .daysCount(trip.durationDays),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (trip.singleLocationWeatherTidal != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _getWeatherIcon(trip.singleLocationWeatherTidal!),
                                  size: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _buildWeatherTidalInfo(trip.singleLocationWeatherTidal!),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
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
                    background: headerImage == null
                        ? null
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(image: headerImage, fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_selectedTab != mapTabIndex) const SliverPadding(padding: EdgeInsets.all(4)),
                if (_selectedTab == overviewTabIndex) TripSummary(trip),
                if (_selectedTab == timelineTabIndex) TripTimeline(tripId: widget.tripId),
                if (_selectedTab == mapTabIndex) TripMap(tripId: widget.tripId),
                if (_selectedTab == attachmentsTabIndex) TripAttachments(tripId: widget.tripId),
              ],
            );
          }),
      bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (i) => setState(() {
                _selectedTab = i;
              }),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.dashboard), label: AppLocalizations.of(context)!.summaryTab),
            NavigationDestination(icon: const Icon(Icons.timeline), label: AppLocalizations.of(context)!.timelineTab),
            NavigationDestination(icon: const Icon(Icons.map), label: AppLocalizations.of(context)!.mapTab),
            NavigationDestination(icon: const Icon(Icons.attachment), label: AppLocalizations.of(context)!.attachmentsTab),
          ]),
    );
  }

  Widget? _fab() {
    if (_selectedTab == attachmentsTabIndex) {
      return FloatingActionButton.extended(
        heroTag: "trip_view_fab",
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AddAttachmentView(tripId: widget.tripId)));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Attachment"),
      );
    }
    return null;
  }
}
