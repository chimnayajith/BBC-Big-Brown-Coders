class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? caregiverPhone;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.caregiverPhone,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'elderly', // Default to elderly when coming from elderly list
      caregiverPhone: json['emergency_contact']?.toString() ?? json['caregiver_phone']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'caregiver_phone': caregiverPhone,
    };
  }
  
  // Case-insensitive role checks
  bool isCaregiver() => role.toLowerCase() == 'caregiver';
  bool isElderly() => role.toLowerCase() == 'elderly';
}