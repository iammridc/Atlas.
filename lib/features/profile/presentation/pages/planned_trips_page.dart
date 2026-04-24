import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/injections/injections.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/features/profile/domain/entities/planned_trip_entity.dart';
import 'package:atlas/features/profile/domain/repositories/profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/favorite_places_page.dart';
import 'package:flutter/material.dart';

class PlannedTripsPage extends StatefulWidget {
  const PlannedTripsPage({super.key});

  @override
  State<PlannedTripsPage> createState() => _PlannedTripsPageState();
}

class _PlannedTripsPageState extends State<PlannedTripsPage> {
  final _repository = getIt<ProfileRepository>();
  bool _isLoading = true;
  String? _errorMessage;
  List<PlannedTripEntity> _trips = const [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getPlannedTrips();
    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      }),
      (trips) => setState(() {
        _isLoading = false;
        _trips = trips;
      }),
    );
  }

  Future<void> _showTripForm({PlannedTripEntity? trip}) async {
    final titleController = TextEditingController(text: trip?.title ?? '');
    final routeController = TextEditingController(
      text: trip?.routeSummary ?? '',
    );
    final noteController = TextEditingController(text: trip?.note ?? '');
    var isSaving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip == null ? 'Add planned trip' : 'Edit planned trip',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Trip title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: routeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Route',
                      hintText: 'Minsk -> Vilnius -> Warsaw',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Timing, hotels, transport swaps, reminders',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final result = await _repository.savePlannedTrip(
                                PlannedTripEntity(
                                  id: trip?.id ?? '',
                                  title: titleController.text,
                                  routeSummary: routeController.text,
                                  note: noteController.text,
                                  updatedAt: DateTime.now(),
                                ),
                              );

                              if (!mounted) return;
                              result.fold((error) {
                                setModalState(() => isSaving = false);
                                AppSnackbar.show(
                                  context,
                                  message: error.message,
                                  type: SnackbarType.error,
                                );
                              }, (_) => Navigator.of(context).pop(true));
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(trip == null ? 'Save trip' : 'Save changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    routeController.dispose();
    noteController.dispose();

    if (saved == true) {
      await _loadTrips();
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: trip == null ? 'Trip added.' : 'Trip updated.',
        type: SnackbarType.success,
      );
    }
  }

  Future<void> _deleteTrip(PlannedTripEntity trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete trip?'),
          content: Text('Remove "${trip.title}" from your planned trips?'),
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
        );
      },
    );

    if (confirmed != true) return;

    final result = await _repository.deletePlannedTrip(trip.id);
    if (!mounted) return;

    result.fold(
      (error) => AppSnackbar.show(
        context,
        message: error.message,
        type: SnackbarType.error,
      ),
      (_) async {
        await _loadTrips();
        if (!mounted) return;
        AppSnackbar.show(
          context,
          message: 'Trip deleted.',
          type: SnackbarType.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Planned Trips')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTripForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add trip'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ProfileCollectionErrorState(
                message: _errorMessage!,
                onRetry: _loadTrips,
              )
            : _trips.isEmpty
            ? const ProfileCollectionEmptyState(
                title: 'No trips planned yet',
                message:
                    'Save trip ideas here so you can edit routes and notes later.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: _trips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final trip = _trips[index];
                  return ProfileManagementCard(
                    title: trip.title,
                    subtitle: trip.routeSummary,
                    body: trip.note.isEmpty ? null : trip.note,
                    trailing: formatProfileDate(trip.updatedAt),
                    onTap: () => _showTripForm(trip: trip),
                    onDelete: () => _deleteTrip(trip),
                  );
                },
              ),
      ),
    );
  }
}
