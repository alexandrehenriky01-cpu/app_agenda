import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, done, canceled }

/// Formas de pagamento
enum PaymentMethod { pix, cash, card }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.card:
        return 'Cartão';
    }
  }
}

class AppointmentServiceItem extends Equatable {
  final String serviceId;
  final String nameSnapshot;
  final int durationMin;
  final double price;

  const AppointmentServiceItem({
    required this.serviceId,
    required this.nameSnapshot,
    required this.durationMin,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'nameSnapshot': nameSnapshot,
        'durationMin': durationMin,
        'price': price,
      };

  factory AppointmentServiceItem.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    final price = (rawPrice is int)
        ? rawPrice.toDouble()
        : (rawPrice is double)
            ? rawPrice
            : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    return AppointmentServiceItem(
      serviceId: (map['serviceId'] ?? '') as String,
      nameSnapshot: (map['nameSnapshot'] ?? '') as String,
      durationMin: (map['durationMin'] ?? 0) as int,
      price: price,
    );
  }

  @override
  List<Object?> get props => [serviceId, nameSnapshot, durationMin, price];
}

class Appointment extends Equatable {
  final String id;
  final String clientId;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final List<AppointmentServiceItem> services;
  final String? notes;

  /// NOVO
  final PaymentMethod? paymentMethod;
  final DateTime? paidAt;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.services,
    this.notes,
    this.paymentMethod,
    this.paidAt,
  });

  double get totalPrice => services.fold<double>(0, (acc, s) => acc + s.price);
  int get totalMin => services.fold<int>(0, (acc, s) => acc + s.durationMin);

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'startAt': Timestamp.fromDate(startAt.toUtc()),
      'endAt': Timestamp.fromDate(endAt.toUtc()),
      'status': status.name,
      'services': services.map((s) => s.toMap()).toList(),
      'notes': notes,
      'paymentMethod': paymentMethod?.name,
      'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!.toUtc()),
    };
  }

  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    final statusStr = (map['status'] ?? 'pending').toString();
    final status = AppointmentStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AppointmentStatus.pending,
    );

    final pmStr = map['paymentMethod']?.toString();
    final paymentMethod = (pmStr == null)
        ? null
        : PaymentMethod.values.firstWhere(
            (e) => e.name == pmStr,
            orElse: () => PaymentMethod.pix,
          );

    final paidAtRaw = map['paidAt'];
    final paidAt = (paidAtRaw is Timestamp) ? paidAtRaw.toDate() : null;

    final servicesList = (map['services'] as List? ?? const [])
        .map((e) => AppointmentServiceItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return Appointment(
      id: id,
      clientId: (map['clientId'] ?? '') as String,
      startAt: parseDate(map['startAt']),
      endAt: parseDate(map['endAt']),
      status: status,
      services: servicesList,
      notes: map['notes'] as String?,
      paymentMethod: paymentMethod,
      paidAt: paidAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        startAt,
        endAt,
        status,
        services,
        notes,
        paymentMethod,
        paidAt,
      ];
}