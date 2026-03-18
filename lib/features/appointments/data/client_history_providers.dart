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
    Provider.family<AsyncValue<List<ClientServiceHistoryGroup>>, String>(
  (ref, clientId) {
    final appointmentsAsync = ref.watch(clientAppointmentsProvider(clientId));

    return appointmentsAsync.whenData((appointments) {
      final map = <String, List<ClientServiceHistoryItem>>{};

      for (final appointment in appointments) {
        if (appointment.status == AppointmentStatus.canceled) continue;

        for (final service in appointment.services) {
          map.putIfAbsent(service.serviceId, () => []).add(
                ClientServiceHistoryItem(
                  appointment: appointment,
                  service: service,
                ),
              );
        }
      }

      final result = map.entries.map((entry) {
        final items = entry.value;

        items.sort(
          (a, b) => b.appointment.startAt.compareTo(a.appointment.startAt),
        );

        final first = items.first;

        final doneCount = items
            .where((item) => item.appointment.status == AppointmentStatus.done)
            .length;

        final confirmedCount = items
            .where((item) => item.appointment.status == AppointmentStatus.confirmed)
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
          lastDate: items.isEmpty ? null : items.first.appointment.startAt,
          lastPaymentMethodLabel: items.first.appointment.paymentMethod?.label,
          items: items,
        );
      }).toList();

      result.sort((a, b) => a.serviceName.compareTo(b.serviceName));
      return result;
    });
  },
);