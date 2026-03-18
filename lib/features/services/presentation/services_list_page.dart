import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/service_repository.dart';
import '../domain/service.dart';
import 'service_form_page.dart';

class ServicesListPage extends ConsumerStatefulWidget {
  const ServicesListPage({super.key});

  @override
  ConsumerState<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends ConsumerState<ServicesListPage> {
  String _query = '';
  bool? _activeFilter; // null = todos | true = ativos | false = inativos

  // 🎨 Paleta “Studio”
  static const _pink = Color(0xFFE91E63);
  static const _rose = Color(0xFFF8BBD0);
  static const _nude = Color(0xFFFFF3F6);
  static const _ink = Color(0xFF1F1F1F);

  String _money(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir serviço?'),
        content: Text('Tem certeza que deseja excluir "$name"?'),
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

    return result == true;
  }

  Future<void> _openForm(Service service) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await nav.push<Service?>(
      MaterialPageRoute(builder: (_) => ServiceFormPage(service: service)),
    );

    if (!mounted) return;

    if (result != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Serviço salvo com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return Scaffold(
      backgroundColor: _nude,
      appBar: AppBar(
        backgroundColor: _nude,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Serviços',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _rose.withValues(alpha: 0.65)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _pink, width: 2),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _activeFilter == null,
                        onSelected: (_) => setState(() => _activeFilter = null),
                      ),
                      ChoiceChip(
                        label: const Text('Ativos'),
                        selected: _activeFilter == true,
                        onSelected: (_) => setState(() => _activeFilter = true),
                      ),
                      ChoiceChip(
                        label: const Text('Inativos'),
                        selected: _activeFilter == false,
                        onSelected: (_) => setState(() => _activeFilter = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (services) {
          final filtered = services.where((s) {
            final qOk = _query.isEmpty || s.name.toLowerCase().contains(_query);
            final aOk = _activeFilter == null || s.isActive == _activeFilter;
            return qOk && aOk;
          }).toList();

          if (services.isEmpty) {
            return const Center(child: Text('Nenhum serviço cadastrado.'));
          }

          if (filtered.isEmpty) {
            return const Center(child: Text('Nenhum serviço encontrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10), // ✅ lint ok
            itemBuilder: (context, index) {
              final service = filtered[index];
              final statusColor =
                  service.isActive ? const Color(0xFF2E7D32) : Colors.grey;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: _rose.withValues(alpha: 0.55)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: _rose,
                    child: Icon(
                      service.isActive ? Icons.star : Icons.star_border,
                      color: _pink,
                    ),
                  ),
                  title: Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(
                          icon: Icons.timer_outlined,
                          text: '${service.durationMin} min',
                        ),
                        _Pill(
                          icon: Icons.payments_outlined,
                          text: _money(service.price),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            service.isActive ? 'Ativo' : 'Inativo',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      final ok = await _confirmDelete(context, service.name);
                      if (!ok) return;

                      try {
                        await ref
                            .read(serviceRepositoryProvider)
                            .delete(service.id);

                        if (!mounted) return;

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Serviço excluído com sucesso!'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro ao excluir: $e')),
                        );
                      }
                    },
                  ),
                  onTap: () => _openForm(service),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        onPressed: () async {
          final newService = Service(
            id: const Uuid().v4(),
            name: '',
            durationMin: 60,
            price: 0,
            isActive: true,
          );

          await _openForm(newService);
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}