import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/src/rust/api/transits.dart';
import 'package:holiday_planner/src/rust/models/transits.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:uuid/uuid.dart';

import 'add_train.dart';
import 'edit_train.dart';

class TripTransits extends StatefulWidget {
  final UuidValue tripId;

  const TripTransits({super.key, required this.tripId});

  @override
  State<TripTransits> createState() => _TripTransitsState();
}

class _TripTransitsState extends State<TripTransits> {
  late StreamController<List<Train>> _trains;
  late Stream<List<Train>>? _trains$;

  @override
  void initState() {
    super.initState();
    _trains = StreamController();
    _trains$ = _trains.stream;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transit"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildTransitsList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTransitsList() {
    return StreamBuilder<List<Train>>(
      stream: _trains$,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var trains = snapshot.requireData;
        if (trains.isEmpty) {
          return _buildEmptyState(
            icon: Icons.train_outlined,
            title: "No train connections",
            subtitle: "Add train bookings for your trip",
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            itemCount: trains.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var train = trains[index];
              return _buildTrainCard(train, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildTrainCard(Train train, int index) {
    return TrainCard(
      train: train,
      onEdit: () => _editTrain(context, train, index),
    );
  }

  Widget _buildErrorWidget(String error) {
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
            "Error: $error",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: "add_train_fab",
      onPressed: () => _addTrain(context),
      child: const Icon(Icons.add),
    );
  }

  void _addTrain(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddTrainPage(tripId: widget.tripId)));
    _fetch();
  }

  void _editTrain(BuildContext context, Train train, int index) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditTrainPage(train: train)));
    _fetch();
  }

  _fetch() {
    _trains.addStream(getTripTrains(tripId: widget.tripId).asStream());
  }

  @override
  void dispose() {
    _trains.close();
    super.dispose();
  }
}

class TrainCard extends StatelessWidget {
  final Train train;
  final VoidCallback? onEdit;

  const TrainCard({
    required this.train,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    const color = TRANSITS_COLOR;

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
                      color: color.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.train,
                      color: color.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        if (train.trainNumber != null) Text(
                          train.trainNumber!,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${train.departure.name} → ${train.arrival.name}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${formatDateTime(train.scheduledDepartureTime)} - ${formatDateTime(train.scheduledArrivalTime)}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.departure_board,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Platform ${train.departure.scheduledPlatform} → Platform ${train.arrival.scheduledPlatform}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
