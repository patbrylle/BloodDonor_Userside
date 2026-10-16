
import 'package:blood_donor/model/blood_request_model.dart';
import 'package:blood_donor/services/api_service.dart';
import 'package:blood_donor/widget/donation_activity.dart';
import 'package:flutter/material.dart';

class Donate extends StatefulWidget {
  const Donate({super.key});

  @override
  State<Donate> createState() => _DonateState();
}

class _DonateState extends State<Donate> {
String? _donorBloodType;
  final _searchController = TextEditingController();
  final _filterButtonKey = GlobalKey();

  String? _selectedBloodType;
  String? _selectedUrgency;

  List<BloodRequest> _requests = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
  }

  try {
    // Fetch the logged-in user's latest saved profile.
    final profile = await ApiService.getProfile();

    // Fetch the latest blood requests.
    final requests = await ApiService.getBloodRequests();

    if (!mounted) return;

    setState(() {
      _donorBloodType = profile.bloodType.trim().toUpperCase();

      _requests = requests
          .where(
            (request) =>
                request.status.trim().toLowerCase() == 'approved',
          )
          .toList();

      _isLoading = false;
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _loadError = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final requests = _requests.where((request) {
      final matchesSearch = query.isEmpty ||
          request.name.toLowerCase().contains(query) ||
          request.bloodType.toLowerCase().contains(query) ||
          request.hospital.toLowerCase().contains(query) ||
          request.location.toLowerCase().contains(query) ||
          request.email.toLowerCase().contains(query) ||
          request.contact.toLowerCase().contains(query) ||
          request.urgency.toLowerCase().contains(query);

      final matchesBloodType = _selectedBloodType == null ||
          request.bloodType == _selectedBloodType;

      final matchesUrgency = _selectedUrgency == null ||
          request.urgency.toLowerCase() ==
              _selectedUrgency!.toLowerCase();

      return matchesSearch && matchesBloodType && matchesUrgency;
    }).toList()
      ..sort((a, b) {
        final compatibility =
            _isCompatible(b.bloodType) == _isCompatible(a.bloodType)
                ? 0
                : (_isCompatible(b.bloodType) ? 1 : -1);

        return compatibility != 0
            ? compatibility
            : b.createdAt.compareTo(a.createdAt);
      });

    final hasActiveFilter = _selectedBloodType != null ||
        _selectedUrgency != null ||
        _searchController.text.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Give blood. Give hope.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your donation can help a patient get the care they need. '
                'Find a request and make a difference today.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
              ),
            ),
            const SizedBox(height: 20),

            // Search and filters
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search requests...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    key: _filterButtonKey,
                    tooltip: 'Filter requests',
                    onSelected: (filter) {
                      if (filter == 'All') {
                        setState(() {
                          _selectedBloodType = null;
                          _selectedUrgency = null;
                        });
                      } else {
                        _showFilterItems(filter);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'All',
                        child: Text('All requests'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'Blood type',
                        child: Text('Blood type                 ›'),
                      ),
                      PopupMenuItem(
                        value: 'Urgency',
                        child: Text('Urgency                       ›'),
                      ),
                    ],
                    icon: Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (hasActiveFilter)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_selectedBloodType != null)
                      Chip(
                        avatar:
                            const Icon(Icons.bloodtype_rounded, size: 16),
                        label: Text(_selectedBloodType!),
                        onDeleted: () =>
                            setState(() => _selectedBloodType = null),
                      ),
                    if (_selectedUrgency != null)
                      Chip(
                        avatar:
                            const Icon(Icons.priority_high_rounded, size: 16),
                        label: Text(_selectedUrgency!),
                        onDeleted: () =>
                            setState(() => _selectedUrgency = null),
                      ),
                    if (_searchController.text.trim().isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.search_rounded, size: 16),
                        label: Text('"${_searchController.text.trim()}"'),
                        onDeleted: () => setState(_searchController.clear),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Loading state
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )

            // Error state
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load blood requests',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadRequests,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              )

            // Empty state
            else if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _requests.isEmpty
                          ? 'No active blood requests'
                          : 'No matching requests found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _requests.isEmpty
                          ? 'New requests will appear here when they are available.'
                          : 'Try another blood type, urgency, or search term.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _selectedBloodType = null;
                          _selectedUrgency = null;
                          _searchController.clear();
                        }),
                        icon: const Icon(Icons.clear_all_rounded),
                        label: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              )

            // Real requests from Laravel
            else
              ...requests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DonationActivityCard(
                    activity: request,
                    isCompatible: _isCompatible(request.bloodType),
                    onJoin: () => _confirmDonation(request),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterItems(String category) async {
    final renderObject =
        _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderObject == null || !mounted) return;

    final buttonRect =
        renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final screenSize = MediaQuery.sizeOf(context);

    final items = category == 'Blood type'
        ? const [
            'All blood types',
            'A+',
            'A-',
            'B+',
            'B-',
            'AB+',
            'AB-',
            'O+',
            'O-',
          ]
        : const [
            'All urgency levels',
            'Normal',
            'Urgent',
            'Critical',
          ];

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonRect.left,
        buttonRect.bottom,
        screenSize.width - buttonRect.right,
        screenSize.height - buttonRect.bottom,
      ),
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (category == 'Blood type') {
        _selectedBloodType =
            selected == 'All blood types' ? null : selected;
      } else {
        _selectedUrgency =
            selected == 'All urgency levels' ? null : selected;
      }
    });
  }

 bool _isCompatible(String recipientBloodType) {
  const compatibleRecipients = {
    'O-': {'O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'},
    'O+': {'O+', 'A+', 'B+', 'AB+'},
    'A-': {'A-', 'A+', 'AB-', 'AB+'},
    'A+': {'A+', 'AB+'},
    'B-': {'B-', 'B+', 'AB-', 'AB+'},
    'B+': {'B+', 'AB+'},
    'AB-': {'AB-', 'AB+'},
    'AB+': {'AB+'},
  };

  final donorType = _donorBloodType?.trim().toUpperCase();
  final recipientType = recipientBloodType.trim().toUpperCase();

  if (donorType == null || donorType.isEmpty) {
    return false;
  }

  return compatibleRecipients[donorType]?.contains(recipientType) ?? false;
}
  Future<void> _confirmDonation(BloodRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help this patient?'),
        content: Text(
          'You are responding to ${request.name}\'s '
          '${request.bloodType} request for ${request.units} '
          '${request.units == 1 ? 'unit' : 'units'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Save the donor's response through Laravel.
    try {
      await ApiService.respondToBloodRequest(id: request.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your response for ${request.name} was submitted successfully.',
          ),
        ),
      );

      // Refresh the list in case the request is no longer active.
      await _loadRequests();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}
