class CrewMember {
  final int id;
  final String name;
  final String? profilePath;
  final double popularity;
  final String department;

  CrewMember({
    required this.id,
    required this.name,
    required this.profilePath,
    required this.popularity,
    required this.department,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      popularity: (json['popularity'] ?? 0).toDouble(),
      department: json['known_for_department'] ?? '',
    );
  }
}
