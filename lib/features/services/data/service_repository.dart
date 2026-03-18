import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase_providers.dart';
import '../domain/service.dart';

class ServiceRepository {
  final FirebaseFirestore _db;
  ServiceRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('services');

  Stream<List<Service>> watchAll() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Service.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> save(Service service) async {
    await _col.doc(service.id).set(service.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.watch(firestoreProvider));
});

final servicesStreamProvider = StreamProvider<List<Service>>((ref) {
  return ref.watch(serviceRepositoryProvider).watchAll();
});