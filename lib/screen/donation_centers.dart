import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DonationCentersScreen extends StatefulWidget {
  const DonationCentersScreen({super.key});

  @override
  State<DonationCentersScreen> createState() =>
      _DonationCentersScreenState();
}

class _DonationCentersScreenState
    extends State<DonationCentersScreen> {
  late Future<List<Map<String, dynamic>>> _centersFuture;

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
    await _centersFuture;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Centers'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCenters,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _centersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return  ListView(
                children: [
                  SizedBox(height: 180),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Loading donation centers...'),
                  ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error
                        .toString()
                        .replaceFirst('Exception: ', ''),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                ...centers.map((center) {
                  final name =
                      center['name']?.toString() ??
                      'Unnamed Center';
                  final location =
                      center['location']?.toString() ??
                      'Location not specified';
                  final contact =
                      center['contact_number']?.toString() ?? '';
                  final description =
                      center['description']?.toString() ?? '';
                  final openingTime =
                      _formatTime(center['opening_time']);
                  final closingTime =
                      _formatTime(center['closing_time']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme
                                          .textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(location),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 20,
                              ),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Contact number\n$contact',
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (description.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}