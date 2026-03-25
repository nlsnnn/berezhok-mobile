class User {
  final String id;
  final String phone;
  final String name;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.phone,
    this.name = '',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        phone: json['phone'] as String,
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

  User copyWith({String? phone, String? name}) => User(
        id: id,
        phone: phone ?? this.phone,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  @override
  String toString() => 'User(id: $id, phone: $phone, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
