class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final DateTime lastLogin;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    required this.lastLogin,
  });

  // Convert User to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
    };
  }

  // Create User from Map (database result)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
      lastLogin: DateTime.parse(map['last_login']),
    );
  }

  // Copy with method
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Hide password for display
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
