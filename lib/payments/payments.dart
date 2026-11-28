/// Payments: deposit outcomes. This is the public module contract.
library;

enum PaymentStatus { paid, declined }

/// Booking will use this port when the deposit workflow is introduced in P17.
abstract interface class PaymentService {
  PaymentStatus takeDeposit(String reservationId, int amountCents);
}
