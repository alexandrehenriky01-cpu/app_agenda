import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  done,
  canceled,
}

enum PaymentMethod {
  pix,
  cash,
  card,
}

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

  static PaymentMethod? fromRaw(dynamic raw) {
    if (raw == null) return null;

    final value = raw.toString().trim().toLowerCase();

    switch (value) {
      case 'pix':
        return PaymentMethod.pix;
      case 'cash':
      case 'dinheiro':
        return PaymentMethod.cash;
      case 'card':
      case 'cartao':
      case 'cartão':
        return PaymentMethod.card;
      default:
        return null;
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

  AppointmentServiceItem copyWith({
    String? serviceId,
    String? nameSnapshot,
    int? durationMin,
    double? price,
  }) {
    return AppointmentServiceItem(
      serviceId: serviceId ?? this.serviceId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      durationMin: durationMin ?? this.durationMin,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'nameSnapshot': nameSnapshot,
      'durationMin': durationMin,
      'price': price,
    };
  }

  factory AppointmentServiceItem.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];

    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawDuration = map['durationMin'];
    final parsedDuration = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '') ?? 0;

    return AppointmentServiceItem(
      serviceId: (map['serviceId'] ?? '').toString(),
      nameSnapshot: (map['nameSnapshot'] ?? '').toString(),
      durationMin: parsedDuration,
      price: parsedPrice,
    );
  }

  @override
  List<Object?> get props => [
        serviceId,
        nameSnapshot,
        durationMin,
        price,
      ];
}

class Appointment extends Equatable {
  final String id;
  final String clientId;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final List<AppointmentServiceItem> services;
  final String? notes;
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

  double get totalPrice {
    return services.fold<double>(0, (acc, s) => acc + s.price);
  }

  int get totalMin {
    return services.fold<int>(0, (acc, s) => acc + s.durationMin);
  }

  Appointment copyWith({
    String? id,
    String? clientId,
    DateTime? startAt,
    DateTime? endAt,
    AppointmentStatus? status,
    List<AppointmentServiceItem>? services,
    String? notes,
    bool clearNotes = false,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    DateTime? paidAt,
    bool clearPaidAt = false,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      services: services ?? this.services,
      notes: clearNotes ? null : (notes ?? this.notes),
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    );
  }

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
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    final rawStatus = (map['status'] ?? 'pending').toString().trim();
    final status = AppointmentStatus.values.firstWhere(
      (e) => e.name == rawStatus,
      orElse: () => AppointmentStatus.pending,
    );

    final paymentMethod = PaymentMethodX.fromRaw(map['paymentMethod']);

    final rawPaidAt = map['paidAt'];
    final parsedPaidAt = rawPaidAt == null ? null : parseDate(rawPaidAt);

    final rawServices = map['services'] as List? ?? const [];
    final servicesList = rawServices
        .map((e) => AppointmentServiceItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return Appointment(
      id: id,
      clientId: (map['clientId'] ?? '').toString(),
      startAt: parseDate(map['startAt']),
      endAt: parseDate(map['endAt']),
      status: status,
      services: servicesList,
      notes: map['notes']?.toString(),
      paymentMethod: paymentMethod,
      paidAt: parsedPaidAt,
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