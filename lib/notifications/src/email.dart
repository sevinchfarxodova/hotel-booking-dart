import '../notifications.dart';

/// Simulates email delivery without network access.
class EmailNotificationSender implements NotificationSender {
  int sent = 0;

  @override
  void sendConfirmation(Confirmation confirmation) => sent++;
}
