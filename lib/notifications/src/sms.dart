import 'email.dart';

class SmsNotificationSender implements NotificationSender {
  final List<Confirmation> sent = [];

  @override
  void send(Confirmation confirmation) {
    sent.add(confirmation);
  }
}
