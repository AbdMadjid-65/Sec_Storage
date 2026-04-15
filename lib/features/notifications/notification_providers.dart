import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final svc = ref.watch(notificationServiceProvider);
  return svc.streamUnreadCount();
});
