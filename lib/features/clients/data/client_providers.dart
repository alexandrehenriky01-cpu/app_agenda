import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/client.dart';
import 'client_repository.dart';

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E e) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// Lista todos os clientes (stream)
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).watchAll();
});

/// Busca 1 cliente pelo ID, a partir da lista já carregada
/// (retorna Client? direto, sem AsyncValue)
final clientByIdProvider = Provider.family<Client?, String>((ref, id) {
  final clientsAsync = ref.watch(clientsStreamProvider);

  return clientsAsync.maybeWhen(
    data: (list) => list.firstWhereOrNull((c) => c.id == id),
    orElse: () => null,
  );
});

/// ✅ Aniversariantes do dia (pela data local do aparelho)
final birthdayClientsTodayProvider = Provider<List<Client>>((ref) {
  final clientsAsync = ref.watch(clientsStreamProvider);
  final now = DateTime.now();
  final m = now.month;
  final d = now.day;

  return clientsAsync.maybeWhen(
    data: (list) {
      final result = list.where((c) {
        final b = c.birthDate;
        if (b == null) return false;
        return b.month == m && b.day == d;
      }).toList();

      // ordena por nome
      result.sort((a, b) => a.name.compareTo(b.name));
      return result;
    },
    orElse: () => <Client>[],
  );
});

/// Opcional: contador pronto
final birthdayCountTodayProvider = Provider<int>((ref) {
  return ref.watch(birthdayClientsTodayProvider).length;
});