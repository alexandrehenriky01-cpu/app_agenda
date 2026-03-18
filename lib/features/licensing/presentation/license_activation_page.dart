import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/license_providers.dart';

class LicenseActivationPage extends ConsumerStatefulWidget {
  const LicenseActivationPage({super.key});

  @override
  ConsumerState<LicenseActivationPage> createState() =>
      _LicenseActivationPageState();
}

class _LicenseActivationPageState
    extends ConsumerState<LicenseActivationPage> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _deviceNameController =
      TextEditingController(text: 'Meu aparelho');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(licenseServiceProvider);
      final ok = await service.activateWithKey(
        key: _keyController.text,
        deviceName: _deviceNameController.text,
      );

      if (!mounted) return;

      if (ok) {
        ref.invalidate(licenseStatusProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aparelho ativado com sucesso.'),
          ),
        );

        context.go('/agenda');
      } else {
        setState(() {
          _error = 'Chave inválida, inativa ou limite de aparelhos atingido.';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Não foi possível validar a chave.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final licenseAsync = ref.watch(licenseStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ativação do aplicativo'),
        centerTitle: true,
      ),
      body: licenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildContent(),
        data: (license) => _buildContent(
          remainingTrialDays: license.isTrial ? license.remainingTrialDays : null,
        ),
      ),
    );
  }

  Widget _buildContent({int? remainingTrialDays}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.devices_rounded, size: 72),
              const SizedBox(height: 20),
              const Text(
                'Ative este aparelho',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                remainingTrialDays != null && remainingTrialDays > 0
                    ? 'Seu período de teste ainda está ativo por $remainingTrialDays dia(s). Você já pode ativar este aparelho.'
                    : 'Seu período de teste expirou. Digite a chave para ativar este aparelho.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do aparelho',
                  hintText: 'Ex: Celular João',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Chave de ativação',
                  hintText: 'EX: AURYA-2026-0001',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _activate,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ativar aparelho'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}