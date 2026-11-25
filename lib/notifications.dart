import 'domain.dart';

abstract interface class NotificationSender {
  void sendConfirmation(Reservation reservation);
}

// These adapters simulate delivery without making network requests.
class EmailNotificationSender implements NotificationSender {
  int sent = 0;

  @override
  void sendConfirmation(Reservation reservation) => sent++;
}

class SmsNotificationSender implements NotificationSender {
  int sent = 0;

  @override
  void sendConfirmation(Reservation reservation) => sent++;
}
