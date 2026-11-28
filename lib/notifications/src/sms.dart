import '../notifications.dart';

/// Simulates SMS delivery without network access.
class SmsNotificationSender implements NotificationSender {
  int sent = 0;

  @override
  void sendConfirmation(Confirmation confirmation) => sent++;
}
