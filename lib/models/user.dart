/// Driver user model (stored locally / from mock).
class User {
  final String id;
  final String phone;
  final String? fullName;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.phone,
    this.fullName,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        phone: json['phone'] as String,
        fullName: json['fullName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
