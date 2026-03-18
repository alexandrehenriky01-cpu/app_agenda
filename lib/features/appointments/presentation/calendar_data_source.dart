import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

/// Modelo usado pelo SfCalendar
class CalendarEvent {
  final String id;
  final String title;
  final DateTime from;
  final DateTime to;
  final Color color;

  /// Opcional: para anexar qualquer coisa (ex.: Appointment, clientId etc.)
  final Object? payload;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.from,
    required this.to,
    required this.color,
    this.payload,
  }) : assert(
          // Evita crash no Syncfusion: término precisa ser depois do início
          to.isAfter(from),
          'CalendarEvent.to must be after CalendarEvent.from',
        );

  /// Se quiser ser mais tolerante (não quebrar em runtime),
  /// use este construtor para "consertar" eventos inválidos.
  factory CalendarEvent.safe({
    required String id,
    required String title,
    required DateTime from,
    required DateTime to,
    required Color color,
    Object? payload,
    Duration minDuration = const Duration(minutes: 1),
  }) {
    final fixedTo = to.isAfter(from) ? to : from.add(minDuration);
    return CalendarEvent(
      id: id,
      title: title,
      from: from,
      to: fixedTo,
      color: color,
      payload: payload,
    );
  }
}

/// DataSource do SfCalendar
class AppCalendarDataSource extends sf.CalendarDataSource {
  AppCalendarDataSource(List<CalendarEvent> events) {
    appointments = List<CalendarEvent>.from(events);
  }

  List<CalendarEvent> get events =>
      (appointments ?? const <Object>[]).cast<CalendarEvent>();

  /// ✅ Atualiza todos os eventos e notifica o calendário (evita “evento fantasma” / crash em rebuild)
  void setEvents(List<CalendarEvent> newEvents) {
    appointments = List<CalendarEvent>.from(newEvents);
    notifyListeners(sf.CalendarDataSourceAction.reset, newEvents);
  }

  /// ✅ Adiciona 1 evento e notifica
  void addEvent(CalendarEvent e) {
    final list = List<CalendarEvent>.from(events)..add(e);
    appointments = list;
    notifyListeners(sf.CalendarDataSourceAction.add, <CalendarEvent>[e]);
  }

  /// ✅ Remove por id e notifica
  void removeById(String id) {
    final list = List<CalendarEvent>.from(events);
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final removed = list.removeAt(idx);
    appointments = list;
    notifyListeners(sf.CalendarDataSourceAction.remove, <CalendarEvent>[removed]);
  }

  /// ✅ Substitui um evento por id e notifica
  void upsert(CalendarEvent e) {
    final list = List<CalendarEvent>.from(events);
    final idx = list.indexWhere((x) => x.id == e.id);

    if (idx >= 0) {
      final old = list[idx];
      list[idx] = e;
      appointments = list;
      notifyListeners(
        sf.CalendarDataSourceAction.reset,
        <CalendarEvent>[old, e],
      );
    } else {
      addEvent(e);
    }
  }

  @override
  DateTime getStartTime(int index) => events[index].from;

  @override
  DateTime getEndTime(int index) => events[index].to;

  @override
  String getSubject(int index) => events[index].title;

  @override
  Color getColor(int index) => events[index].color;

  @override
  bool isAllDay(int index) => false;

  /// ✅ Opcional: permite recuperar o objeto inteiro de um "appointment"
  CalendarEvent eventAt(int index) => events[index];
}