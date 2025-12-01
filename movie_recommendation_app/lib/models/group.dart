class Group {
  final String id;
  final String code;
  final String adminId;
  final DateTime createdAt;
  final bool isActive;

  Group({
    required this.id,
    required this.code,
    required this.adminId,
    required this.createdAt,
    required this.isActive,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      code: json['code'] as String,
      adminId: json['admin_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}