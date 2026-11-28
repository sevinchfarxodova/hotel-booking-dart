class Confirmation {
  const Confirmation({
    required this.reservationId,
    required this.recipient,
    required this.message,
  });

  final String reservationId;
  final String recipient;
  final String message;
}

abstract interface class NotificationSender {
  void send(Confirmation confirmation);
}

class EmailNotificationSender implements NotificationSender {
  final List<Confirmation> sent = [];

  @override
  void send(Confirmation confirmation) {
    sent.add(confirmation);
  }
}
