class BloodDrive {
  final int id;
  final String name;
  final String description;
  final String date;
  final String time;
  final String location;
  final String organizer;
  final int capacity;

  const BloodDrive({
    this.id = 0,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.organizer = '',
    this.capacity = 0,
  });

  factory BloodDrive.fromJson(Map<String, dynamic> json) {
    final eventDate = _formatDate(
      json['event_date']?.toString() ?? '',
    );

    final startTime = _formatTime(
      json['start_time']?.toString() ?? '',
    );

    final endTime = _formatTime(
      json['end_time']?.toString() ?? '',
    );

    return BloodDrive(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['title']?.toString() ?? 'Blood Drive',
      description: json['description']?.toString() ?? '',
      date: eventDate,
      time: startTime.isEmpty
          ? endTime
          : endTime.isEmpty
              ? startTime
              : '$startTime – $endTime',
      location: json['venue']?.toString() ?? '',
      organizer: json['organizer']?.toString() ?? '',
      capacity: int.tryParse(
            json['capacity']?.toString() ?? '',
          ) ??
          0,
    );
  }

  static String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

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

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  static String _formatTime(String value) {
    if (value.isEmpty) {
      return '';
    }

    final parts = value.split(':');

    if (parts.length < 2) {
      return value;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null || hour < 0 || hour > 23) {
      return value;
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }
}
