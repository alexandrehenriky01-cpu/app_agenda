import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }
enum PaymentMethod { pix, dinheiro, cartao }

class FinanceTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;

  /// pix | dinheiro | cartao
  final PaymentMethod? method;

  final String? description;
  final String? appointmentId;
  final String? clientId;

  /// Quando ocorreu (Timestamp no Firestore)
  final DateTime? occurredAt;

  /// Quando foi criado (Timestamp no Firestore)
  final DateTime? createdAt;

  /// (Opcional) quando foi pago (se você gravar)
  final DateTime? paidAt;

  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.method,
    this.description,
    this.appointmentId,
    this.clientId,
    this.occurredAt,
    this.createdAt,
    this.paidAt,
  });

  /// Data efetiva para ordenação/exibição (fallback para dados antigos)
  DateTime? get effectiveAt => occurredAt ?? paidAt ?? createdAt;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,

        // ✅ padrão
        'paymentMethod': method?.name,

        // (opcional) compat com legado - use apenas se você tiver docs antigos lendo "method"
        // 'method': method?.name,

        'description': description,
        'appointmentId': appointmentId,
        'clientId': clientId,

        'occurredAt':
            occurredAt == null ? null : Timestamp.fromDate(occurredAt!.toUtc()),
        'createdAt':
            createdAt == null ? null : Timestamp.fromDate(createdAt!.toUtc()),
        'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!.toUtc()),
      };

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    double parseAmount(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    DateTime? parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate(); // não força utc aqui
      if (v is DateTime) return v;
      return null;
    }

    TransactionType parseType(dynamic v) {
      final s = (v ?? TransactionType.income.name).toString();
      return TransactionType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => TransactionType.income,
      );
    }

    // ✅ parse robusto para paymentMethod/method (string, enum string, índice, map, etc.)
    PaymentMethod? parseMethod(dynamic v) {
      if (v == null) return null;

      // Se vier como índice (0,1,2)
      if (v is int) {
        if (v >= 0 && v < PaymentMethod.values.length) {
          return PaymentMethod.values[v];
        }
      }

      // Se vier como map {name: 'dinheiro'} ou {value: 'dinheiro'}
      if (v is Map) {
        final inner =
            v['name'] ?? v['value'] ?? v['method'] ?? v['paymentMethod'];
        return parseMethod(inner);
      }

      var s = v.toString().trim();

      // Se vier "PaymentMethod.dinheiro"
      if (s.contains('.')) s = s.split('.').last;

      s = s.toLowerCase();

      // Normalizações comuns
      switch (s) {
        case 'pix':
        case 'qr':
        case 'qrcode':
          return PaymentMethod.pix;

        case 'dinheiro':
        case 'cash':
        case 'money':
          return PaymentMethod.dinheiro;

        case 'cartao':
        case 'cartão':
        case 'card':
        case 'credito':
        case 'crédito':
        case 'debito':
        case 'débito':
          return PaymentMethod.cartao;
      }

      // fallback: tenta bater com o enum pelo name
      for (final e in PaymentMethod.values) {
        if (e.name == s) return e;
      }

      return null;
    }

    final desc = map['description']?.toString().trim();
    final description = (desc == null || desc.isEmpty) ? null : desc;

    // ✅ compat: paymentMethod (novo) ou method (legado) + variações
    final rawMethod =
        map['paymentMethod'] ?? map['method'] ?? map['payment_method'];

    // ✅ occurredAt (padrão), ou fallback para paidAt/createdAt se dados antigos
    final createdAt = parseTs(map['createdAt']);
    final paidAt = parseTs(map['paidAt']);
    final occurredAt = parseTs(map['occurredAt']) ?? paidAt ?? createdAt;

    return FinanceTransaction(
      id: id,
      type: parseType(map['type']),
      amount: parseAmount(map['amount']),
      method: parseMethod(rawMethod),
      description: description,
      appointmentId: map['appointmentId']?.toString(),
      clientId: map['clientId']?.toString(),
      occurredAt: occurredAt,
      createdAt: createdAt,
      paidAt: paidAt,
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
        paidAt,
      ];
}