class Group {
  final String id;
  final String code;
  final String adminId;
  final bool isActive;
  final String status;

  Group({
    required this.id,
    required this.code,
    required this.adminId,
    required this.isActive,
    this.status = 'lobby',
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      code: json['code'] as String,
      adminId: json['admin_id'] as String,
      isActive: json['is_active'] as bool,
      status: json['status'] ?? 'lobby',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'admin_id': adminId,
      'is_active': isActive,
      'lobby': status,
    };
  }
}
