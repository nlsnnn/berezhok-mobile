enum OrderStatus {
  pending,
  paid,
  confirmed,
  pickedUp,
  completed,
  cancelled,
  refunded,
  disputed,
}

class Order {
  final String id;
  final OrderStatus status;
  final String pickupCode;
  final String? qrCodeUrl;
  final double amount;
  final OrderBox box;
  final OrderLocation location;
  final DateTime pickupTimeStart;
  final DateTime pickupTimeEnd;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final bool hasReview;

  const Order({
    required this.id,
    required this.status,
    required this.pickupCode,
    this.qrCodeUrl,
    required this.amount,
    required this.box,
    required this.location,
    required this.pickupTimeStart,
    required this.pickupTimeEnd,
    required this.createdAt,
    this.confirmedAt,
    this.hasReview = false,
  });

  bool get isActive =>
      status == OrderStatus.paid ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.pickedUp;

  bool get canChat =>
      status == OrderStatus.confirmed || status == OrderStatus.pickedUp;

  bool get canDispute => status == OrderStatus.pickedUp;

  bool get canReview => status == OrderStatus.completed && !hasReview;

  String get statusKey => switch (status) {
    OrderStatus.pickedUp => 'picked_up',
    _ => status.name,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final pickupTime = json['pickup_time'] as Map<String, dynamic>?;

    return Order(
      id: json['id'] as String,
      status: _parseStatus(json['status'] as String),
      pickupCode: json['pickup_code'] as String,
      qrCodeUrl: json['qr_code_url'] as String?,
      amount: (json['amount'] as num).toDouble(),
      box: OrderBox.fromJson(json['box'] as Map<String, dynamic>),
      location: OrderLocation.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      pickupTimeStart: pickupTime != null
          ? DateTime.parse(pickupTime['start'] as String)
          : DateTime.parse(json['pickup_time_start'] as String),
      pickupTimeEnd: pickupTime != null
          ? DateTime.parse(pickupTime['end'] as String)
          : DateTime.parse(json['pickup_time_end'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      hasReview: json['has_review'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': statusKey,
    'pickup_code': pickupCode,
    if (qrCodeUrl != null) 'qr_code_url': qrCodeUrl,
    'amount': amount,
    'box': box.toJson(),
    'location': location.toJson(),
    'pickup_time_start': pickupTimeStart.toIso8601String(),
    'pickup_time_end': pickupTimeEnd.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
    'has_review': hasReview,
  };

  static OrderStatus _parseStatus(String value) => switch (value) {
    'pending' || 'pending_payment' => OrderStatus.pending,
    'paid' => OrderStatus.paid,
    'confirmed' => OrderStatus.confirmed,
    'picked_up' => OrderStatus.pickedUp,
    'completed' => OrderStatus.completed,
    'cancelled' => OrderStatus.cancelled,
    'refunded' => OrderStatus.refunded,
    'disputed' => OrderStatus.disputed,
    _ => OrderStatus.pending,
  };

  @override
  String toString() => 'Order(id: $id, status: $statusKey)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class OrderBox {
  final String name;
  final String? imageUrl;

  const OrderBox({required this.name, this.imageUrl});

  factory OrderBox.fromJson(Map<String, dynamic> json) => OrderBox(
    name: json['name'] as String,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (imageUrl != null) 'image_url': imageUrl,
  };

  @override
  String toString() => 'OrderBox(name: $name)';
}

class OrderLocation {
  final String name;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;

  const OrderLocation({
    required this.name,
    required this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
  });

  factory OrderLocation.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;

    return OrderLocation(
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      latitude: coordinates != null
          ? (coordinates['lat'] as num).toDouble()
          : (json['latitude'] as num).toDouble(),
      longitude: coordinates != null
          ? (coordinates['lng'] as num).toDouble()
          : (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    if (phone != null) 'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  String toString() => 'OrderLocation(name: $name, address: $address)';
}
