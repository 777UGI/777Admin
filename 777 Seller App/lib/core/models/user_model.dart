class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String kycStatus; // none, pending, verified, rejected
  final String? referredByAgentId;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.kycStatus,
    this.referredByAgentId,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      kycStatus: json['kycStatus'] as String? ?? 'none',
      referredByAgentId: json['referredByAgentId'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'kycStatus': kycStatus,
      'referredByAgentId': referredByAgentId,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? kycStatus,
    String? referredByAgentId,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      referredByAgentId: referredByAgentId ?? this.referredByAgentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
