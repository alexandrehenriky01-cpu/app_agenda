import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/whatsapp/whatsapp_service.dart';
import '../../clients/data/client_providers.dart';
import '../../clients/domain/client.dart';
import '../data/appointment_providers.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';

class AppointmentDetailPage extends ConsumerWidget {
  final String appointmentId;

  const AppointmentDetailPage({
    super.key,
    required this.appointmentId,
  });

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
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

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.done:
        return Colors.blueGrey;
      case AppointmentStatus.canceled:
        return Colors.red;
      case AppointmentStatus.pending:
        return Colors.orange;
    }
  }

  double _totalPrice(Appointment a) {
    return a.services.fold<double>(0, (sum, s) => sum + s.price);
  }

  int _totalMin(Appointment a) {
    return a.services.fold<int>(0, (sum, s) => sum + s.durationMin);
  }

  String _servicesText(Appointment a) {
    if (a.services.isEmpty) return '-';
    return a.services.map((s) => s.nameSnapshot).join(' + ');
  }

  String _msgConfirm({
    required Client client,
    required Appointment a,
  }) {
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtTime = DateFormat('HH:mm');
    final services = _servicesText(a);
    final total = _totalPrice(a).toStringAsFixed(2);
    final duration = _totalMin(a);

    return 'Olá ${client.name} 👋\n\n'
        '✅ *Agendamento confirmado!*\n\n'
        '📅 ${fmt.format(a.startAt)} às ${fmtTime.format(a.startAt)}\n'
        '💄 $services\n'
        '⏱ $duration min\n'
        '💰 R\$ $total\n\n'
        'Se precisar reagendar, é só me chamar. 💖';
  }

  String _msgReminder({
    required Client client,
    required Appointment a,
  }) {
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtTime = DateFormat('HH:mm');
    final services = _servicesText(a);

    return 'Olá ${client.name} 👋\n\n'
        '⏰ *Lembrete do seu agendamento*\n\n'
        '📅 ${fmt.format(a.startAt)} às ${fmtTime.format(a.startAt)}\n'
        '💄 $services\n\n'
        'Se tiver algum imprevisto, me avise para reagendarmos. 💖';
  }

  String _msgCanceled({
    required Client client,
    required Appointment a,
  }) {
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtTime = DateFormat('HH:mm');

    return 'Olá ${client.name} 👋\n\n'
        '❌ *Agendamento cancelado*\n\n'
        '📅 ${fmt.format(a.startAt)} às ${fmtTime.format(a.startAt)}\n\n'
        'Quando quiser, posso te ajudar a marcar um novo horário. 💖';
  }

  String _msgBirthday({
    required Client client,
  }) {
    return '🎉 *Feliz aniversário, ${client.name}!* 🥳\n\n'
        'Que seu dia seja lindo e cheio de alegria! 💖\n'
        'Quando quiser, me chama que vou amar te atender. ✨';
  }

  bool _isBirthdayToday(Client client) {
    final b = client.birthDate;
    if (b == null) return false;

    final now = DateTime.now();
    return b.day == now.day && b.month == now.month;
  }

  Future<PaymentMethod?> _pickPaymentMethod(BuildContext context) async {
    return showDialog<PaymentMethod>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forma de recebimento'),
        content: const Text('Como foi pago este atendimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, PaymentMethod.cash),
            child: const Text('Dinheiro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, PaymentMethod.pix),
            child: const Text('Pix'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, PaymentMethod.card),
            child: const Text('Cartão'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aAsync = ref.watch(appointmentByIdProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do agendamento'),
      ),
      body: aAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Erro: $e'),
        ),
        data: (a) {
          if (a == null) {
            return const Center(
              child: Text('Agendamento não encontrado.'),
            );
          }

          final client = ref.watch(clientByIdProvider(a.clientId));
          final fmt = DateFormat('dd/MM/yyyy HH:mm');

          final servicesText = a.services.isEmpty
              ? '-'
              : a.services.map((s) => '• ${s.nameSnapshot}').join('\n');

          final total = _totalPrice(a).toStringAsFixed(2);
          final phone = (client?.phoneE164 ?? '').trim();
          final canWhatsApp = phone.isNotEmpty;
          final isBirthdayToday = client != null && _isBirthdayToday(client);

          final paymentInfo =
              (a.status == AppointmentStatus.done && a.paymentMethod != null)
                  ? 'Recebido em ${a.paymentMethod!.label}'
                  : null;

          final canConclude = a.status != AppointmentStatus.done &&
              a.status != AppointmentStatus.canceled;

          Future<void> sendWhatsApp(String msg) async {
            if (!canWhatsApp) return;

            await WhatsAppService.openWhatsApp(
              phoneE164OrAny: phone,
              message: msg,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(_statusLabel(a.status)),
                    backgroundColor:
                        _statusColor(a.status).withValues(alpha: 0.15),
                    side: BorderSide(color: _statusColor(a.status)),
                  ),
                  const Spacer(),
                  Text(
                    'R\$ $total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),

              if (paymentInfo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(paymentInfo),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person),
                title: Text(client?.name ?? 'Carregando cliente...'),
                subtitle: Text(
                  client?.phoneE164.isNotEmpty == true
                      ? client!.phoneE164
                      : 'Sem telefone',
                ),
              ),

              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Horário'),
                subtitle: Text(
                  '${fmt.format(a.startAt)}  →  ${fmt.format(a.endAt)}',
                ),
              ),

              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.design_services),
                title: const Text('Serviços'),
                subtitle: Text(servicesText),
              ),

              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Duração total'),
                subtitle: Text('${_totalMin(a)} minutos'),
              ),

              if ((a.notes ?? '').trim().isNotEmpty) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes),
                  title: const Text('Observações'),
                  subtitle: Text(a.notes!),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                'Ações do atendimento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: a.status == AppointmentStatus.confirmed ||
                            a.status == AppointmentStatus.done ||
                            a.status == AppointmentStatus.canceled
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              await ref
                                  .read(appointmentRepositoryProvider)
                                  .updateStatus(
                                    a.id,
                                    AppointmentStatus.confirmed,
                                  );

                              if (!context.mounted) return;

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Status: Confirmado'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erro: $e'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirmar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: !canConclude
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final repo = ref.read(appointmentRepositoryProvider);

                            final method = await _pickPaymentMethod(context);
                            if (method == null) return;

                            if (!context.mounted) return;

                            try {
                              await repo.completeWithPayment(
                                appointment: a,
                                method: method,
                              );

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Concluído • Recebido em ${method.label}',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao concluir: $e'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.verified),
                    label: const Text('Concluir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: a.status == AppointmentStatus.canceled ||
                            a.status == AppointmentStatus.done
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);

                            try {
                              await ref
                                  .read(appointmentRepositoryProvider)
                                  .updateStatus(
                                    a.id,
                                    AppointmentStatus.canceled,
                                  );

                              if (!context.mounted) return;

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Status: Cancelado'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erro: $e'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final repo = ref.read(appointmentRepositoryProvider);

                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Excluir agendamento?'),
                          content: const Text(
                            'Essa ação não pode ser desfeita.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return;
                      if (!context.mounted) return;

                      try {
                        await repo.delete(a.id);
                        nav.pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Erro ao excluir: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'WhatsApp',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: (!canWhatsApp || client == null)
                        ? null
                        : () => sendWhatsApp(
                              _msgConfirm(client: client, a: a),
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmação'),
                  ),
                  ElevatedButton.icon(
                    onPressed: (!canWhatsApp || client == null)
                        ? null
                        : () => sendWhatsApp(
                              _msgReminder(client: client, a: a),
                            ),
                    icon: const Icon(Icons.alarm),
                    label: const Text('Lembrete'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: (!canWhatsApp || client == null)
                        ? null
                        : () => sendWhatsApp(
                              _msgCanceled(client: client, a: a),
                            ),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelamento'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBirthdayToday ? Colors.purple : Colors.grey,
                    ),
                    onPressed: (!canWhatsApp || client == null)
                        ? null
                        : () => sendWhatsApp(
                              _msgBirthday(client: client),
                            ),
                    icon: const Icon(Icons.cake),
                    label: Text(
                      isBirthdayToday
                          ? 'WhatsApp Aniversário (hoje)'
                          : 'WhatsApp Aniversário',
                    ),
                  ),
                ],
              ),

              if (client == null) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          );
        },
      ),
    );
  }
}