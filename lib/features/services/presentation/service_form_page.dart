import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/service.dart';
import '../data/service_repository.dart';

class ServiceFormPage extends ConsumerStatefulWidget {
  final Service service;

  const ServiceFormPage({super.key, required this.service});

  @override
  ConsumerState<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends ConsumerState<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _durationController =
        TextEditingController(text: widget.service.durationMin.toString());
    _priceController =
        TextEditingController(text: widget.service.price.toStringAsFixed(2));
    _isActive = widget.service.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int _parseIntSafe(String v, {int fallback = 0}) {
    return int.tryParse(v.trim()) ?? fallback;
  }

  double _parseDoubleSafe(String v, {double fallback = 0.0}) {
    final normalized = v.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.service.name.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Novo serviço' : 'Editar serviço')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duração (min)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = _parseIntSafe(v ?? '', fallback: -1);
                  if (n <= 0) return 'Informe uma duração válida';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final p = _parseDoubleSafe(v ?? '', fallback: -1);
                  if (p < 0) return 'Informe um preço válido';
                  return null;
                },
              ),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Ativo'),
              ),
              const Spacer(),

              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final updated = Service(
                          id: widget.service.id,
                          name: _nameController.text.trim(),
                          durationMin: _parseIntSafe(
                            _durationController.text,
                            fallback: widget.service.durationMin,
                          ),
                          price: _parseDoubleSafe(
                            _priceController.text,
                            fallback: widget.service.price,
                          ),
                          isActive: _isActive,
                        );

                        setState(() => _saving = true);

                        // ✅ capture antes do await (não usar context depois)
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await ref
                              .read(serviceRepositoryProvider)
                              .save(updated)
                              .timeout(const Duration(seconds: 12));

                          if (!mounted) return;

                          setState(() => _saving = false);

                          // ✅ retorna resultado para a lista
                          nav.pop(updated);
                          return;
                        } catch (e) {
                          if (!mounted) return;

                          setState(() => _saving = false);

                          messenger.showSnackBar(
                            SnackBar(content: Text('Erro ao salvar: $e')),
                          );
                        }
                      },
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