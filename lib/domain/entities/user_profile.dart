class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoURL;
  final String? gender; // 'Masculino', 'Femenino', null para no especificado
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool completedInitialQuestionnaire;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoURL,
    this.gender,
    required this.createdAt,
    required this.lastLoginAt,
    this.completedInitialQuestionnaire = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'completedInitialQuestionnaire': completedInitialQuestionnaire,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      displayName:
          json['displayName'] ?? 'Usuario', // Valor predeterminado si es nulo
      email: json['email'],
      photoURL: json['photoURL'],
      gender: json['gender'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(), // Valor predeterminado si es nulo
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : DateTime.now(), // Valor predeterminado si es nulo
      completedInitialQuestionnaire:
          json['completedInitialQuestionnaire'] ?? false,
    );
  }

  // Método para verificar si faltan datos importantes
  bool get hasIncompleteProfile {
    return displayName.isEmpty ||
        displayName == 'Usuario' ||
        email == null ||
        email!.isEmpty;
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    String? gender,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? completedInitialQuestionnaire,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      completedInitialQuestionnaire:
          completedInitialQuestionnaire ?? this.completedInitialQuestionnaire,
    );
  }
}
