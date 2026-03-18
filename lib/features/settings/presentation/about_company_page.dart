import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutCompanyPage extends StatelessWidget {
  const AboutCompanyPage({super.key});

  static const Color _bgTop = Color(0xFF0B1020);
  static const Color _bgBottom = Color(0xFF151A33);
  static const Color _primary = Color(0xFF62F5E8);
  static const Color _secondary = Color(0xFFB06CFF);
  static const Color _textSecondary = Color(0xFFD6D9E0);
  static const Color _cardColor = Color(0x1AFFFFFF);

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contato@auryasolucoes.com.br',
      query: 'subject=AURYA BEAUTY - Contato',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/5518996898121');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre a empresa'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _secondary.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              top: 140,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withValues(alpha: 0.14),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.12),
                            blurRadius: 30,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/logo_aurya_beauty.png',
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [_primary, _secondary],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'AURYA BEAUTY',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tecnologia e gestão inteligente para o seu studio de beleza.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoCard(
                      title: 'Sobre a empresa',
                      icon: Icons.business_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _highlightText(
                            context,
                            'Desenvolvido por AURYA SOLUÇÕES',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'O CAMINHO DA INTELIGÊNCIA',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'A AURYA SOLUÇÕES oferece soluções inovadoras para gestão, organização e crescimento de negócios. '
                            'No AURYA BEAUTY, unimos tecnologia, praticidade e eficiência para transformar a rotina do seu studio, '
                            'facilitando o controle de agenda, clientes, serviços e resultados.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _textSecondary,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Contato',
                      icon: Icons.contact_mail_rounded,
                      child: Column(
                        children: [
                          _ContactTile(
                            icon: Icons.email_rounded,
                            title: 'E-mail',
                            subtitle: 'contato@auryasolucoes.com.br',
                            onTap: _openEmail,
                          ),
                          const SizedBox(height: 12),
                          _ContactTile(
                            icon: Icons.phone_android_rounded,
                            title: 'WhatsApp',
                            subtitle: '(18) 99689-8121',
                            onTap: _openWhatsApp,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '© AURYA SOLUÇÕES',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1,
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

  Widget _highlightText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color _cardColor = Color(0x1AFFFFFF);
  static const Color _primary = Color(0xFF62F5E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primary.withValues(alpha: 0.18),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF62F5E8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _primary.withValues(alpha: 0.18),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}