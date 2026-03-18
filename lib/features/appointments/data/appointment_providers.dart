import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appointment.dart';
import 'appointment_repository.dart';
import 'current_range_provider.dart';

/// Classe para representar um intervalo de datas
@immutable
class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'DateRange($from -> $to)';
}

/// Provider para listar agendamentos dentro de um período informado manualmente
final appointmentsRangeProvider =
    StreamProvider.family<List<Appointment>, DateRange>((ref, range) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.watchRange(range.from, range.to);
});

/// Provider para listar agendamentos usando o período atual selecionado
final appointmentsInRangeProvider = StreamProvider<List<Appointment>>((ref) {
  final range = ref.watch(currentRangeProvider);
  final repo = ref.watch(appointmentRepositoryProvider);

  return repo.watchRange(range.start, range.end);
});

/// Provider para observar um agendamento específico pelo ID
final appointmentByIdProvider =
    StreamProvider.family<Appointment?, String>((ref, id) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.watchById(id);
});