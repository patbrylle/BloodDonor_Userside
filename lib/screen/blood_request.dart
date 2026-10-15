
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/blood_donor.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() =>
      _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  List<BloodDonor> _donors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedBloodType = 'All';

  final List<String> _bloodTypes = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonors() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final donors = await ApiService.getActiveDonors();

      if (!mounted) return;

      setState(() {
        _donors = donors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load donors. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<BloodDonor> get _filteredDonors {
    final query = _searchController.text.trim().toLowerCase();

    return _donors.where((donor) {
      final matchesSearch =
          donor.name.toLowerCase().contains(query) ||
          donor.bloodType.toLowerCase().contains(query) ||
          donor.location.toLowerCase().contains(query);

      final matchesBloodType =
          _selectedBloodType == 'All' ||
          donor.bloodType.toUpperCase() ==
              _selectedBloodType.toUpperCase();

      return matchesSearch && matchesBloodType;
    }).toList();
  }

 
Future<void> _openRequestForm() async {
  List<Map<String, dynamic>> donationCenters;

  try {
    donationCenters = await ApiService.getOpenDonationCenters();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not load donation centers: $e')),
    );
    return;
  }

  // Only use centers with valid integer IDs.
  donationCenters = donationCenters.where((center) {
    return int.tryParse(center['id']?.toString() ?? '') != null;
  }).toList();

  if (donationCenters.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No available donation centers were found.'),
      ),
    );
    return;
  }

  Position? userPosition;

  // Try to get the user's location. If unavailable, continue without it.
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (serviceEnabled) {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        userPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      }
    }
  } catch (_) {
    // The user can still choose a center without GPS.
  }

  double distanceKmFor(Map<String, dynamic> center) {
    if (userPosition == null) return double.infinity;

    final latitude =
        double.tryParse(center['latitude']?.toString() ?? '');
    final longitude =
        double.tryParse(center['longitude']?.toString() ?? '');

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return double.infinity;
    }

   return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      latitude,
      longitude,
    ) /
    1000;
  }

  // Nearest center first. Centers without GPS coordinates go last.
  donationCenters.sort((a, b) {
    final distanceComparison =
        distanceKmFor(a).compareTo(distanceKmFor(b));

    if (distanceComparison != 0) return distanceComparison;

    return (a['name']?.toString() ?? '')
        .compareTo(b['name']?.toString() ?? '');
  });

  final formKey = GlobalKey<FormState>();
  final patientNameController = TextEditingController();
  final notesController = TextEditingController();

  int? selectedDonationCenterId =
      int.tryParse(donationCenters.first['id'].toString());

  String selectedBloodType = 'O+';
  int unitsNeeded = 1;
  String urgency = 'Normal';
  bool isSubmitting = false;
if (!mounted) return;

try {
  final submitted = await showDialog<bool>(
    context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Make a Blood Request'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: patientNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the patient name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedBloodType,
                        decoration: const InputDecoration(
                          labelText: 'Required Blood Type',
                          prefixIcon: Icon(Icons.bloodtype),
                          border: OutlineInputBorder(),
                        ),
                        items: _bloodTypes
                            .where((type) => type != 'All')
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedBloodType = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        initialValue: unitsNeeded,
                        decoration: const InputDecoration(
                          labelText: 'Units Needed',
                          prefixIcon: Icon(Icons.medical_services),
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(5, (index) {
                          final units = index + 1;

                          return DropdownMenuItem<int>(
                            value: units,
                            child: Text(
                              '$units ${units == 1 ? 'unit' : 'units'}',
                            ),
                          );
                        }),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    unitsNeeded = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        initialValue: selectedDonationCenterId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Donation Center',
                          prefixIcon: const Icon(
                            Icons.local_hospital_outlined,
                          ),
                          border: const OutlineInputBorder(),
                          helperText: userPosition == null
                              ? 'Choose an available donation center'
                              : 'Centers sorted by distance from you',
                        ),
                        items: donationCenters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final center = entry.value;
                          final distance = distanceKmFor(center);
                          final recommended = index == 0 &&
                              userPosition != null &&
                              distance.isFinite;

                          final name =
                              center['name']?.toString() ?? 'Donation Center';
                          final location =
                              center['location']?.toString() ?? '';

                          final details = <String>[
                            if (location.isNotEmpty) location,
                            if (distance.isFinite)
                              '${distance.toStringAsFixed(1)} km away',
                            if (recommended) 'Recommended',
                          ].join(' · ');

                          return DropdownMenuItem<int>(
                            value: int.parse(center['id'].toString()),
                            child: Text(
                              details.isEmpty ? name : '$name\n$details',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedDonationCenterId = value;
                                  });
                                }
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a donation center.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: urgency,
                        decoration: const InputDecoration(
                          labelText: 'Urgency',
                          prefixIcon: Icon(Icons.priority_high),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Normal',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: 'Urgent',
                            child: Text('Urgent'),
                          ),
                          DropdownMenuItem(
                            value: 'Critical',
                            child: Text('Critical'),
                          ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    urgency = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            final notes = [
                              if (urgency != 'Normal') 'Urgency: $urgency',
                              if (notesController.text.trim().isNotEmpty)
                                notesController.text.trim(),
                            ].join('\n');

                            await ApiService.createBloodRequest(
                              patientName: patientNameController.text.trim(),
                              bloodType: selectedBloodType,
                              unitsNeeded: unitsNeeded,
                              donationCenterId: selectedDonationCenterId!,
                              notes: notes.isEmpty ? null : notes,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.of(dialogContext).pop(true);
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              isSubmitting = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (submitted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blood request submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDonors();
    }
  } finally {
    patientNameController.dispose();
    notesController.dispose();
  }
}

  void _openDonorDetails(BloodDonor donor) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DonorDetailsScreen(donor: donor),
      ),
    );
  }

  Widget _buildDonorCard(BloodDonor donor) {
    final theme = Theme.of(context);

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
                CircleAvatar(
                  radius: 27,
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Text(
                    donor.bloodType,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            donor.isAvailable
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 16,
                            color: donor.isAvailable
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            donor.isAvailable
                                ? 'Available'
                                : 'Unavailable',
                            style: TextStyle(
                              color: donor.isAvailable
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    donor.location.isNotEmpty
                        ? donor.location
                        : 'Location not provided',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    donor.contact.isNotEmpty
                        ? donor.contact
                        : 'Contact number not provided',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openDonorDetails(donor),
                icon: const Icon(Icons.contact_phone_outlined),
                label: const Text('Contact Donor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadDonors,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final donors = _filteredDonors;

    if (donors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _donors.isEmpty
                    ? 'No active donors found.'
                    : 'No donors match your search.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try changing your search or blood type filter.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonors,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: donors.length,
        itemBuilder: (context, index) {
          return _buildDonorCard(donors[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Blood'),
        actions: [
          IconButton(
            tooltip: 'Refresh donors',
            onPressed: _loadDonors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search donor, blood type, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              decoration: InputDecoration(
                labelText: 'Filter by blood type',
                prefixIcon: const Icon(Icons.bloodtype),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _bloodTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type == 'All' ? 'All Blood Types' : type,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBloodType = value;
                  });
                }
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openRequestForm,
                icon: const Icon(Icons.add),
                label: const Text('Make a Blood Request'),
              ),
            ),
          ),

          Expanded(
            child: _buildDonorList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DONOR DETAILS SCREEN
// ============================================================

class DonorDetailsScreen extends StatelessWidget {
  final BloodDonor donor;

  const DonorDetailsScreen({
    super.key,
    required this.donor,
  });

  Future<void> _callDonor(BuildContext context) async {
    final phone = donor.contact.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This donor has no contact number.'),
        ),
      );
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the phone dialer.'),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone dialer.'),
        ),
      );
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isNotEmpty ? value : 'Not provided'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),

          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                donor.bloodType,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            donor.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Chip(
              avatar: Icon(
                donor.isAvailable
                    ? Icons.check_circle
                    : Icons.schedule,
                color: donor.isAvailable
                    ? Colors.green
                    : Colors.orange,
              ),
              label: Text(
                donor.isAvailable
                    ? 'Available to Donate'
                    : 'Currently Unavailable',
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.bloodtype,
                  title: 'Blood Type',
                  value: donor.bloodType,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: donor.location,
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  icon: Icons.phone_outlined,
                  title: 'Contact Number',
                  value: donor.contact,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: donor.contact.trim().isEmpty
                  ? null
                  : () => _callDonor(context),
              icon: const Icon(Icons.call),
              label: const Text('Call Donor'),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Please contact the donor respectfully and confirm '
            'their availability before making arrangements.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
