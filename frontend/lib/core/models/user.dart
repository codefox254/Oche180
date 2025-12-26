class User {
  final int id;
  final String email;
  final String? publicUsername;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String skillLevel;
  final UserProfile? profile;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.publicUsername,
    this.firstName,
    this.lastName,
    this.avatar,
    required this.skillLevel,
    this.profile,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      publicUsername: json['public_username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatar: json['avatar'] as String?,
      skillLevel: json['skill_level'] as String? ?? 'BEGINNER',
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'public_username': publicUsername,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'skill_level': skillLevel,
      'profile': profile?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return lastName != null && lastName!.isNotEmpty ? '$firstName $lastName' : firstName!;
    }
    return publicUsername ?? email.split('@').first;
  }
}

class UserProfile {
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final int totalTrainingSessions;
  final int totalGamesPlayed;

  UserProfile({
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
    required this.totalTrainingSessions,
    required this.totalGamesPlayed,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.parse(json['last_login_date'] as String)
          : null,
      totalTrainingSessions: json['total_training_sessions'] as int? ?? 0,
      totalGamesPlayed: json['total_games_played'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_xp': totalXp,
      'level': level,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_login_date': lastLoginDate?.toIso8601String(),
      'total_training_sessions': totalTrainingSessions,
      'total_games_played': totalGamesPlayed,
    };
  }
}
