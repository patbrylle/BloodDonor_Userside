
class BloodRequest {
  final String id;
  final String name;
  final String email;
  final String contact;
  final String bloodType;
  final int units;
  final String hospital;
  final String location;
  final String urgency;
  final String status;
  final DateTime createdAt;

  const BloodRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.bloodType,
    required this.units,
    required this.hospital,
    required this.location,
    required this.urgency,
    required this.status,
    required this.createdAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['patient_name'] ?? 'Unknown').toString(),
      email: (json['email'] ?? '').toString(),
      contact: (json['contact'] ?? json['contact_number'] ?? '').toString(),
      bloodType: (json['blood_type'] ?? '').toString(),
      units: int.tryParse(
            (json['units'] ?? json['units_needed'] ?? 0).toString(),
          ) ??
          0,
      hospital: (json['hospital'] ?? '').toString(),
      location: (json['location'] ?? json['hospital'] ?? '').toString(),
      urgency: (json['urgency'] ?? 'Normal').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': contact,
      'blood_type': bloodType,
      'units': units,
      'hospital': hospital,
      'location': location,
      'urgency': urgency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
