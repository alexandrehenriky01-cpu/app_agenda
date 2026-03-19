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
  static const _white = Colors.white;

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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

  Widget _viewChipHorizontal(
    String label,
    IconData icon,
    CalendarView view,
  ) {
    final selected = _controller.view == view;

    return GestureDetector(
      onTap: () => _setView(view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _pink : _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _pink : _rose,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? _white : _pink,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? _white : _pink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionWideButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_nude, Color(0xFFF7DCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo_er.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Studio Elisa Rodriguez',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agenda e gestão do studio',
                        style: TextStyle(
                          color: _ink.withValues(alpha: 0.60),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickActionWideButton(
                  icon: Icons.people,
                  label: 'Clientes',
                  color: _gold,
                  onTap: () => context.go('/clients'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionWideButton(
                  icon: Icons.add,
                  label: 'Agendar',
                  color: _pink,
                  onTap: () => _openNewAppointment(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _viewChipHorizontal(
                  'Mês',
                  Icons.calendar_month,
                  CalendarView.month,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _viewChipHorizontal(
                  'Semana',
                  Icons.view_week,
                  CalendarView.week,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _viewChipHorizontal(
                  'Dia',
                  Icons.view_day,
                  CalendarView.day,
                ),
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
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SfCalendar(
          controller: _controller,
          view: _controller.view ?? CalendarView.month,
          dataSource: _dataSource,
          allowViewNavigation: true,
          showNavigationArrow: true,
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
            showAgenda: false,
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
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

            if (details.appointments != null &&
                details.appointments!.isNotEmpty) {
              final event = details.appointments!.first as CalendarEvent;

              await nav.push(
                MaterialPageRoute(
                  builder: (_) => AppointmentDetailPage(
                    appointmentId: event.id,
                  ),
                ),
              );
              return;
            }

            await _openNewAppointment(context);
          },
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
              color: _ink.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _white,
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
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _legendItem('Pendente', _statusColor(AppointmentStatus.pending)),
          _legendItem('Confirmado', _statusColor(AppointmentStatus.confirmed)),
          _legendItem('Concluído', _statusColor(AppointmentStatus.done)),
          _legendItem('Cancelado', _statusColor(AppointmentStatus.canceled)),
        ],
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
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
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

          return SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final calendarHeight = width < 420 ? 280.0 : 320.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headerCard(context),
                      if (birthdaysToday.isNotEmpty) ...[
                        const SizedBox(height: 12),
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
                              backgroundColor: _white,
                              child: Icon(Icons.cake, color: _pink),
                            ),
                            title: Text(
                              '🎉 ${birthdaysToday.length} aniversariante(s) hoje',
                              style: const TextStyle(
                                color: _white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: const Text(
                              'Toque para enviar mensagem no WhatsApp',
                              style: TextStyle(color: _white),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: _white,
                            ),
                            onTap: () =>
                                _openBirthdayPicker(context, birthdaysToday),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _legendCard(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: calendarHeight,
                        child: _calendarCard(context),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pink,
        foregroundColor: _white,
        onPressed: () => _openNewAppointment(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}