import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  final Client client;

  const ClientFormPage({
    super.key,
    required this.client,
  });

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

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);
  static const _white = Colors.white;

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

  String _normalizePhone(String value) {
    final cleaned = value.trim();
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

    if (!mounted || picked == null) return;

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

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(clientRepositoryProvider);

    try {
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
        centerTitle: true,
        title: Text(
          isNew ? 'Novo cliente' : 'Editar cliente',
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
                    child: const Icon(Icons.person, color: _pink, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNew ? 'Cadastro de cliente' : 'Atualizar cliente',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preencha os dados principais do cliente.',
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
                      controller: _name,
                      decoration: _inputDecoration(
                        label: 'Nome',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneE164,
                      decoration: _inputDecoration(
                        label: 'Telefone',
                        icon: Icons.phone_iphone,
                        hint: '+5511999999999',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final n = _normalizePhone(v ?? '');
                        if (n.length < 8) return 'Telefone inválido';
                        if (!n.startsWith('+')) {
                          return 'Use formato com + (E.164)';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _saving ? null : _pickBirthDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _rose.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: _pink),
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
                                  const SizedBox(height: 3),
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
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notes,
                      decoration: _inputDecoration(
                        label: 'Observações',
                        icon: Icons.notes_outlined,
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
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