import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ApiStatus {
  connected,
  disconnected,
}

final connectivityProvider = StreamProvider<ApiStatus>((ref) async* {
  // For now, always return connected.
  // In a real app, you would listen to network connectivity changes here.
  yield ApiStatus.connected;
});
