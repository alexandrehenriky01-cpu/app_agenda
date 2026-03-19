import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_repository.dart';
import '../domain/service.dart';

class ServiceFormPage extends ConsumerStatefulWidget {
  final Service service;

  const ServiceFormPage({
    super.key,
    required this.service,
  });

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

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);
  static const _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _durationController = TextEditingController(
      text: widget.service.durationMin.toString(),
    );
    _priceController = TextEditingController(
      text: widget.service.price.toStringAsFixed(2),
    );
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _pink),
      filled: true,
      fillColor: _white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _rose.withValues(alpha: 0.65)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _rose.withValues(alpha: 0.65)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _pink, width: 1.6),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.service.name.trim().isEmpty;

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isNew ? 'Novo serviço' : 'Editar serviço',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.design_services,
                      color: _pink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNew ? 'Cadastro de serviço' : 'Atualizar serviço',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Defina nome, duração, preço e status.',
                          style: TextStyle(
                            color: _ink.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'Nome do serviço',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _durationController,
                      decoration: _inputDecoration(
                        label: 'Duração (min)',
                        icon: Icons.schedule_outlined,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = _parseIntSafe(v ?? '', fallback: -1);
                        if (n <= 0) return 'Informe uma duração válida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _priceController,
                      decoration: _inputDecoration(
                        label: 'Preço',
                        icon: Icons.attach_money,
                        hint: '0,00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final p = _parseDoubleSafe(v ?? '', fallback: -1);
                        if (p < 0) return 'Informe um preço válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _rose.withValues(alpha: 0.65),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text(
                          'Serviço ativo',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          _isActive
                              ? 'Disponível para agendamento'
                              : 'Oculto para novos agendamentos',
                        ),
                        activeColor: _pink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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

                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                try {
                                  await ref
                                      .read(serviceRepositoryProvider)
                                      .save(updated)
                                      .timeout(const Duration(seconds: 12));

                                  if (!mounted) return;

                                  setState(() => _saving = false);
                                  nav.pop(updated);
                                  return;
                                } catch (e) {
                                  if (!mounted) return;

                                  setState(() => _saving = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao salvar: $e'),
                                    ),
                                  );
                                }
                              },
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Salvando...' : 'Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: _white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}