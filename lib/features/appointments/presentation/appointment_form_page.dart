import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../clients/data/client_providers.dart';
import '../../clients/domain/client.dart';
import '../../services/data/service_repository.dart';
import '../../services/domain/service.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';

class AppointmentFormPage extends ConsumerStatefulWidget {
  const AppointmentFormPage({super.key});

  @override
  ConsumerState<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  String? _clientId;
  DateTime? _startAt;
  List<Service> _selectedServices = [];
  AppointmentStatus _status = AppointmentStatus.pending;
  bool _saving = false;

  int get _totalDurationMin =>
      _selectedServices.fold<int>(0, (sum, s) => sum + s.durationMin);

  double get _totalPrice =>
      _selectedServices.fold<double>(0, (sum, s) => sum + s.price);

  DateTime? get _endAt {
    final start = _startAt;
    if (start == null) return null;
    final minutes = _totalDurationMin;
    if (minutes <= 0) return start;
    return start.add(Duration(minutes: minutes));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
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

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _startAt ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (!mounted || time == null) return;

    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickServices(List<Service> allServices) async {
    final active = allServices.where((s) => s.isActive).toList();
    final selectedIds = _selectedServices.map((e) => e.id).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final temp = {...selectedIds};

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setModalState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selecione os serviços',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: active.length,
                      itemBuilder: (_, i) {
                        final s = active[i];
                        final checked = temp.contains(s.id);

                        return CheckboxListTile(
                          value: checked,
                          title: Text(s.name),
                          subtitle: Text(
                            '${s.durationMin} min • R\$ ${s.price.toStringAsFixed(2)}',
                          ),
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                temp.add(s.id);
                              } else {
                                temp.remove(s.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, <String>{}),
                        child: const Text('Limpar'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, temp),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    final picked = active.where((s) => result.contains(s.id)).toList();

    setState(() {
      _selectedServices = picked;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_clientId == null || _clientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente.')),
      );
      return;
    }

    if (_startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data e hora.')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos 1 serviço.')),
      );
      return;
    }

    final start = _startAt!;
    final end = _endAt!;

    final servicesItems = _selectedServices
        .map(
          (s) => AppointmentServiceItem(
            serviceId: s.id,
            nameSnapshot: s.name,
            durationMin: s.durationMin,
            price: s.price,
          ),
        )
        .toList();

    final appointment = Appointment(
      id: const Uuid().v4(),
      clientId: _clientId!,
      startAt: start,
      endAt: end,
      status: _status,
      services: servicesItems,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    setState(() => _saving = true);

    try {
      // ignore: avoid_print
      print(
        '[UI] Chamando saveWithConflictCheck: ${appointment.startAt} -> ${appointment.endAt}',
      );

      await ref
          .read(appointmentRepositoryProvider)
          .saveWithConflictCheck(appointment)
          .timeout(const Duration(seconds: 12));

      // ignore: avoid_print
      print('[UI] Salvou OK');

      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.pop(context, appointment);
    } on TimeoutException {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tempo excedido ao salvar. Tente novamente.'),
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[UI] ERRO AO SALVAR: $e');
      // ignore: avoid_print
      print(st);

      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final servicesAsync = ref.watch(servicesStreamProvider);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo agendamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              clientsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar clientes: $e'),
                data: (clients) {
                  return DropdownButtonFormField<String>(
                    initialValue: _clientId,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                    ),
                    items: clients
                        .map(
                          (Client c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _clientId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data e hora'),
                subtitle: Text(
                  _startAt == null
                      ? 'Toque para escolher'
                      : fmt.format(_startAt!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDateTime,
              ),
              const Divider(),
              DropdownButtonFormField<AppointmentStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: AppointmentStatus.values
                    .map(
                      (status) => DropdownMenuItem<AppointmentStatus>(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              servicesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar serviços: $e'),
                data: (services) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Serviços'),
                        subtitle: Text(
                          _selectedServices.isEmpty
                              ? 'Toque para selecionar'
                              : _selectedServices.map((e) => e.name).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickServices(services),
                      ),
                      if (_selectedServices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Duração: $_totalDurationMin min • Total: R\$ ${_totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Término estimado'),
                subtitle: Text(
                  _endAt == null ? '-' : fmt.format(_endAt!),
                ),
                trailing: const Icon(Icons.schedule),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}