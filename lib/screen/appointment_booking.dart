import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState
    extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _centers = [];
  String? _selectedCenter;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoadingCenters = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    if (mounted) {
      setState(() {
        _isLoadingCenters = true;
        _errorMessage = null;
      });
    }

    try {
      final centers = await ApiService.getOpenDonationCenters();

      if (!mounted) return;

      setState(() {
        _centers = centers;

        if (_selectedCenter != null &&
            !centers.any(
              (center) =>
                  center['name']?.toString() == _selectedCenter,
            )) {
          _selectedCenter = null;
        }

        _isLoadingCenters = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoadingCenters = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Choose appointment date',
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Choose appointment time',
    );

    if (time != null && mounted) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _displayDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCenter == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a center, date, and time.',
          ),
        ),
      );
      return;
    }

    final selectedDate = DateUtils.dateOnly(_selectedDate!);
    final today = DateUtils.dateOnly(DateTime.now());

    if (selectedDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select today or a future date.'),
        ),
      );
      return;
    }

    if (selectedDate == today) {
      final now = TimeOfDay.now();
      final selectedMinutes =
          _selectedTime!.hour * 60 + _selectedTime!.minute;
      final currentMinutes = now.hour * 60 + now.minute;

      if (selectedMinutes <= currentMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a future time.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.createAppointment(
        center: _selectedCenter!,
        appointmentDate: _formatDate(_selectedDate!),
        appointmentTime: _formatTime(_selectedTime!),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      final message = result['message']?.toString() ??
          'Your appointment request was submitted successfully.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedCenter = null;
        _selectedDate = null;
        _selectedTime = null;
        _notesController.clear();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoadingCenters
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadCenters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _centers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No open donation centers are available.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _loadCenters,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 52,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Schedule Your Appointment',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose an open donation center and '
                                'your preferred date and time.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 28),

                              // Donation center
                              Text(
                                'Donation Center',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
initialValue: _selectedCenter,                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.local_hospital_outlined,
                                  ),
                                  labelText: 'Select a center',
                                ),
                                items: _centers
                                    .where(
                                      (center) =>
                                          center['name'] != null,
                                    )
                                    .map((center) {
                                  final name =
                                      center['name'].toString();

                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isSubmitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedCenter = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please select a center.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Appointment date
                              Text(
                                'Appointment Date',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _isSubmitting ? null : _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.calendar_today_rounded,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Choose a date'
                                        : _displayDate(_selectedDate!),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Appointment time
                              Text(
                                'Appointment Time',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _isSubmitting ? null : _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.access_time_rounded,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedTime == null
                                        ? 'Choose a time'
                                        : _selectedTime!.format(context),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Optional notes
                              Text(
                                'Notes (Optional)',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _notesController,
                                enabled: !_isSubmitting,
                                maxLines: 3,
                                maxLength: 500,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Add any information for the center',
                                  alignLabelWithHint: true,
                                ),
                              ),

                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitAppointment,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.event_available_rounded,
                                        ),
                                  label: Text(
                                    _isSubmitting
                                        ? 'Submitting...'
                                        : 'Book Appointment',
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Your appointment will be submitted '
                                'for confirmation. Please wait for '
                                'the center to review your request.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}