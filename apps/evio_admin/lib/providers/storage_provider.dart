import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

/// Provider del servicio de Storage
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(SupabaseService.client);
});
