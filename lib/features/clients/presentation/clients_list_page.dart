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
        content: Text(
          'Tem certeza que deseja excluir "${client.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

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
        SnackBar(
          content: Text('Erro ao excluir: $e'),
        ),
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

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou telefone…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                setState(() => _query = v.trim().toLowerCase());
              },
            ),
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

            final phoneMatch = qDigits.isEmpty ? false : phoneDigits.contains(qDigits);

            return nameMatch || phoneMatch;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text('Nenhum cliente encontrado.'),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = filtered[i];

              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.phoneE164),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.person_add),
      ),
    );
  }
}