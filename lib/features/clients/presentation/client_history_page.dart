import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../appointments/data/client_history_providers.dart';
import '../../appointments/domain/appointment.dart';
import '../domain/client.dart';

class ClientHistoryPage extends ConsumerWidget {
  final Client client;

  const ClientHistoryPage({
    super.key,
    required this.client,
  });

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);
  static const _white = Colors.white;

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(value);
  }

  String _date(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.done:
        return 'Concluído';
      case AppointmentStatus.canceled:
        return 'Cancelado';
    }
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.done:
        return Colors.blueGrey;
      case AppointmentStatus.canceled:
        return Colors.red;
    }
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rose),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _pink),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(clientHistoryGroupedProvider(client.id));

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Histórico do Cliente',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: groupedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Erro: $e'),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text('Nenhum atendimento encontrado para este cliente.'),
            );
          }

          final totalAtendimentos =
              groups.fold<int>(0, (sum, group) => sum + group.count);

          final totalGasto =
              groups.fold<double>(0, (sum, group) => sum + group.totalValue);

          final totalServicos = groups.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_nude, Color(0xFFF7DCE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (client.phoneE164.isNotEmpty)
                        Text(
                          client.phoneE164,
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(
                            icon: Icons.event,
                            label: '$totalAtendimentos atendimentos',
                          ),
                          _infoChip(
                            icon: Icons.attach_money,
                            label: _money(totalGasto),
                          ),
                          _infoChip(
                            icon: Icons.design_services,
                            label: '$totalServicos serviços',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...groups.map((group) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      group.serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Qtde: ${group.count} • Total: ${_money(group.totalValue)}\n'
                        'Último: ${_date(group.lastDate)}',
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ),
                    children: group.items.map((item) {
                      final appointment = item.appointment;
                      final service = item.service;
                      final statusColor = _statusColor(appointment.status);

                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _date(appointment.startAt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(appointment.status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Valor: ${_money(service.price)} • Duração: ${service.durationMin} min',
                              style: TextStyle(
                                color: _ink.withValues(alpha: 0.82),
                              ),
                            ),
                            if (appointment.paymentMethod != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Pagamento: ${appointment.paymentMethod!.label}',
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                            if (appointment.notes?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Obs: ${appointment.notes}',
                                style: TextStyle(
                                  color: _ink.withValues(alpha: 0.70),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}