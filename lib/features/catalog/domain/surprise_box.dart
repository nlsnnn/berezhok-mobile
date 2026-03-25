class SurpriseBox {
  final String id;
  final String name;
  final String? description;
  final double originalPrice;
  final double discountPrice;
  final int quantityAvailable;
  final String pickupTimeStart;
  final String pickupTimeEnd;
  final String? imageUrl;

  const SurpriseBox({
    required this.id,
    required this.name,
    this.description,
    required this.originalPrice,
    required this.discountPrice,
    required this.quantityAvailable,
    required this.pickupTimeStart,
    required this.pickupTimeEnd,
    this.imageUrl,
  });

  int get discountPercent =>
      ((1 - discountPrice / originalPrice) * 100).round();

  String get pickupTimeFormatted => '$pickupTimeStart – $pickupTimeEnd';

  factory SurpriseBox.fromJson(Map<String, dynamic> json) {
    final pickupTime = json['pickup_time'] as Map<String, dynamic>?;
    return SurpriseBox(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num).toDouble(),
      quantityAvailable: (json['quantity_available'] as num).toInt(),
      pickupTimeStart: pickupTime != null
          ? pickupTime['start'] as String
          : json['pickup_time_start'] as String,
      pickupTimeEnd: pickupTime != null
          ? pickupTime['end'] as String
          : json['pickup_time_end'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'original_price': originalPrice,
        'discount_price': discountPrice,
        'quantity_available': quantityAvailable,
        'pickup_time_start': pickupTimeStart,
        'pickup_time_end': pickupTimeEnd,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  @override
  String toString() =>
      'SurpriseBox(id: $id, name: $name, discount: $discountPercent%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurpriseBox &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
