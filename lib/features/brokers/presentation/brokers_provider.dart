import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/broker_repository.dart';
import '../domain/broker.dart';

/// Lista de brokers para el slide del wizard. Expone `AsyncValue` para tener
/// loading / error (bloqueante si `/brokers` no existe) / data sin boilerplate.
final brokersProvider = FutureProvider.autoDispose<List<Broker>>((ref) {
  return ref.watch(brokerRepositoryProvider).getBrokers();
});
