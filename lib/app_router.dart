import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/appointments/presentation/agenda_page.dart';
import 'features/clients/presentation/clients_list_page.dart';
import 'features/finance/presentation/finance_page.dart';
import 'features/licensing/data/license_providers.dart';
import 'features/licensing/presentation/license_activation_page.dart';
import 'features/services/presentation/services_list_page.dart';
import 'features/settings/presentation/about_company_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/agenda',
    redirect: (context, state) async {
      final license = await ref.read(licenseServiceProvider).getLicenseStatus();

      final currentPath = state.uri.path;
      final isGoingToActivation = currentPath == '/activate';

      if (!license.isActive && !isGoingToActivation) {
        return '/activate';
      }

      if (license.isActive && isGoingToActivation) {
        return '/agenda';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/agenda',
            name: 'agenda',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AgendaPage(),
            ),
          ),
          GoRoute(
            path: '/clients',
            name: 'clients',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ClientsListPage(),
            ),
          ),
          GoRoute(
            path: '/services',
            name: 'services',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ServicesListPage(),
            ),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FinancePage(),
            ),
          ),
          GoRoute(
            path: '/about-company',
            name: 'about-company',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AboutCompanyPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/activate',
        name: 'activate',
        builder: (context, state) => const LicenseActivationPage(),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  int _locationToIndex(String location) {
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/services')) return 2;
    if (location.startsWith('/finance')) return 3;
    if (location.startsWith('/about-company')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/agenda');
        break;
      case 1:
        context.go('/clients');
        break;
      case 2:
        context.go('/services');
        break;
      case 3:
        context.go('/finance');
        break;
      case 4:
        context.go('/about-company');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services),
            label: 'Serviços',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Financeiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'Sobre',
          ),
        ],
      ),
    );
  }
}