class BloodDonor {
  final int? id;
  final String name;
  final String email;
  final String bloodType;
  final String contact;
  final String location;
  final int unitsNeeded;
  final String urgency;
  final DateTime requestedAt;
  final bool isAvailable;

  const BloodDonor({
    this.id,
    required this.name,
    required this.email,
    required this.bloodType,
    required this.contact,
    required this.location,
    required this.unitsNeeded,
    required this.urgency,
    required this.requestedAt,
    required this.isAvailable,
  });

  factory BloodDonor.fromJson(Map<String, dynamic> json) {
    final availability =
        (json['availability'] ?? 'available').toString().toLowerCase();

    return BloodDonor(
      id: int.tryParse('${json['id'] ?? ''}'),
      name: (json['name'] ?? 'Unknown Donor').toString(),
      email: (json['email'] ?? 'Not provided').toString(),
      bloodType: (json['blood_type'] ?? 'Unknown').toString(),
      contact: (json['contact'] ?? json['phone'] ?? 'Not provided').toString(),
      location: (json['location'] ?? 'Location not provided').toString(),
      unitsNeeded: 0,
      urgency: availability == 'available' ? 'Available' : availability,
      requestedAt: DateTime.now(),
      isAvailable: availability == 'available',
    );
  }
}