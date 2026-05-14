import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:skywing_tracker/core/theme.dart';
import 'package:skywing_tracker/core/constants.dart';
import 'package:skywing_tracker/features/flights/models/flight_session.dart';
import 'package:skywing_tracker/features/flights/models/flight_participant.dart';
import 'package:skywing_tracker/features/flights/providers/flight_provider.dart';
import 'package:skywing_tracker/features/pigeons/providers/pigeon_provider.dart';
import 'package:skywing_tracker/features/pigeons/models/pigeon.dart';

class CreateFlightScreen extends ConsumerStatefulWidget {
  const CreateFlightScreen({super.key});

  @override
  ConsumerState<CreateFlightScreen> createState() => _CreateFlightScreenState();
}

class _CreateFlightScreenState extends ConsumerState<CreateFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  FlightType _selectedType = FlightType.training;
  LatLng? _selectedLocation;
  String? _locationName;
  String? _weatherJson;
  bool _fetchingWeather = false;
  final Set<String> _selectedPigeonIds = {};
  bool _saving = false;

  GoogleMapController? _mapController;

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _locationName =
          '${pos.latitude.toStringAsFixed(4)}, '
          '${pos.longitude.toStringAsFixed(4)}';
      _fetchingWeather = true;
      _weatherJson = null;
    });
    await _fetchWeather(pos.latitude, pos.longitude);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.weatherapi.com/v1/current.json'
        '?key=${AppConstants.weatherApiKey}&q=$lat,$lon',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _weatherJson = response.body;
          _fetchingWeather = false;
        });
      } else {
        setState(() => _fetchingWeather = false);
      }
    } catch (_) {
      setState(() => _fetchingWeather = false);
    }
  }

  String _parseWeatherSummary(String? json) {
    if (json == null) return 'N/A';
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final condition =
          (current['condition'] as Map<String, dynamic>)['text'] as String;
      final tempC = current['temp_c'];
      final windKph = current['wind_kph'];
      return '$condition, ${tempC}°C, Wind: ${windKph} km/h';
    } catch (_) {
      return 'Weather data available';
    }
  }

  Future<void> _createFlight(List<Pigeon> allPigeons) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a release location')),
      );
      return;
    }
    if (_selectedPigeonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pigeon')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(flightRepositoryProvider);
      final now = DateTime.now();
      const uuid = Uuid();

      final flight = FlightSession(
        id: uuid.v4(),
        ownerId: '',
        name: _nameController.text.trim(),
        type: _selectedType,
        status: FlightStatus.released,
        releaseTime: now,
        releaseLatitude: _selectedLocation!.latitude,
        releaseLongitude: _selectedLocation!.longitude,
        releaseLocationName: _locationName,
        weatherConditions: _weatherJson,
        createdAt: now,
        updatedAt: now,
      );

      final created = await repo.createFlight(flight);

      // Create participants
      final selectedPigeons = allPigeons
          .where((p) => _selectedPigeonIds.contains(p.id))
          .toList();

      for (final pigeon in selectedPigeons) {
        final participant = FlightParticipant(
          id: uuid.v4(),
          flightSessionId: created.id,
          pigeonId: pigeon.id,
          pigeonName: pigeon.name,
          pigeonRingNumber: pigeon.ringNumber,
          status: FlightStatus.released,
        );
        await repo.updateParticipant(participant);
      }

      ref.invalidate(flightsProvider);

      if (mounted) {
        context.go('/flights/${created.id}/live');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pigeonsAsync = ref.watch(pigeonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Flight')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Flight Name',
                hintText: 'e.g. Morning Training Run',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Type selector
            const Text(
              'Flight Type',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: FlightType.values.map((type) {
                final selected = _selectedType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withOpacity(0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : AppColors.divider,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type == FlightType.training
                                ? 'Training'
                                : 'Competition',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Map location picker
            const Text(
              'Release Location',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(52.2297, 21.0122),
                    zoom: 6,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('release'),
                            position: _selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
                        }
                      : {},
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
              ),
            ),
            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: $_locationName',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Weather
            if (_fetchingWeather)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fetching weather...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              )
            else if (_weatherJson != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _parseWeatherSummary(_weatherJson),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Pigeon multi-select
            const Text(
              'Select Pigeons',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            pigeonsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Error loading pigeons: $e',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (pigeons) {
                final active = pigeons.where((p) => p.isActive).toList();
                if (active.isEmpty) {
                  return const Text(
                    'No active pigeons found.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: active.map((pigeon) {
                    final selected = _selectedPigeonIds.contains(pigeon.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedPigeonIds.add(pigeon.id);
                          } else {
                            _selectedPigeonIds.remove(pigeon.id);
                          }
                        });
                      },
                      title: Text(
                        pigeon.name,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        pigeon.ringNumber,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      activeColor: AppColors.accent,
                      checkColor: AppColors.primary,
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Create button
            pigeonsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (pigeons) => ElevatedButton(
                onPressed: _saving ? null : () => _createFlight(pigeons),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text('Start Flight'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
