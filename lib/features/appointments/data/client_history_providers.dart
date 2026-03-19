import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appointment.dart';
import 'appointment_repository.dart';

class ClientServiceHistoryItem {
  final Appointment appointment;
  final AppointmentServiceItem service;

  const ClientServiceHistoryItem({
    required this.appointment,
    required this.service,
  });
}

class ClientServiceHistoryGroup {
  final String serviceId;
  final String serviceName;
  final int count;
  final int doneCount;
  final int confirmedCount;
  final int pendingCount;
  final double totalValue;
  final double totalPaid;
  final DateTime? lastDate;
  final String? lastPaymentMethodLabel;
  final List<ClientServiceHistoryItem> items;

  const ClientServiceHistoryGroup({
    required this.serviceId,
    required this.serviceName,
    required this.count,
    required this.doneCount,
    required this.confirmedCount,
    required this.pendingCount,
    required this.totalValue,
    required this.totalPaid,
    required this.lastDate,
    required this.lastPaymentMethodLabel,
    required this.items,
  });
}

final clientAppointmentsProvider =
    StreamProvider.family<List<Appointment>, String>((ref, clientId) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.watchByClient(clientId);
});

final clientHistoryGroupedProvider =
    Provider.family<AsyncValue<List<ClientServiceHistoryGroup>>, String>((
  ref,
  clientId,
) {
  final appointmentsAsync = ref.watch(clientAppointmentsProvider(clientId));

  return appointmentsAsync.whenData((appointments) {
    if (appointments.isEmpty) {
      return const <ClientServiceHistoryGroup>[];
    }

    final groupedMap = <String, List<ClientServiceHistoryItem>>{};

    for (final appointment in appointments) {
      if (appointment.status == AppointmentStatus.canceled) continue;
      if (appointment.services.isEmpty) continue;

      for (final service in appointment.services) {
        final serviceKey = service.serviceId.trim().isNotEmpty
            ? service.serviceId
            : service.nameSnapshot.trim();

        groupedMap.putIfAbsent(serviceKey, () => []);

        groupedMap[serviceKey]!.add(
          ClientServiceHistoryItem(
            appointment: appointment,
            service: service,
          ),
        );
      }
    }

    if (groupedMap.isEmpty) {
      return const <ClientServiceHistoryGroup>[];
    }

    final result = groupedMap.entries.map((entry) {
      final items = [...entry.value]
        ..sort(
          (a, b) => b.appointment.startAt.compareTo(a.appointment.startAt),
        );

      final first = items.first;

      final doneCount = items
          .where((item) => item.appointment.status == AppointmentStatus.done)
          .length;

      final confirmedCount = items
          .where(
            (item) => item.appointment.status == AppointmentStatus.confirmed,
          )
          .length;

      final pendingCount = items
          .where((item) => item.appointment.status == AppointmentStatus.pending)
          .length;

      final totalValue = items.fold<double>(
        0,
        (sum, item) => sum + item.service.price,
      );

      final totalPaid = items.fold<double>(0, (sum, item) {
        return item.appointment.status == AppointmentStatus.done
            ? sum + item.service.price
            : sum;
      });

      return ClientServiceHistoryGroup(
        serviceId: first.service.serviceId,
        serviceName: first.service.nameSnapshot,
        count: items.length,
        doneCount: doneCount,
        confirmedCount: confirmedCount,
        pendingCount: pendingCount,
        totalValue: totalValue,
        totalPaid: totalPaid,
        lastDate: first.appointment.startAt,
        lastPaymentMethodLabel: first.appointment.paymentMethod?.label,
        items: items,
      );
    }).toList();

    result.sort((a, b) {
      final aDate = a.lastDate;
      final bDate = b.lastDate;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return result;
  });
});