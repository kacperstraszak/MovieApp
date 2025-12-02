class GroupMember {
  const GroupMember({
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.isAdmin = false,
    this.joinedAt,
  });

  final String userId;
  final String username;
  final String imageUrl;
  final bool isAdmin;
  final DateTime? joinedAt;

  factory GroupMember.fromPresence(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      imageUrl: json['image_url'] as String,
      isAdmin: json['is_admin'] as bool,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toPresencePayload() {
    return {
      'user_id': userId,
      'username': username,
      'image_url': imageUrl,
      'is_admin': isAdmin,
      'joined_at': DateTime.now().toIso8601String(),
    };
  }
}
