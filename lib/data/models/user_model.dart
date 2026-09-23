enum UserRole { patient, caregiver, doctor }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String avatarUrl;
  final int age;
  final String bloodGroup;
  final double weight;
  final double height;
  final String medicalConditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String phone;
  final String? elderCode;
  final String? linkedElderCode;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone = '',
    this.elderCode,
    this.linkedElderCode,
    this.avatarUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    this.age = 0,
    this.bloodGroup = 'Not specified',
    this.weight = 0.0,
    this.height = 0.0,
    this.medicalConditions = 'None specified',
    this.emergencyContactName = 'Not provided',
    this.emergencyContactPhone = 'Not provided',
  });

  factory UserModel.defaultPatient() {
    return UserModel(
      id: 'da390507-f906-412d-b975-2616e05f1c0c',
      email: 'ah7546870@gmail.com',
      name: 'Aslam',
      role: UserRole.patient,
      phone: '8754814489',
      elderCode: '482810',
      age: 50,
      bloodGroup: 'B+',
      weight: 65.0,
      height: 170.0,
      medicalConditions: 'Mild Hypertension',
      emergencyContactName: 'Yoosuf',
      emergencyContactPhone: '9895843898',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      elderCode: json['elderCode'] as String? ?? json['elder_code'] as String?,
      linkedElderCode: json['linkedElderCode'] as String? ?? json['linked_elder_code'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String? ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      age: (json['age'] as num?)?.toInt() ?? 0,
      bloodGroup: json['bloodGroup'] as String? ?? json['blood_group'] as String? ?? 'Not specified',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      medicalConditions: json['medicalConditions'] as String? ?? json['medical_conditions'] as String? ?? 'None specified',
      emergencyContactName: json['emergencyContactName'] as String? ?? json['emergency_contact_name'] as String? ?? 'Not provided',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? json['emergency_contact_phone'] as String? ?? 'Not provided',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'elderCode': elderCode,
      'linkedElderCode': linkedElderCode,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'age': age,
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'medicalConditions': medicalConditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    int? age,
    String? bloodGroup,
    double? weight,
    double? height,
    String? medicalConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? phone,
    String? elderCode,
    String? linkedElderCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      phone: phone ?? this.phone,
      elderCode: elderCode ?? this.elderCode,
      linkedElderCode: linkedElderCode ?? this.linkedElderCode,
    );
  }
}
