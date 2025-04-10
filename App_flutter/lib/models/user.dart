class User {
  final dynamic id;  // int 또는 String (소셜 로그인용)
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? loginProvider;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.loginProvider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      loginProvider: json['loginProvider'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'loginProvider': loginProvider,
    };
  }
} 