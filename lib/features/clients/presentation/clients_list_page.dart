import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/client_providers.dart';
import '../data/client_repository.dart';
import '../domain/client.dart';
import 'client_form_page.dart';
import 'client_history_page.dart';

class ClientsListPage extends ConsumerStatefulWidget {
  const ClientsListPage({super.key});

  @override
  ConsumerState<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends ConsumerState<ClientsListPage> {
  String _query = '';

  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);
  static const _white = Colors.white;

  Future<void> _deleteClient(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(clientRepositoryProvider);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text('Tem certeza que deseja excluir "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted || ok != true) return;

    try {
      await repo.delete(client.id);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente excluído com sucesso'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  Future<void> _openForm(BuildContext context, Client client) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await Navigator.push<Client?>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormPage(client: client),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente salvo com sucesso!'),
        ),
      );
    }
  }

  Future<void> _openHistory(BuildContext context, Client client) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientHistoryPage(client: client),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou telefone',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
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
      ),
      onChanged: (v) {
        setState(() => _query = v.trim().toLowerCase());
      },
    );
  }

  Widget _clientCard(BuildContext context, Client c) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _rose.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, color: _pink),
        ),
        title: Text(
          c.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            c.phoneE164,
            style: TextStyle(
              color: _ink.withValues(alpha: 0.68),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => _openForm(context, c),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'history':
                await _openHistory(context, c);
                break;
              case 'delete':
                await _deleteClient(context, ref, c);
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'history',
              child: Text('Histórico'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Excluir'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Clientes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: clientsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Erro: $e'),
        ),
        data: (clients) {
          final qDigits = _query.replaceAll(RegExp(r'\D'), '');

          final filtered = clients.where((c) {
            if (_query.isEmpty) return true;

            final nameMatch = c.name.toLowerCase().contains(_query);
            final phoneDigits = c.phoneE164.replaceAll(RegExp(r'\D'), '');
            final phoneMatch =
                qDigits.isEmpty ? false : phoneDigits.contains(qDigits);

            return nameMatch || phoneMatch;
          }).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: _white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.people,
                              color: _pink,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cadastro de clientes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${filtered.length} cliente(s) encontrado(s)',
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
                      const SizedBox(height: 14),
                      _searchField(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Nenhum cliente encontrado.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return _clientCard(context, c);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pink,
        foregroundColor: _white,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);

          final client = Client(
            id: const Uuid().v4(),
            name: '',
            phoneE164: '+55',
            notes: null,
            createdAt: DateTime.now(),
            birthDate: null,
          );

          final result = await Navigator.push<Client?>(
            context,
            MaterialPageRoute(
              builder: (_) => ClientFormPage(client: client),
            ),
          );

          if (!mounted) return;

          if (result != null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Cliente salvo com sucesso!'),
              ),
            );
          }
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Novo cliente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}