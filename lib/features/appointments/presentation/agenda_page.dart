import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' hide Appointment;

import '../../../core/whatsapp/whatsapp_service.dart';
import '../../clients/data/client_providers.dart';
import '../../clients/domain/client.dart';
import '../data/appointment_providers.dart';
import '../domain/appointment.dart';
import 'appointment_detail_page.dart';
import 'appointment_form_page.dart';
import 'calendar_data_source.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  final CalendarController _controller = CalendarController();
  late final AppCalendarDataSource _dataSource;

  DateTime _visibleMonth = DateTime.now();

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _gold = Color(0xFFC9A227);
  static const _ink = Color(0xFF1F1F1F);

  static const String _studioPhone = '5518996898121';

  @override
  void initState() {
    super.initState();
    _dataSource = AppCalendarDataSource(const <CalendarEvent>[]);
    _controller.view = CalendarView.month;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateRange _monthRange(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return DateRange(first, nextMonth);
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF2E7D32);
      case AppointmentStatus.done:
        return const Color(0xFF546E7A);
      case AppointmentStatus.canceled:
        return const Color(0xFFC62828);
      case AppointmentStatus.pending:
        return const Color(0xFFEF6C00);
    }
  }

  String _statusShort(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.confirmed:
        return 'CONF';
      case AppointmentStatus.done:
        return 'OK';
      case AppointmentStatus.canceled:
        return 'CANC';
      case AppointmentStatus.pending:
        return 'PEND';
    }
  }

  void _setView(CalendarView view) {
    _controller.view = view;
    setState(() {});
  }

  String _birthdayMessage(Client c) {
    return 'Olá ${c.name} 🎉🎂\n\n'
        'Passando para te desejar um *Feliz Aniversário*! 💖\n'
        'Que seu dia seja incrível!\n\n'
        'Se quiser comemorar com um cuidado especial, me chama aqui que eu te ajudo a marcar um horário 😊';
  }

  Future<void> _openBirthdayPicker(
    BuildContext context,
    List<Client> birthdayClients,
  ) async {
    final picked = await showModalBottomSheet<Client>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.cake, color: _pink),
                  SizedBox(width: 8),
                  Text(
                    'Aniversariantes de hoje',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: birthdayClients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = birthdayClients[i];
                    final phone = c.phoneE164.trim();
                    final enabled = phone.isNotEmpty;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: _rose,
                        child: Icon(Icons.person, color: _pink),
                      ),
                      title: Text(c.name),
                      subtitle: Text(phone.isEmpty ? 'Sem telefone' : phone),
                      enabled: enabled,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: !enabled ? null : () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;

    final phone = picked.phoneE164.trim();
    if (phone.isEmpty) return;

    if (!context.mounted) return;

    await WhatsAppService.openWhatsApp(
      phoneE164OrAny: phone,
      message: _birthdayMessage(picked),
    );
  }

  Future<void> _openNewAppointment(BuildContext context) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await nav.push<Appointment?>(
      MaterialPageRoute(
        builder: (_) => const AppointmentFormPage(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          content: Text('Agendamento salvo!'),
        ),
      );
    }
  }

  Widget _viewChips() {
    final current = _controller.view ?? CalendarView.month;

    Widget chip(String label, IconData icon, CalendarView view) {
      final selected = current == view;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : _pink),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        selectedColor: _pink,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : _pink,
        ),
        side: BorderSide(color: selected ? _pink : _rose),
        backgroundColor: Colors.white,
        onSelected: (_) => _setView(view),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Mês', Icons.calendar_month, CalendarView.month),
        chip('Semana', Icons.view_week, CalendarView.week),
        chip('Dia', Icons.view_day, CalendarView.day),
      ],
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStudioWhatsApp(BuildContext context) async {
    try {
      await WhatsAppService.openWhatsApp(
        phoneE164OrAny: _studioPhone,
        message: 'Olá! Gostaria de agendar um horário 😊',
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          content: Text('Não foi possível abrir o WhatsApp.'),
        ),
      );
    }
  }

  Widget _premiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_nude, _rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_er.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'Studio Elisa Rodriguez',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _viewChips(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickButton(
                icon: Icons.add,
                label: 'Agendar',
                color: _pink,
                onTap: () => _openNewAppointment(context),
              ),
              _quickButton(
                icon: Icons.people,
                label: 'Clientes',
                color: _gold,
                onTap: () => context.go('/clients'),
              ),
              _quickButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _openStudioWhatsApp(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: SfCalendar(
        controller: _controller,
        view: _controller.view ?? CalendarView.month,
        dataSource: _dataSource,
        headerStyle: const CalendarHeaderStyle(
          textAlign: TextAlign.center,
          textStyle: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _ink,
          ),
        ),
        viewHeaderStyle: ViewHeaderStyle(
          dayTextStyle: TextStyle(
            color: _ink.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
          dateTextStyle: TextStyle(
            color: _ink.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
        todayHighlightColor: _pink,
        selectionDecoration: BoxDecoration(
          border: Border.all(color: _pink, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 7,
          endHour: 21,
          timeIntervalHeight: 60,
          timeFormat: 'HH:mm',
        ),
        monthViewSettings: const MonthViewSettings(
          showAgenda: true,
          agendaItemHeight: 56,
        ),
        onViewChanged: (details) {
          final visibleDates = details.visibleDates;
          if (visibleDates.isEmpty) return;

          final mid = visibleDates[visibleDates.length ~/ 2];
          final newMonth = DateTime(mid.year, mid.month, 1);

          if (newMonth.year == _visibleMonth.year &&
              newMonth.month == _visibleMonth.month) {
            return;
          }

          setState(() => _visibleMonth = newMonth);
        },
        onTap: (details) async {
          final nav = Navigator.of(context);

          if (details.appointments != null && details.appointments!.isNotEmpty) {
            final event = details.appointments!.first as CalendarEvent;

            await nav.push(
              MaterialPageRoute(
                builder: (_) => AppointmentDetailPage(
                  appointmentId: event.id,
                ),
              ),
            );

            if (!mounted) return;
            return;
          }

          await _openNewAppointment(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _monthRange(_visibleMonth);
    final appointmentsAsync = ref.watch(appointmentsRangeProvider(range));
    final birthdaysToday = ref.watch(birthdayClientsTodayProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);

    final clientNameById = clientsAsync.maybeWhen(
      data: (clients) => {
        for (final c in clients) c.id: c.name,
      },
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _nude,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Agenda',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Erro no stream: $e'),
        ),
        data: (items) {
          final events = items.map((a) {
            final clientName = clientNameById[a.clientId] ?? 'Cliente';
            final servicesLabel =
                a.services.map((s) => s.nameSnapshot).join(' + ');
            final statusLabel = _statusShort(a.status);

            final title = [
              clientName,
              if (servicesLabel.isNotEmpty) servicesLabel,
              '[$statusLabel]',
            ].join(' • ');

            return CalendarEvent.safe(
              id: a.id,
              title: title,
              from: a.startAt,
              to: a.endAt,
              color: _statusColor(a.status),
              payload: a,
            );
          }).toList();

          _dataSource.setEvents(events);

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            children: [
              _premiumHeader(context),
              const SizedBox(height: 12),
              if (birthdaysToday.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [_pink, _gold],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.cake, color: _pink),
                    ),
                    title: Text(
                      '🎉 ${birthdaysToday.length} aniversariante(s) hoje',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: const Text(
                      'Toque para enviar mensagem no WhatsApp',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.white),
                    onTap: () => _openBirthdayPicker(context, birthdaysToday),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _legendItem(
                      'Pendente',
                      _statusColor(AppointmentStatus.pending),
                    ),
                    _legendItem(
                      'Confirmado',
                      _statusColor(AppointmentStatus.confirmed),
                    ),
                    _legendItem(
                      'Concluído',
                      _statusColor(AppointmentStatus.done),
                    ),
                    _legendItem(
                      'Cancelado',
                      _statusColor(AppointmentStatus.canceled),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 640,
                child: _calendarCard(context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        onPressed: () => _openNewAppointment(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _ink.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}