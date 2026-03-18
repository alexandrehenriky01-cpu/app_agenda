import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../appointments/presentation/agenda_page.dart';
import '../data/license_providers.dart';
import '../domain/license_status.dart';
import 'license_activation_page.dart';

class LicenseGatePage extends ConsumerWidget {
  const LicenseGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseStatusProvider);

    return licenseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Scaffold(
        body: Center(child: Text('Erro ao verificar licença.')),
      ),
      data: (status) {
        if (status.isActive) {
          return const AgendaPage();
        }

        return _ExpiredPage(status: status);
      },
    );
  }
}

class _ExpiredPage extends ConsumerWidget {
  final LicenseStatus status;

  const _ExpiredPage({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'Período de teste encerrado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Seu período de teste de 30 dias expirou. '
                  'Para continuar utilizando o aplicativo, ative sua licença com uma chave válida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LicenseActivationPage(),
                        ),
                      );

                      if (result == true) {
                        ref.invalidate(licenseStatusProvider);
                      }
                    },
                    child: const Text('Inserir chave de ativação'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}