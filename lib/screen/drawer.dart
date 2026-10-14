import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import '../widget/app_logo.dart';
import 'donation_centers.dart';
import 'appointment_booking.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const AppDrawer({super.key, this.onProfileTap});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor:
          Theme.of(context).drawerTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  const AppLogo(size: 36, iconSize: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'COMMUNITY\nBLOOD DONOR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => _go(context, const HomeScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.water_drop_rounded,
                    label: 'Donate Blood',
                    onTap: () =>
                        _go(context, const HomeScreen(initialIndex: 1)),
                  ),
                  _DrawerItem(
                    icon: Icons.bloodtype_rounded,
                    label: 'Request Blood',
                    onTap: () =>
                        _go(context, const HomeScreen(initialIndex: 2)),
                  ),
                  _DrawerItem(
  icon: Icons.location_on_rounded,
  label: 'Donation Centers',
  onTap: () => _go(
    context,
    const DonationCentersScreen(),
  ),
),
_DrawerItem(
  icon: Icons.calendar_month_rounded,
  label: 'Book Appointment',
  onTap: () => _go(
    context,
    const AppointmentBookingScreen(),
  ),
),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Activity',
                    onTap: () =>
                        _go(context, const HomeScreen(initialIndex: 3)),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    danger: true,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? theme.colorScheme.error
        : theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final iconColor = danger
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
