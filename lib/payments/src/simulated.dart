import '../payments.dart';

/// Simulated payment adapter: no card and no network.
class SimulatedPaymentService implements PaymentService {
  @override
  PaymentStatus takeDeposit(String reservationId, int amountCents) =>
      amountCents > 0 ? PaymentStatus.paid : PaymentStatus.declined;
}
