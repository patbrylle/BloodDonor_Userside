import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';

class DonationCentersScreen extends StatefulWidget {
  const DonationCentersScreen({super.key});

  @override
  State<DonationCentersScreen> createState() => _DonationCentersScreenState();
}

class _DonationCentersScreenState extends State<DonationCentersScreen> {
  late Future<List<Map<String, dynamic>>> _centersFuture;

  final MapController _mapController = MapController();

  // Default map position: the coordinates of Manila Bay
  static const LatLng _defaultLocation = LatLng(12.7452939, 121.0535698);

  LatLng? _currentLocation;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  void _loadCenters() {
    _centersFuture = ApiService.getOpenDonationCenters();
  }

  Future<void> _refreshCenters() async {
    setState(_loadCenters);

    try {
      await _centersFuture;
    } catch (_) {
      // The FutureBuilder displays the error.
    }
  }

  String _formatTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not specified';
    }

    final time = value.toString();
    final parts = time.split(':');

    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]);
    final minute = parts[1];

    if (hour == null) return time;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
  }

  // Only centers with valid GPS coordinates can have markers.
  List<Map<String, dynamic>> _centersWithCoordinates(
    List<Map<String, dynamic>> centers,
  ) {
    return centers.where((center) {
      final lat = double.tryParse(center['latitude']?.toString() ?? '');
      final lng = double.tryParse(center['longitude']?.toString() ?? '');

      return lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180;
    }).toList();
  }

  Future<void> _showMyLocation() async {
    if (_gettingLocation) return;

    setState(() => _gettingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please turn on Location in your phone settings.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Enable location permission in your app settings.');
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);

      setState(() => _currentLocation = location);

      // Move the map to your current position.
      _mapController.move(location, 14);
    } catch (error) {
      _showMessage('Unable to get your location. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMap(BuildContext context, List<Map<String, dynamic>> centers) {
    final theme = Theme.of(context);
    final mappedCenters = _centersWithCoordinates(centers);

    final markers = <Marker>[
      for (final center in mappedCenters)
        Marker(
          point: LatLng(
            double.parse(center['latitude'].toString()),
            double.parse(center['longitude'].toString()),
          ),
          width: 50,
          height: 60,
          child: GestureDetector(
            onTap: () {
              final name = center['name']?.toString() ?? 'Donation Center';

              final location =
                  center['location']?.toString() ?? 'Location not specified';

              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text(location)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Select this center from the list below '
                            'for its contact details and opening hours.',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: const Icon(Icons.location_on, color: Colors.red, size: 45),
          ),
        ),

      if (_currentLocation != null)
        Marker(
          point: _currentLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 22),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Donation Center Map',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          mappedCenters.isEmpty
              ? 'No centers have GPS coordinates yet.'
              : 'Tap a map marker to view a center.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? _defaultLocation,
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.blood_donor',
                    ),
                    MarkerLayer(markers: markers),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'myLocationButton',
                    tooltip: 'Show my location',
                    onPressed: _gettingLocation ? null : _showMyLocation,
                    child: _gettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (mappedCenters.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Add latitude and longitude to a center in your '
            'database to display its marker.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildCenterCard(BuildContext context, Map<String, dynamic> center) {
    final theme = Theme.of(context);

    final name = center['name']?.toString() ?? 'Unnamed Center';

    final location = center['location']?.toString() ?? 'Location not specified';

    final contact = center['contact_number']?.toString() ?? '';

    final description = center['description']?.toString() ?? '';

    final openingTime = _formatTime(center['opening_time']);

    final closingTime = _formatTime(center['closing_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: theme.colorScheme.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 17),
                          const SizedBox(width: 4),
                          Expanded(child: Text(location)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OPEN',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Opening hours\n'
                    '$openingTime – $closingTime',
                  ),
                ),
              ],
            ),
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.phone_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Contact number\n$contact')),
                ],
              ),
            ],
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Donation Centers')),
      body: RefreshIndicator(
        onRefresh: _refreshCenters,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _centersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  Center(child: Text('Loading donation centers...')),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load donation centers',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(_loadCenters);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],
              );
            }

            final centers = snapshot.data ?? [];

            if (centers.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 100),
                  Icon(
                    Icons.location_off_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Open Donation Centers',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There are currently no open donation '
                    'centers available. Please check again later.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Find a Donation Center',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View available centers and their opening hours.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Interactive GPS map
                _buildMap(context, centers),

                const SizedBox(height: 28),

                Text(
                  'Available Centers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Existing donation center cards
                ...centers.map((center) => _buildCenterCard(context, center)),
              ],
            );
          },
        ),
      ),
    );
  }
}
