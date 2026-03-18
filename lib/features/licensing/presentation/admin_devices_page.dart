import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/license_providers.dart';
import '../domain/licensed_device.dart';

class AdminDevicesPage extends ConsumerWidget {
  final String keyDocId;
  final String licenseKey;

  const AdminDevicesPage({
    super.key,
    required this.keyDocId,
    required this.licenseKey,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    LicensedDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remover aparelho'),
            content: Text(
              'Deseja remover o aparelho "${device.deviceName}"?\n\n'
              'Ele perderá o acesso até ser ativado novamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(licenseServiceProvider).removeDevice(
          keyDocId: keyDocId,
          installationId: device.installationId,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesByKeyProvider(keyDocId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Dispositivos - $licenseKey'),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro ao carregar dispositivos: $e'),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Text('Nenhum dispositivo ativo encontrado.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = devices[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.smartphone),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover aparelho',
                            onPressed: () => _confirmRemove(context, ref, device),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'ID do aparelho',
                        value: device.installationId,
                      ),
                      _InfoRow(
                        label: 'Ativado em',
                        value: _formatDate(device.activatedAt),
                      ),
                      _InfoRow(
                        label: 'Último acesso',
                        value: _formatDate(device.lastAccessAt),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}