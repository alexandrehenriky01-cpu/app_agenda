import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/client.dart';

class ClientRepository {
  final FirebaseFirestore _db;
  ClientRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('clients');

  Stream<List<Client>> watchAll() {
    return _col.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) => Client.fromMap(d.id, d.data())).toList();
    });
  }

  Stream<Client?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Client.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> save(Client c) async {
    final ref = _col.doc(c.id);

    await ref.set(
      {
        ...c.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        // createdAt só define se ainda não existir
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(firestoreProvider));
});