import 'package:blood_donor/model/blood_request_model.dart';
import 'package:blood_donor/model/blood_drive.dart';
import 'package:flutter/material.dart';

import '../screen/join.dart';
import '../services/api_service.dart';
import '../theme/app_radius.dart';

// =========================================================
// DONATION ACTIVITY CARD
// Displays a blood request and its donor information.
// =========================================================

class DonationActivityCard extends StatefulWidget {
  const DonationActivityCard({
    super.key,
    required this.activity,
    required this.onJoin,
    required this.isCompatible,
  });

  final BloodRequest activity;
  final VoidCallback onJoin;
  final bool isCompatible;

  @override
  State<DonationActivityCard> createState() =>
      _DonationActivityCardState();
}

// =========================================================
// UPCOMING BLOOD ACTIVITIES
// Loads published events from the Laravel API.
// =========================================================

class UpcomingBloodActivitiesScreen extends StatefulWidget {
  const UpcomingBloodActivitiesScreen({super.key});

  @override
  State<UpcomingBloodActivitiesScreen> createState() =>
      _UpcomingBloodActivitiesScreenState();
}

class _UpcomingBloodActivitiesScreenState
    extends State<UpcomingBloodActivitiesScreen> {
  late Future<List<BloodDrive>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  Future<List<BloodDrive>> _fetchEvents() async {
    final events = await ApiService.getPublishedBloodDriveEvents();

    return events.map((event) => BloodDrive.fromJson(event)).toList();
  }

  void _retryLoading() {
    setState(() {
      _eventsFuture = _fetchEvents();
    });
  }

  Future<void> _refreshEvents() async {
    final future = _fetchEvents();

    setState(() {
      _eventsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error message.
    }
  }

  void _openEvent(BloodDrive activity) {
    BloodActivityDialog.show(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Blood Activities'),
      ),
      body: FutureBuilder<List<BloodDrive>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load blood drive events.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error
                              ?.toString()
                              .replaceFirst('Exception: ', '') ??
                          'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retryLoading,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final activities = snapshot.data ?? <BloodDrive>[];

          if (activities.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshEvents,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 90),
                  Icon(
                    Icons.event_busy_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming blood drives',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Published blood drive events will appear here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Pull down to refresh.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshEvents,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final activity = activities[index];

                return _UpcomingActivityCard(
                  activity: activity,
                  onTap: () => _openEvent(activity),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// =========================================================
// UPCOMING EVENT CARD
// =========================================================

class _UpcomingActivityCard extends StatelessWidget {
  const _UpcomingActivityCard({
    required this.activity,
    required this.onTap,
  });

  final BloodDrive activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                activity.description.isNotEmpty
                    ? activity.description
                    : 'Give blood, give hope.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _ActivityDetailRow(
                icon: Icons.calendar_today_outlined,
                label: activity.date,
              ),
              const SizedBox(height: 8),
              _ActivityDetailRow(
                icon: Icons.access_time_outlined,
                label: activity.time,
              ),
              const SizedBox(height: 8),
              _ActivityDetailRow(
                icon: Icons.location_on_outlined,
                label: activity.location,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.event_available_rounded),
                  label: const Text('View Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// EVENT DETAIL ROW
// =========================================================

class _ActivityDetailRow extends StatelessWidget {
  const _ActivityDetailRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
      ],
    );
  }
}

// =========================================================
// BLOOD REQUEST CARD STATE
// Keep the existing donor request functionality.
// =========================================================

class _DonationActivityCardState extends State<DonationActivityCard> {
  bool _showProfile = false;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.bloodtype_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLOOD REQUEST',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.hospital} • ${activity.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _RequestBadge(
                  icon: Icons.bloodtype_rounded,
                  label: activity.bloodType,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RequestBadge(
                  icon: Icons.priority_high_rounded,
                  label: activity.urgency,
                  color: _urgencyColor(activity.urgency),
                ),
                if (widget.isCompatible)
                  const _RequestBadge(
                    icon: Icons.check_circle_rounded,
                    label: 'Compatible',
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.water_drop_outlined,
                    label:
                        '${activity.units} ${activity.units == 1 ? 'unit' : 'units'} needed',
                  ),
                ),
                _SummaryItem(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(activity.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showProfile = !_showProfile;
                      });
                    },
                    icon: Icon(
                      _showProfile
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.person_outline_rounded,
                    ),
                    label: Text(
                      _showProfile ? 'Hide details' : 'View details',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onJoin,
                    icon: const Icon(Icons.volunteer_activism_rounded),
                    label: const Text('Donate'),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: !_showProfile
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            InfoRow(
                              icon: Icons.email_outlined,
                              label: activity.email,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              icon: Icons.phone_outlined,
                              label: activity.contact,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              icon: Icons.location_on_outlined,
                              label: activity.location,
                            ),
                            const SizedBox(height: 10),
                            InfoRow(
                              icon: Icons.local_hospital_outlined,
                              label: activity.hospital,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// SUMMARY ITEM
// =========================================================

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// REQUEST BADGE
// =========================================================

class _RequestBadge extends StatelessWidget {
  const _RequestBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// DONOR INFORMATION ROW
// =========================================================

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// HELPER FUNCTIONS
// =========================================================

Color _urgencyColor(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return const Color(0xFFD32F2F);
    case 'urgent':
      return const Color(0xFFE07800);
    default:
      return const Color(0xFF9A7200);
  }
}

String _formatDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
