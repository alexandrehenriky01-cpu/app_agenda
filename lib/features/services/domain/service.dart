import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String name;
  final int durationMin;
  final double price;
  final bool isActive;

  const Service({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.price,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'durationMin': durationMin,
        'price': price,
        'isActive': isActive,
      };

  factory Service.fromMap(String id, Map<String, dynamic> map) {
    return Service(
      id: id,
      name: map['name'] ?? '',
      durationMin: map['durationMin'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, durationMin, price, isActive];
}