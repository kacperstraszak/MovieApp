class GroupMember {
  final String userId;
  final String username;
  final String imageUrl;
  final bool isAdmin;
  final DateTime? joinedAt;

  GroupMember({
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.isAdmin = false,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json, String adminId) {
    final profile = json['profiles'] as Map<String, dynamic>;
    
    return GroupMember(
      userId: json['user_id'] as String,
      username: profile['username'] as String,
      imageUrl: profile['image_url'] as String,
      isAdmin: json['user_id'] == adminId,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }
}