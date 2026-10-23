class UserProfileModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int dailyGoalMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.dailyGoalMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfileModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? dailyGoalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: (map['displayName'] as String?) ?? 'Student',
      photoUrl: map['photoUrl'] as String?,
      dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
