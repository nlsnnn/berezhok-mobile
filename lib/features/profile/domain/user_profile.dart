/// User profile matching API contract: GET /customer/profile
/// API returns: {id, phone, name, created_at}
class UserProfile {
  final String id;
  final String phone;
  final String name;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.phone,
    this.name = '',
    this.createdAt,
  });

  String get displayName => name.isNotEmpty ? name : 'Пользователь';

  String get initials {
    if (name.isEmpty) return 'П';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  UserProfile copyWith({String? name}) => UserProfile(
        id: id,
        phone: phone,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  @override
  String toString() => 'UserProfile(id: $id, phone: $phone, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
