class UserProfile {
  UserProfile({
    required this.username,
    required this.imageUrl,
  });

  final String username;
  final String imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      imageUrl: json['image_url'],
    );
  }
}
