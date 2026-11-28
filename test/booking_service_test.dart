// The eight P04 behaviour checks; only the module imports and notification message changed.
import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/notifications/src/sms.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:test/test.dart';

final r7 = Room('R7', 'Standard');
final r8 = Room('R8', 'Deluxe');
const maya = Guest('Maya', 'maya@example.com');
const omar = Guest('Omar', 'omar@example.com');
const nora = Guest('Nora', 'nora@example.com');

DateRange nov(int checkIn, int checkOut) =>
    DateRange(DateTime.utc(2026, 11, checkIn), DateTime.utc(2026, 11, checkOut));

class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.fail = false});

  final bool fail;
  final List<String> sent = [];

  @override
  void sendConfirmation(Confirmation confirmation) {
    if (fail) throw StateError('The mail server is down.');
    sent.add(confirmation.reservationId);
  }
}

({BookingService service, InMemoryReservationStore store, FakeNotificationSender sender})
    newService({bool failingSender = false}) {
  final store = InMemoryReservationStore();
  final sender = FakeNotificationSender(fail: failingSender);
  return (
    service: BookingService([r7, r8], store, sender),
    store: store,
    sender: sender,
  );
}

void main() {
  test('Maya gets R7 when it is free', () async {
    final fixture = newService();
    expect('${await fixture.service.reserve(maya, r7, nov(12, 14))}', 'Accepted R101');
  });

  test('Omar is refused when a night is shared', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('${await fixture.service.reserve(omar, r7, nov(13, 15))}', 'Unavailable');
    expect(fixture.store.count, 1);
  });

  test('Nora can arrive on the day Maya leaves', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('${await fixture.service.reserve(nora, r7, nov(14, 16))}', 'Accepted R102');
  });

  test('check-out must be after check-in', () async {
    final fixture = newService();
    expect('${await fixture.service.reserve(omar, r8, nov(15, 15))}', 'InvalidDates');
    expect(fixture.store.count, 0);
  });

  test('cancelling frees the room again', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    expect(fixture.service.cancel('R101'), isTrue);
    expect(fixture.service.findFreeRooms(nov(12, 14)), contains(r7));
  });

  test('one confirmation per accepted booking', () async {
    final fixture = newService();
    await fixture.service.reserve(maya, r7, nov(12, 14));
    await fixture.service.reserve(omar, r7, nov(13, 15));
    await fixture.service.reserve(nora, r7, nov(14, 16));
    expect(fixture.sender.sent, ['R101', 'R102']);
  });

  test('a failed confirmation keeps the booking', () async {
    final fixture = newService(failingSender: true);
    final result = await fixture.service.reserve(maya, r7, nov(12, 14));
    expect('$result', 'Accepted R101');
    expect(result.notificationFailed, isTrue);
    expect(fixture.store.count, 1);
    expect(fixture.store.find('R101')?.status, ReservationStatus.confirmed);
    expect(fixture.service.findFreeRooms(nov(12, 14)), isNot(contains(r7)));
  });

  test('SMS confirmations need no change to BookingService', () async {
    final sms = SmsNotificationSender();
    final service = BookingService([r7, r8], InMemoryReservationStore(), sms);
    await service.reserve(maya, r7, nov(12, 14));
    expect(sms.sent, 1);
  });
}
