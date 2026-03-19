import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../domain/appointment.dart';

class AppointmentRepository {
  final FirebaseFirestore _db;
  AppointmentRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  void _log(String message) {
    dev.log(message, name: 'AppointmentRepository');
  }

  Future<void> saveWithConflictCheck(Appointment a) async {
    final dayStart = DateTime(a.startAt.year, a.startAt.month, a.startAt.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    _log('ENTER saveWithConflictCheck: ${a.startAt} -> ${a.endAt}');

    try {
      final snap = await _col
          .where(
            'startAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart.toUtc()),
          )
          .where(
            'startAt',
            isLessThan: Timestamp.fromDate(dayEnd.toUtc()),
          )
          .orderBy('startAt')
          .get()
          .timeout(const Duration(seconds: 10));

      _log('same day docs: ${snap.docs.length}');

      final sameDay = snap.docs
          .map((d) => Appointment.fromMap(d.id, d.data()))
          .where((x) => x.id != a.id)
          .toList();

      final hasOverlap = sameDay.any((x) {
        return a.startAt.isBefore(x.endAt) && a.endAt.isAfter(x.startAt);
      });

      if (hasOverlap) {
        throw StateError('Já existe agendamento nesse horário.');
      }

      await _col
          .doc(a.id)
          .set(a.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));

      _log('saved OK: ${a.id}');
    } on TimeoutException catch (e, st) {
      _log('TIMEOUT: $e');
      dev.log('$st', name: 'AppointmentRepository');
      rethrow;
    } on FirebaseException catch (e, st) {
      _log('FirebaseException: ${e.code} - ${e.message}');
      dev.log('$st', name: 'AppointmentRepository');
      rethrow;
    } catch (e, st) {
      _log('ERROR: $e');
      dev.log('$st', name: 'AppointmentRepository');
      rethrow;
    }
  }

  Stream<Appointment?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Appointment.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<List<Appointment>> watchByClient(String clientId) {
    return _col.where('clientId', isEqualTo: clientId).limit(200).snapshots().map(
      (snap) {
        final items = snap.docs
            .map((d) => Appointment.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));

        return items;
      },
    );
  }

  Future<void> updateStatus(String id, AppointmentStatus status) async {
    await _col.doc(id).update({
      'status': status.name,
    });
  }

  Future<void> completeWithPayment({
    required Appointment appointment,
    required PaymentMethod method,
  }) async {
    final batch = _db.batch();

    final apptRef = _col.doc(appointment.id);
    final txRef = _db.collection('transactions').doc();

    final paidAt = FieldValue.serverTimestamp();
    final occurredAt = Timestamp.fromDate(appointment.startAt.toUtc());

    batch.update(apptRef, {
      'status': AppointmentStatus.done.name,
      'paymentMethod': method.name,
      'paidAt': paidAt,
    });

    batch.set(txRef, {
      'type': 'income',
      'amount': appointment.totalPrice,
      'paymentMethod': method.name,
      'appointmentId': appointment.id,
      'clientId': appointment.clientId,
      'occurredAt': occurredAt,
      'createdAt': FieldValue.serverTimestamp(),
      'paidAt': paidAt,
    });

    await batch.commit();

    _log('Payment completed for appointment: ${appointment.id}');
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    _log('Deleted appointment: $id');
  }

  Stream<List<Appointment>> watchRange(DateTime from, DateTime to) {
    _log('watchRange: $from -> $to');

    return _col
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from.toUtc()),
        )
        .where(
          'startAt',
          isLessThan: Timestamp.fromDate(to.toUtc()),
        )
        .orderBy('startAt')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Appointment.fromMap(d.id, d.data()))
          .toList();

      _log('watchRange docs: ${list.length}');
      return list;
    });
  }
}

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(ref.watch(firestoreProvider));
});