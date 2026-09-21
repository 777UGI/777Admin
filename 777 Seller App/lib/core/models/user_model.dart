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
      id: (json["id"] ?? json["_id"])?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      phone: json["phone"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      role: json["role"]?.toString() ?? "seller",
      kycStatus: json["kycStatus"]?.toString() ?? "none",
      referredByAgentId: json["referredByAgentId"]?.toString(),
      createdAt: json["createdAt"]?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "phone": phone,
      "email": email,
      "role": role,
      "kycStatus": kycStatus,
      "referredByAgentId": referredByAgentId,
      "createdAt": createdAt,
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
