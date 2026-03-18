import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get label => this == TransactionType.income ? 'Entrada' : 'Saída';
}

class FinanceTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;

  /// pix/dinheiro/cartao (string)
  final String? method;

  final String? description;
  final String? appointmentId;
  final String? clientId;

  /// data do evento financeiro (sempre preenchida)
  final DateTime occurredAt;

  /// auditoria
  final DateTime? createdAt;

  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.method,
    this.description,
    this.appointmentId,
    this.clientId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name, // income | expense
      'amount': amount,

      // ✅ padrão novo
      'paymentMethod': method,

      // ✅ (opcional) compat com legado
      'method': method,

      'description': description,
      'appointmentId': appointmentId,
      'clientId': clientId,

      'occurredAt': Timestamp.fromDate(occurredAt.toUtc()),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!.toUtc()),
    };
  }

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? 'income').toString();
    final type = TransactionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TransactionType.income,
    );

    double parseAmount(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      final s = v?.toString();
      return DateTime.tryParse(s ?? '') ?? DateTime.now();
    }

    final occurredAt = parseDate(map['occurredAt']);
    final createdAt =
        (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : null;

    // ✅ pega o método do campo novo (paymentMethod) ou do legado (method)
    final rawMethod = map['paymentMethod'] ?? map['method'];

    return FinanceTransaction(
      id: id,
      type: type,
      amount: parseAmount(map['amount']),
      method: rawMethod?.toString(),
      description: map['description']?.toString(),
      appointmentId: map['appointmentId']?.toString(),
      clientId: map['clientId']?.toString(),
      occurredAt: occurredAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        method,
        description,
        appointmentId,
        clientId,
        occurredAt,
        createdAt,
      ];
}