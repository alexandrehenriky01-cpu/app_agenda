import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  final FirebaseFirestore _db;
  TransactionRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('transactions');

  Stream<List<FinanceTransaction>> watchIncomeRange(DateTime from, DateTime to) {
    final fromUtc = from.toUtc();
    final toUtc = to.toUtc();

    // 1) Padrão novo: occurredAt
    final sOccurred = _col
        .where('type', isEqualTo: 'income')
        .where('occurredAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromUtc))
        .where('occurredAt', isLessThan: Timestamp.fromDate(toUtc))
        .orderBy('occurredAt', descending: true)
        .snapshots();

    // 2) Fallback legado: paidAt (caso tenha docs antigos)
    final sPaid = _col
        .where('type', isEqualTo: 'income')
        .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromUtc))
        .where('paidAt', isLessThan: Timestamp.fromDate(toUtc))
        .orderBy('paidAt', descending: true)
        .snapshots();

    // 3) Fallback legado: createdAt (último recurso)
    final sCreated = _col
        .where('type', isEqualTo: 'income')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromUtc))
        .where('createdAt', isLessThan: Timestamp.fromDate(toUtc))
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Merge manual das 3 streams (sem duplicar)
    return _merge3(sOccurred, sPaid, sCreated).map((allDocs) {
      final byId = <String, FinanceTransaction>{};

      for (final d in allDocs) {
        byId[d.id] = FinanceTransaction.fromMap(d.id, d.data());
      }

      final list = byId.values.toList();

      // Ordena pela effectiveAt (occurredAt -> paidAt -> createdAt)
      list.sort((a, b) {
        final ad = a.effectiveAt?.millisecondsSinceEpoch ?? 0;
        final bd = b.effectiveAt?.millisecondsSinceEpoch ?? 0;
        return bd.compareTo(ad);
      });

      return list;
    });
  }

  /// Junta 3 streams de QuerySnapshot em uma stream de List<QueryDocumentSnapshot)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _merge3(
    Stream<QuerySnapshot<Map<String, dynamic>>> a,
    Stream<QuerySnapshot<Map<String, dynamic>>> b,
    Stream<QuerySnapshot<Map<String, dynamic>>> c,
  ) async* {
    QuerySnapshot<Map<String, dynamic>>? la;
    QuerySnapshot<Map<String, dynamic>>? lb;
    QuerySnapshot<Map<String, dynamic>>? lc;

    final sa = a.listen((v) => la = v);
    final sb = b.listen((v) => lb = v);
    final sc = c.listen((v) => lc = v);

    try {
      // Espera a primeira emissão de cada
      await a.first.then((v) => la = v);
      await b.first.then((v) => lb = v);
      await c.first.then((v) => lc = v);

      // Emite a primeira combinação
      yield [
        ...?la?.docs,
        ...?lb?.docs,
        ...?lc?.docs,
      ];

      // Emite sempre que qualquer uma atualizar
      await for (final _ in Stream<dynamic>.periodic(const Duration(milliseconds: 250))) {
        // se ainda não tem nada, continua
        if (la == null && lb == null && lc == null) continue;

        yield [
          ...?la?.docs,
          ...?lb?.docs,
          ...?lc?.docs,
        ];
      }
    } finally {
      await sa.cancel();
      await sb.cancel();
      await sc.cancel();
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(firestoreProvider));
});