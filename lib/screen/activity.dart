import 'package:flutter/material.dart';

import '../model/blood_drive.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'join.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Text(
            'Your Activity',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Manage activities, track your blood requests, and review your donation history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'You have helped save up to 6 lives.',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.event_available_rounded),
                  text: 'Upcoming',
                ),
                Tab(
                  icon: Icon(Icons.calendar_month_rounded),
                  text: 'My Joined Events',
                ),
                Tab(
                  icon: Icon(Icons.water_drop_rounded),
                  text: 'My Requests',
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: 'History',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 460,
            child: TabBarView(
              children: [
                _UpcomingTab(theme: theme),
                _MyJoinedEventsTab(theme: theme),
                _MyRequestsTab(theme: theme),
                _HistoryTab(theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// SHARED HELPERS
// =========================================================

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.color,
  });

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty
        ? 'Pending'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatActivityDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return 'Date not available';
  }

  final date = DateTime.tryParse(value.toString());

  if (date == null) {
    return value.toString();
  }

  final localDate = date.toLocal();

  return '${localDate.month.toString().padLeft(2, '0')}/'
      '${localDate.day.toString().padLeft(2, '0')}/'
      '${localDate.year}';
}

Map<String, dynamic> _asActivityMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  return <String, dynamic>{};
}

String _activityValue(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = data[key];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return fallback;
}

Color _activityStatusColor(
  String status,
  ThemeData theme,
) {
  switch (status.toLowerCase().trim()) {
    case 'approved':
    case 'confirmed':
    case 'registered':
    case 'completed':
    case 'fulfilled':
      return AppColors.success;

    case 'cancelled':
    case 'rejected':
      return theme.colorScheme.error;

    default:
      return theme.colorScheme.primary;
  }
}

Widget _activityLoading() {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

Widget _activityError({
  required Object error,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

Widget _activityEmpty({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required VoidCallback onRefresh,
}) {
  final theme = Theme.of(context);

  return RefreshIndicator(
    onRefresh: () async {
      onRefresh();
    },
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 35),
        Icon(
          icon,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ),
      ],
    ),
  );
}

// =========================================================
// UPCOMING BLOOD DRIVE EVENTS
// =========================================================

class _UpcomingTab extends StatefulWidget {
  const _UpcomingTab({required this.theme});

  final ThemeData theme;

  @override
  State<_UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends State<_UpcomingTab> {
  late Future<List<BloodDrive>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsFuture = _fetchEvents();
  }

  Future<List<BloodDrive>> _fetchEvents() async {
    final events = await ApiService.getPublishedBloodDriveEvents();

    return events
        .map((event) => BloodDrive.fromJson(event))
        .toList();
  }

  Future<void> _refreshEvents() async {
    final future = _fetchEvents();

    setState(() {
      _eventsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return FutureBuilder<List<BloodDrive>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _activityLoading();
        }

        if (snapshot.hasError) {
          return _activityError(
            error: snapshot.error!,
            onRetry: () => setState(_loadEvents),
          );
        }

        final events = snapshot.data ?? <BloodDrive>[];

        if (events.isEmpty) {
          return _activityEmpty(
            context: context,
            icon: Icons.event_busy_rounded,
            title: 'No upcoming blood drives',
            message: 'Published blood drive events will appear here.',
            onRefresh: () => setState(_loadEvents),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshEvents,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _ActivityInfo(
                        icon: Icons.calendar_today_outlined,
                        text: event.date.isNotEmpty
                            ? event.date
                            : 'Date not available',
                      ),
                      const SizedBox(height: 9),
                      _ActivityInfo(
                        icon: Icons.access_time_outlined,
                        text: event.time.isNotEmpty
                            ? event.time
                            : 'Time not available',
                      ),
                      const SizedBox(height: 9),
                      _ActivityInfo(
                        icon: Icons.location_on_outlined,
                        text: event.location.isNotEmpty
                            ? event.location
                            : 'Venue not available',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            BloodActivityDialog.show(context, event);
                          },
                          icon: const Icon(
                            Icons.event_available_rounded,
                          ),
                          label: const Text('View activity'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =========================================================
// MY JOINED EVENTS
// Loads the signed-in user's event registrations.
// =========================================================

class _MyJoinedEventsTab extends StatefulWidget {
  const _MyJoinedEventsTab({required this.theme});

  final ThemeData theme;

  @override
  State<_MyJoinedEventsTab> createState() =>
      _MyJoinedEventsTabState();
}

class _MyJoinedEventsTabState extends State<_MyJoinedEventsTab> {
  late Future<List<Map<String, dynamic>>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  void _loadRegistrations() {
    _registrationsFuture =
        ApiService.getMyBloodDriveEventRegistrations();
  }

  Future<void> _refreshRegistrations() async {
    final future =
        ApiService.getMyBloodDriveEventRegistrations();

    setState(() {
      _registrationsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _registrationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _activityLoading();
        }

        if (snapshot.hasError) {
          return _activityError(
            error: snapshot.error!,
            onRetry: () => setState(_loadRegistrations),
          );
        }

        final registrations =
            snapshot.data ?? <Map<String, dynamic>>[];

        if (registrations.isEmpty) {
          return _activityEmpty(
            context: context,
            icon: Icons.event_busy_rounded,
            title: 'No joined events yet',
            message: 'Events you register for will appear here.',
            onRefresh: () => setState(_loadRegistrations),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshRegistrations,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: registrations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final registration = registrations[index];

              // Support common Laravel relationship names.
              final event = _asActivityMap(
                registration['blood_drive_event'] ??
                    registration['bloodDriveEvent'] ??
                    registration['event'],
              );

              final name = _activityValue(
                event,
                ['name', 'title', 'event_name'],
                fallback: _activityValue(
                  registration,
                  ['event_name', 'name', 'title'],
                  fallback: 'Blood Drive Event',
                ),
              );

              final description = _activityValue(
                event,
                ['description'],
                fallback: _activityValue(
                  registration,
                  ['description'],
                ),
              );

              final date = _activityValue(
                event,
                [
                  'date',
                  'event_date',
                  'start_date',
                  'event_date_time',
                ],
                fallback: _activityValue(
                  registration,
                  ['event_date', 'date', 'start_date'],
                ),
              );

              final time = _activityValue(
                event,
                ['time', 'event_time', 'start_time'],
                fallback: _activityValue(
                  registration,
                  ['event_time', 'time', 'start_time'],
                ),
              );

              final location = _activityValue(
                event,
                ['location', 'venue', 'address'],
                fallback: _activityValue(
                  registration,
                  ['location', 'venue', 'address'],
                  fallback: 'Venue not available',
                ),
              );

              final status = _activityValue(
                registration,
                ['status'],
                fallback: 'Registered',
              );

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _ActivityInfo(
                        icon: Icons.calendar_today_outlined,
                        text: _formatActivityDate(date),
                      ),
                      const SizedBox(height: 8),
                      _ActivityInfo(
                        icon: Icons.access_time_outlined,
                        text: time.isEmpty
                            ? 'Time not available'
                            : time,
                      ),
                      const SizedBox(height: 8),
                      _ActivityInfo(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                      const SizedBox(height: 14),
                      _StatusChip(
                        status: status,
                        color: _activityStatusColor(status, theme),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =========================================================
// MY BLOOD REQUESTS
// =========================================================

class _MyRequestsTab extends StatefulWidget {
  const _MyRequestsTab({required this.theme});

  final ThemeData theme;

  @override
  State<_MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<_MyRequestsTab> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = ApiService.getMyBloodRequests();
  }

  Future<void> _refreshRequests() async {
    final future = ApiService.getMyBloodRequests();

    setState(() {
      _requestsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  String _statusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Your blood request has been approved by the administrator.';
      case 'cancelled':
      case 'rejected':
        return 'This blood request was cancelled or rejected.';
      case 'fulfilled':
        return 'This blood request has been fulfilled.';
      default:
        return 'Your blood request is waiting for administrator review.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _activityLoading();
        }

        if (snapshot.hasError) {
          return _activityError(
            error: snapshot.error!,
            onRetry: () => setState(_loadRequests),
          );
        }

        final requests =
            snapshot.data ?? <Map<String, dynamic>>[];

        if (requests.isEmpty) {
          return _activityEmpty(
            context: context,
            icon: Icons.inbox_rounded,
            title: 'No blood requests yet',
            message: 'Your submitted blood requests will appear here.',
            onRefresh: () => setState(_loadRequests),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];

              final patientName = _activityValue(
                request,
                ['patient_name'],
                fallback: 'Unknown patient',
              );

              final bloodType = _activityValue(
                request,
                ['blood_type'],
                fallback: 'N/A',
              );

              final units = _activityValue(
                request,
                ['units_needed'],
                fallback: '0',
              );

              final hospital = _activityValue(
                request,
                ['hospital'],
                fallback: 'Not specified',
              );

              final status = _activityValue(
                request,
                ['status'],
                fallback: 'pending',
              );

              final color = _activityStatusColor(status, theme);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              Icons.water_drop_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                _StatusChip(
                                  status: status,
                                  color: color,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ActivityInfo(
                        icon: Icons.water_drop_outlined,
                        text: 'Blood type: $bloodType',
                      ),
                      const SizedBox(height: 8),
                      _ActivityInfo(
                        icon: Icons.inventory_2_outlined,
                        text: 'Units needed: $units',
                      ),
                      const SizedBox(height: 8),
                      _ActivityInfo(
                        icon: Icons.location_on_outlined,
                        text: 'Hospital: $hospital',
                      ),
                      const SizedBox(height: 8),
                      _ActivityInfo(
                        icon: Icons.calendar_today_outlined,
                        text:
                            'Submitted: ${_formatActivityDate(request['created_at'])}',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _statusMessage(status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =========================================================
// DONATION RESPONSE HISTORY
// =========================================================

class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.theme});

  final ThemeData theme;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  late Future<List<Map<String, dynamic>>> _donationsFuture;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  void _loadDonations() {
    _donationsFuture = ApiService.getMyDonationResponses();
  }

  Future<void> _refreshDonations() async {
    final future = ApiService.getMyDonationResponses();

    setState(() {
      _donationsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _donationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _activityLoading();
        }

        if (snapshot.hasError) {
          return _activityError(
            error: snapshot.error!,
            onRetry: () => setState(_loadDonations),
          );
        }

        final donations =
            snapshot.data ?? <Map<String, dynamic>>[];

        if (donations.isEmpty) {
          return _activityEmpty(
            context: context,
            icon: Icons.volunteer_activism_rounded,
            title: 'No donation responses yet',
            message:
                'Your responses to blood requests will appear here.',
            onRefresh: () => setState(_loadDonations),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshDonations,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: donations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final donation = donations[index];

              final patientName = _activityValue(
                donation,
                ['patient_name'],
                fallback: 'Unknown patient',
              );

              final bloodType = _activityValue(
                donation,
                ['blood_type'],
                fallback: 'N/A',
              );

              final units = _activityValue(
                donation,
                ['units'],
                fallback: '0',
              );

              final status = _activityValue(
                donation,
                ['status'],
                fallback: 'pending',
              );

              final color = _activityStatusColor(status, theme);

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    patientName,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Blood type: $bloodType\n'
                      'Units: $units\n'
                      '${_formatActivityDate(donation['donated_at'])}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: _StatusChip(
                    status: status,
                    color: color,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
