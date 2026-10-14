
class UserProfile {
  final String name;
  final String email;
  final String contact;
  final String address;
  final String bloodType;

  // Donor application information from Laravel
  final String donorStatus;
  final bool isDonor;

  UserProfile({
    required this.name,
    required this.email,
    required this.contact,
    required this.address,
    required this.bloodType,
    this.donorStatus = 'not_registered',
    this.isDonor = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contact: json['contact_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',

      donorStatus:
          json['donor_status']?.toString() ?? 'not_registered',
      isDonor: json['is_donor'] == true,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? contact,
    String? address,
    String? bloodType,
    String? donorStatus,
    bool? isDonor,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      donorStatus: donorStatus ?? this.donorStatus,
      isDonor: isDonor ?? this.isDonor,
    );
  }
}
