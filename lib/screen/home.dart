import 'package:flutter/material.dart';

import '../model/user_profile.dart';
import '../model/blood_drive.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../widget/gradient_button.dart';
import '../widget/app_logo.dart';
import '../widget/donation_activity.dart';

import 'drawer.dart';
import 'join.dart';
import 'donate_screen.dart';
import 'blood_request.dart';
import 'profile.dart';
import 'notifications.dart';
import 'activity.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomescreenState();
}


class _HomescreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;

  UserProfile? _user;
  bool _isLoadingProfile = true;
  String? _profileError;
  Timer? _profileRefreshTimer;

  int _completedDonations = 0;
  int _livesHelped = 0;
  bool _isLoadingImpact = true;

 @override
void initState() {
  super.initState();

  _currentIndex = widget.initialIndex;

  WidgetsBinding.instance.addObserver(this);

  _loadProfile();

    _profileRefreshTimer = Timer.periodic(
  const Duration(seconds: 30),
  (_) {
    _refreshProfile();
    _loadImpact();
  },
);
}
Future<void> _loadImpact() async {
  try {
    final donations = await ApiService.getMyDonationResponses();

    final completedDonations = donations.where(
      (donation) => donation['status']?.toString().toLowerCase() == 'completed',
    );

    final completedList = completedDonations.toList();

    final livesHelped = completedList.fold<int>(
      0,
      (total, donation) =>
          total + (int.tryParse(donation['units']?.toString() ?? '0') ?? 0),
    );

    if (!mounted) return;

    setState(() {
      _completedDonations = completedList.length;
      _livesHelped = livesHelped;
      _isLoadingImpact = false;
    });
  } catch (error) {
    debugPrint('Could not load donation impact: $error');

    if (!mounted) return;

    setState(() {
      _isLoadingImpact = false;
    });
  }
}
Future<void> _refreshProfile() async {
  if (!mounted || _isLoadingProfile) return;

  try {
    final user = await ApiService.getProfile();

    if (!mounted) return;

    setState(() {
      _user = user;
      _profileError = null;
    });
  } catch (error) {
    debugPrint('Could not refresh profile: $error');
  }
}


@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _refreshProfile();
    _loadImpact();
  }
}


@override
void dispose() {
  _profileRefreshTimer?.cancel();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
        _profileError = null;
      });
    }

    try {
      final user = await ApiService.getProfile();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
        _profileError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // =========================================================
  // OPEN PROFILE
  // =========================================================

  Future<void> _navigateToProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your profile is not available yet.'),
        ),
      );
      return;
    }

    final updatedUser = await showDialog<UserProfile>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        backgroundColor: Colors.transparent,
        child: ProfileScreen(initialUser: _user!),
      ),
    );

    if (updatedUser != null && mounted) {
      setState(() {
        _user = updatedUser;
      });
    }
  }

  // =========================================================
  // DONOR APPLICATION FORM
  // =========================================================

  Future<void> _showDonorApplicationForm() async {
    final user = _user;

    if (user == null) return;

    String selectedBloodType =
        user.bloodType.isNotEmpty ? user.bloodType : 'O+';

    DateTime? dateOfBirth;

    final phoneController = TextEditingController(
      text: user.contact,
    );

    final addressController = TextEditingController(
      text: user.address,
    );

    bool submitting = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Become a Donor'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submit your details for admin review. '
                        'Your donor registration becomes active '
                        'only after approval.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBloodType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Blood type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'O+',
                          'O-',
                          'AB+',
                          'AB-',
                        ].map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: submitting
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
                      OutlinedButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                final now = DateTime.now();

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(
                                    now.year - 18,
                                    now.month,
                                    now.day,
                                  ),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  ),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    dateOfBirth = picked;
                                  });
                                }
                              },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          dateOfBirth == null
                              ? 'Date of birth (optional)'
                              : '${dateOfBirth!.year}-'
                                  '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
                                  '${dateOfBirth!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        enabled: !submitting,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            setDialogState(() {
                              submitting = true;
                            });

                            try {
                              final date = dateOfBirth == null
                                  ? null
                                  : '${dateOfBirth!.year}-'
                                      '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
                                      '${dateOfBirth!.day.toString().padLeft(2, '0')}';

                              await ApiService.submitDonorApplication(
                                bloodType: selectedBloodType,
                                dateOfBirth: date,
                                phone: phoneController.text.trim(),
                                address: addressController.text.trim(),
                              );

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);

                              if (!mounted) return;

                              ScaffoldMessenger.of(this.context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Application submitted! '
                                    'Please wait for admin review.',
                                  ),
                                ),
                              );

                              await _loadProfile();
                              _loadImpact();
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                  ),
                                ),
                              );
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  submitting = false;
                                });
                              }
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Application'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      phoneController.dispose();
      addressController.dispose();
    }
  }

  // =========================================================
  // DONOR APPLICATION STATUS
  // =========================================================

  Widget _buildDonorStatusCard() {
    final theme = Theme.of(context);
    final status = _user?.donorStatus ?? 'not_registered';

    final approved = status == 'approved';
    final pending = status == 'pending';
    final rejected = status == 'rejected';

    final IconData statusIcon = approved
        ? Icons.verified_rounded
        : pending
            ? Icons.hourglass_top_rounded
            : rejected
                ? Icons.info_outline_rounded
                : Icons.volunteer_activism_rounded;

    final String title = approved
        ? 'Approved Donor'
        : pending
            ? 'Application Pending'
            : rejected
                ? 'Application Rejected'
                : 'Become a Donor';

    final String description = approved
        ? 'Your donor registration is active. You can respond to blood requests.'
        : pending
            ? 'Your application is waiting for admin review.'
            : rejected
                ? 'Your application was rejected. You may submit a new application.'
                : 'Apply to become a registered donor. Admin approval is required.';

    final Color accent = approved
        ? AppColors.success
        : pending
            ? Colors.orange
            : rejected
                ? theme.colorScheme.error
                : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!approved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    pending ? null : _showDonorApplicationForm,
                icon: Icon(
                  rejected
                      ? Icons.refresh_rounded
                      : Icons.favorite_rounded,
                ),
                label: Text(
                  pending
                      ? 'Waiting for Review'
                      : rejected
                          ? 'Apply Again'
                          : 'Become a Donor',
                ),
              ),
            ),
          ],
          if (approved) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                icon: const Icon(Icons.water_drop_rounded),
                label: const Text('View Donation Opportunities'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // MAIN SCREEN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop_rounded),
            label: 'Donate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bloodtype_outlined),
            activeIcon: Icon(Icons.bloodtype_rounded),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Activity',
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Community Blood Donor'
              : _currentIndex == 1
                  ? 'Donate Blood'
                  : _currentIndex == 2
                      ? 'Request Blood'
                      : 'Your Activity',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (context, themeMode, child) {
              final isDark = themeMode == ThemeMode.dark;

              return IconButton(
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: () {
                  appThemeMode.value = isDark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                },
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                ),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        onProfileTap: _navigateToProfile,
      ),
      body: _currentIndex == 0
          ? _isLoadingProfile
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _profileError != null
                  ? _buildProfileError()
                  : _buildHomeContent()
          : _currentIndex == 1
              ? const Donate()
              : _currentIndex == 2
                  ? const BloodRequestScreen()
                  : const ActivityScreen(),
    );
  }

  // =========================================================
  // PROFILE ERROR
  // =========================================================

  Widget _buildProfileError() {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load your profile',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _profileError ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HOME CONTENT
  // =========================================================

  Widget _buildHomeContent() {
    final user = _user!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bloodCardTextColor = theme.colorScheme.onSurface;
    final bloodCardMutedColor =
        theme.textTheme.bodySmall?.color ??
            theme.colorScheme.onSurface;
    final bloodCardAccent = theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Hello, ${user.name}! 👋',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Your donation can help save up to 3 lives.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color
                ?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every donation brings hope closer to someone who needs it.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color
                ?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'What would you like to do?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.water_drop_rounded,
                title: 'Donate Blood',
                subtitle: 'Save up to 3 lives',
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bloodtype_rounded,
                title: 'Request Blood',
                subtitle: 'Find a donor',
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: bloodCardAccent.withValues(
                alpha: isDark ? 0.35 : 0.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: bloodCardAccent.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR BLOOD TYPE',
                style: TextStyle(
                  color: bloodCardTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.bloodType,
                style: TextStyle(
                  color: bloodCardAccent,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _buildDonorStatusCard(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 3;
                    });
                  },
                  icon: const Icon(Icons.event_note_rounded),
                  label: const Text('View donation activity'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your donation history and eligibility should be '
                'confirmed with your donation records.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: bloodCardMutedColor,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your impact',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
              _ImpactValue(
  value: _isLoadingImpact ? '...' : '$_completedDonations',
  label: 'Donations',
),
const SizedBox(width: 18),
_ImpactValue(
  value: _isLoadingImpact ? '...' : '$_livesHelped',
  label: 'Lives helped*',
),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Urgent blood requests',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bloodtype_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No urgent requests nearby',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'We’ll notify you when someone needs your '
                        'blood type.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming blood drives',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UpcomingBloodActivitiesScreen(),
                  ),
                );
              },
              child: const Text('See more'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HomeUpcomingBloodDriveCard(),
      ],
    );
  }
}

// =========================================================
// HOME UPCOMING BLOOD DRIVE
// =========================================================

class _HomeUpcomingBloodDriveCard extends StatefulWidget {
  const _HomeUpcomingBloodDriveCard();

  @override
  State<_HomeUpcomingBloodDriveCard> createState() =>
      _HomeUpcomingBloodDriveCardState();
}

class _HomeUpcomingBloodDriveCardState
    extends State<_HomeUpcomingBloodDriveCard> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsFuture = ApiService.getPublishedBloodDriveEvents();
  }

  Future<void> _refreshEvents() async {
    setState(_loadEvents);

    try {
      await _eventsFuture;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 36,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Could not load upcoming blood drives.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refreshEvents,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final eventData = snapshot.data ?? [];
        final events = <BloodDrive>[];

        for (final json in eventData) {
          try {
            final event = BloodDrive.fromJson(json);

            if (event.id > 0) {
              events.add(event);
            }
          } catch (_) {
            // Ignore malformed event data.
          }
        }

        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No upcoming blood drives',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Published upcoming events will appear here.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activity = events.first;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(
                      size: 48,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            activity.description.isNotEmpty
                                ? activity.description
                                : 'Give blood, give hope.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const _ActivityTag(
                      icon: Icons.event_available_rounded,
                      label: 'Published event',
                    ),
                    const SizedBox(width: 8),
                    _ActivityTag(
                      icon: Icons.people_alt_outlined,
                      label: activity.capacity > 0
                          ? '${activity.capacity} slots'
                          : 'Open event',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: activity.date.isNotEmpty
                      ? activity.date
                      : 'Date to be announced',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: activity.time.isNotEmpty
                      ? activity.time
                      : 'Time to be announced',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: activity.location.isNotEmpty
                      ? activity.location
                      : 'Location to be announced',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'RESERVE MY SLOT',
                    icon: Icons.event_available_rounded,
                    onTap: () {
                      BloodActivityDialog.show(context, activity);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// INFO ROW
// =========================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// QUICK ACTION CARD
// =========================================================

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        hoverColor: primary.withValues(alpha: 0.08),
        splashColor: primary.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark
                  ? theme.dividerColor.withValues(alpha: 0.8)
                  : theme.dividerColor,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(
                    alpha: isDark ? 0.18 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? theme.colorScheme.secondary
                      : primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: isDark
                    ? theme.colorScheme.secondary
                    : primary,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// IMPACT VALUE
// =========================================================

class _ImpactValue extends StatelessWidget {
  const _ImpactValue({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// =========================================================
// ACTIVITY TAG
// =========================================================

class _ActivityTag extends StatelessWidget {
  const _ActivityTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
