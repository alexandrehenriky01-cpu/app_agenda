import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  final Client client;
  const ClientFormPage({super.key, required this.client});

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phoneE164;
  late final TextEditingController _notes;

  DateTime? _birthDate;
  bool _saving = false;

  // 🎨 Paleta “Studio”
  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.client.name);
    _phoneE164 = TextEditingController(text: widget.client.phoneE164);
    _notes = TextEditingController(text: widget.client.notes ?? '');
    _birthDate = widget.client.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _phoneE164.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _normalizePhone(String v) {
    final cleaned = v.trim();
    if (cleaned.startsWith('+')) {
      return '+${cleaned.substring(1).replaceAll(RegExp(r'\D'), '')}';
    }
    return '+${cleaned.replaceAll(RegExp(r'\D'), '')}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
    );

    if (!mounted) return;
    if (picked == null) return;

    setState(() {
      _birthDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final updated = Client(
      id: widget.client.id,
      name: _name.text.trim(),
      phoneE164: _normalizePhone(_phoneE164.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.client.createdAt,
      birthDate: _birthDate,
    );

    setState(() => _saving = true);

    // ✅ captura antes do await (boa prática)
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(clientRepositoryProvider);

    try {
      // ✅ RECOMENDADO: sem timeout (evita erro falso)
      // await repo.save(updated);

      // ✅ Se quiser manter timeout, use maior e trate TimeoutException:
      await repo.save(updated).timeout(const Duration(seconds: 45));

      if (!mounted) return;

      setState(() => _saving = false);
      nav.pop(updated);
    } on TimeoutException {
      if (!mounted) return;

      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Sem resposta do servidor. Verifique sua internet e tente novamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.client.name.isEmpty &&
        (widget.client.phoneE164 == '+55' || widget.client.phoneE164.isEmpty);

    final fmtBirth = DateFormat('dd/MM/yyyy');
    final birthText =
        _birthDate == null ? 'Não informado' : fmtBirth.format(_birthDate!);

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          isNew ? 'Novo cliente' : 'Editar cliente',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _rose.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _rose,
                        child: const Icon(Icons.person, color: _pink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isNew ? 'Cadastro de cliente' : 'Atualize os dados',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneE164,
                    decoration: const InputDecoration(
                      labelText: 'Telefone (E.164)',
                      hintText: '+5511999999999',
                      prefixIcon: Icon(Icons.phone_iphone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final n = _normalizePhone(v ?? '');
                      if (n.length < 8) return 'Telefone inválido';
                      if (!n.startsWith('+')) return 'Use formato com + (E.164)';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _saving ? null : _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _rose.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake, color: _pink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data de nascimento',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _ink.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  birthText,
                                  style: TextStyle(
                                    color: _ink.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: (_saving || _birthDate == null)
                          ? null
                          : () => setState(() => _birthDate = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Remover data'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Salvando...' : 'Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}