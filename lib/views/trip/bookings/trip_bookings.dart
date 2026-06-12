import 'package:flutter/material.dart';
import 'package:holiday_planner/colors.dart';
import 'package:holiday_planner/services/data_change_bus.dart';
import 'package:holiday_planner/services/refreshable_data.dart';
import 'package:holiday_planner/src/rust/api/bookings.dart';
import 'package:holiday_planner/src/rust/models/bookings.dart';
import 'package:holiday_planner/date_format.dart';
import 'package:holiday_planner/views/trip/bookings/add_reservation.dart';
import 'package:holiday_planner/views/trip/bookings/add_car_rental.dart';
import 'package:holiday_planner/views/trip/bookings/edit_reservation.dart';
import 'package:holiday_planner/views/trip/bookings/edit_car_rental.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class TripBookings extends StatefulWidget {
  final UuidValue tripId;

  const TripBookings({super.key, required this.tripId});

  @override
  State<TripBookings> createState() => _TripBookingsState();
}

class _TripBookingsState extends State<TripBookings> {
  late final _bookings = RefreshableData<List<Booking>>(
    fetch: () => getTripBookings(tripId: widget.tripId),
    refreshOn: [DataChangeBus.instance.onBookingsChanged(widget.tripId)],
  );

  @override
  void dispose() {
    _bookings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildUnifiedBookingsList(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildUnifiedBookingsList() {
    return StreamBuilder(
      stream: _bookings.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var bookings = snapshot.requireData;
        if (bookings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.book_online_outlined,
            title: "No bookings",
            subtitle: "Add reservations and car rental bookings for your trip",
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var booking = bookings[index];
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return booking.when(
      reservation: (reservation) => ReservationCard(
        reservation: reservation,
        onEdit: () => _editReservation(context, reservation),
        onDelete: () => _deleteReservation(context, reservation),
      ),
      carRental: (carRental) => CarRentalCard(
        carRental: carRental,
        onEdit: () => _editCarRental(context, carRental),
        onDelete: () => _deleteCarRental(context, carRental),
      ),
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

  Widget _buildFloatingActionButtons() {
    return FloatingActionButton(
      heroTag: "add_booking_fab",
      onPressed: () => _showAddBookingMenu(context),
      child: const Icon(Icons.add),
    );
  }

  void _showAddBookingMenu(BuildContext context) {
    var bookingColorScheme = ColorScheme.fromSeed(seedColor: BOOKINGS_COLOR);
    var carRentalColorScheme = ColorScheme.fromSeed(seedColor: CAR_RENTAL_COLOR);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Booking'),
          contentPadding: const EdgeInsets.only(top: 20.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bookingColorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: bookingColorScheme.primary,
                    size: 24,
                  ),
                ),
                title: const Text('Add Reservation'),
                subtitle: const Text('Restaurant, hotel, or other booking'),
                onTap: () {
                  Navigator.pop(context);
                  _addReservation(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: carRentalColorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: carRentalColorScheme.primary,
                    size: 24,
                  ),
                ),
                title: const Text('Add Car Rental'),
                subtitle: const Text('Car rental booking'),
                onTap: () {
                  Navigator.pop(context);
                  _addCarRental(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addReservation(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddReservationPage(tripId: widget.tripId)));
  }

  void _addCarRental(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AddCarRentalPage(tripId: widget.tripId)));
  }

  void _editReservation(BuildContext context, Reservation reservation) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditReservationPage(reservation: reservation)));
  }

  void _editCarRental(BuildContext context, CarRental carRental) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditCarRentalPage(carRental: carRental)));
  }

  void _deleteReservation(BuildContext context, Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: Text('Are you sure you want to delete "${reservation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteReservation(reservationId: reservation.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting reservation: $e')),
          );
        }
      }
    }
  }

  void _deleteCarRental(BuildContext context, CarRental carRental) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car Rental'),
        content: Text('Are you sure you want to delete the ${carRental.provider} rental?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteCarRental(carRentalId: carRental.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting car rental: $e')),
          );
        }
      }
    }
  }

}

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReservationCard({
    required this.reservation,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var bookingColorScheme = ColorScheme.fromSeed(seedColor: BOOKINGS_COLOR, brightness: colorScheme.brightness);
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
                      color: bookingColorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      reservation.category == ReservationCategory.restaurant 
                          ? Icons.restaurant 
                          : Icons.local_activity,
                      color: bookingColorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reservation.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            reservation.address!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                    "${formatDateTime(reservation.startDate)} ${reservation.endDate != null ? ' - ${formatDateTime(reservation.endDate!)}' : ''}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (reservation.bookingNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reservation.bookingNumber!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (reservation.link != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(reservation.link!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Open Link"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class CarRentalCard extends StatelessWidget {
  final CarRental carRental;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CarRentalCard({
    required this.carRental,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var carRentalColorScheme = ColorScheme.fromSeed(seedColor: CAR_RENTAL_COLOR, brightness: colorScheme.brightness);
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
                      color: carRentalColorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: carRentalColorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carRental.provider,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          carRental.pickUpLocation,
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
                    "${formatDateTime(carRental.pickUpDate)} - ${formatDateTime(carRental.returnDate)}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (carRental.returnLocation != null && carRental.returnLocation != carRental.pickUpLocation) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Return: ${carRental.returnLocation!}",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (carRental.bookingNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      carRental.bookingNumber!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
