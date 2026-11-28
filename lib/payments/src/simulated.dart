enum PaymentStatus { authorized, declined }

abstract interface class PaymentService {
  PaymentStatus charge(String guestEmail, int amount);
}

class SimulatedPaymentService implements PaymentService {
  @override
  PaymentStatus charge(String guestEmail, int amount) {
    return amount > 0 ? PaymentStatus.authorized : PaymentStatus.declined;
  }
}
