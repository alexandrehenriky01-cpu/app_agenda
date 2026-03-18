import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FinanceEntryType { income, expense }

class FinanceEntry extends Equatable {
  final String id;
  final FinanceEntryType type;
  final double amount;
  final DateTime date;
  final String description;

  final String? appointmentId;
  final String? clientId;

  final DateTime createdAt;

  const FinanceEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.createdAt,
    this.appointmentId,
    this.clientId,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,
        'date': Timestamp.fromDate(date.toUtc()),
        'description': description,
        'appointmentId': appointmentId,
        'clientId': clientId,
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      };

  factory FinanceEntry.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? 'income') as String;
    final type = FinanceEntryType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FinanceEntryType.income,
    );

    final dateRaw = map['date'];
    final createdRaw = map['createdAt'];

    return FinanceEntry(
      id: id,
      type: type,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: (dateRaw is Timestamp) ? dateRaw.toDate() : DateTime.now(),
      description: (map['description'] ?? '') as String,
      appointmentId: map['appointmentId'] as String?,
      clientId: map['clientId'] as String?,
      createdAt: (createdRaw is Timestamp) ? createdRaw.toDate() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, type, amount, date, description, appointmentId, clientId, createdAt];
}