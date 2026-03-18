import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/transaction.dart';

class FinanceRepository {
  final FirebaseFirestore _db;
  FinanceRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('transactions');

  Stream<List<FinanceTransaction>> watchRange(DateTime from, DateTime to) {
    return _col
        .where('occurredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from.toUtc()))
        .where('occurredAt', isLessThan: Timestamp.fromDate(to.toUtc()))
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FinanceTransaction.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addManual({
    required TransactionType type,
    required double amount,
    required DateTime occurredAt,
    PaymentMethod? method,
    String? description,
  }) async {
    final ref = _col.doc();
    final data = FinanceTransaction(
      id: ref.id,
      type: type,
      amount: amount,
      method: method,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      occurredAt: occurredAt,
      createdAt: DateTime.now(),
    ).toMap();

    await ref.set({
      ...data,
      // melhor que DateTime.now() para consistência
      'createdAt': FieldValue.serverTimestamp(),
      'occurredAt': Timestamp.fromDate(occurredAt.toUtc()),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(firestoreProvider));
});