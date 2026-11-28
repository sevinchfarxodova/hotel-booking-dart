/// Notifications: confirmation delivery. This is the public module contract.
library;

/// The small message crossing from Reservations to Notifications.
/// The full Reservation object and its storage stay inside Reservations.
class Confirmation {
  const Confirmation(
    this.reservationId,
    this.guestEmail,
    this.roomNumber,
    this.checkIn,
    this.checkOut,
  );

  final String reservationId;
  final String guestEmail;
  final String roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
}

abstract interface class NotificationSender {
  void sendConfirmation(Confirmation confirmation);
}
