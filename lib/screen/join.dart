import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../model/blood_drive.dart';
import '../services/api_service.dart';
import '../widget/gradient_button.dart';
import '../widget/app_logo.dart';

class BloodActivityDialog {
  static void show(BuildContext context, BloodDrive activity) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BloodActivityDialogContent(
        activity: activity,
      ),
    );
  }
}

class _BloodActivityDialogContent extends StatefulWidget {
  const _BloodActivityDialogContent({
    required this.activity,
  });

  final BloodDrive activity;

  @override
  State<_BloodActivityDialogContent> createState() =>
      _BloodActivityDialogContentState();
}

class _BloodActivityDialogContentState
    extends State<_BloodActivityDialogContent> {
  bool _isSubmitting = false;

  Future<void> _joinActivity() async {
    if (_isSubmitting) return;

    if (widget.activity.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid blood drive event. Please try again.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ApiService.registerForBloodDriveEvent(
        eventId: widget.activity.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Registration submitted successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogo(size: 52, iconSize: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Blood Donation Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                activity.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                activity.description.isNotEmpty
                    ? activity.description
                    : 'Give blood, give hope.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: activity.date.isNotEmpty
                          ? activity.date
                          : 'Date not available',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.access_time_outlined,
                      label: 'Time',
                      value: activity.time.isNotEmpty
                          ? activity.time
                          : 'Time not available',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: activity.location.isNotEmpty
                          ? activity.location
                          : 'Venue not available',
                    ),
                    if (activity.organizer.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Organizer',
                        value: activity.organizer,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Would you like to join this blood donation activity?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: _isSubmitting
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : GradientButton(
                              label: 'JOIN NOW',
                              onTap: _joinActivity,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryLight,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
