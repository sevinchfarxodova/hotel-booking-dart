// P06 modular-monolith wiring and runnable demonstration.
// dart run bin/main.dart          -> the normal nine-line demo
// dart run bin/main.dart --race   -> deliberately reproduces the race from P04/P05
import 'package:hotel_booking/notifications/src/email.dart';
import 'package:hotel_booking/payments/payments.dart';
import 'package:hotel_booking/payments/src/simulated.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:hotel_booking/rooms/src/catalog.dart';

final r7 = Room('R7', 'Standard');
final r8 = Room('R8', 'Deluxe');
final maya = Guest('Maya', 'maya@example.com');
final omar = Guest('Omar', 'omar@example.com');
final nora = Guest('Nora', 'nora@example.com');

// Composition root: the only application code that constructs internal adapters.
final catalog = InMemoryRoomCatalog([r7, r8]);
final paymentService = SimulatedPaymentService();

DateRange nov(int checkIn, int checkOut) =>
    DateRange(DateTime.utc(2026, 11, checkIn), DateTime.utc(2026, 11, checkOut));

String names(List<Room> rooms) => rooms.map((room) => room.number).join(', ');
String boolText(bool value) => value ? 'True' : 'False';

Future<void> main(List<String> args) async {
  // Payments is wired and ready for its later P17 workflow; it is not part of booking yet.
  if (paymentService.takeDeposit('wiring-check', 1) != PaymentStatus.paid) {
    throw StateError('The simulated payment adapter is not wired correctly.');
  }
  if (args.contains('--race')) {
    await runRace();
  } else {
    await runDemo();
  }
}

Future<void> runDemo() async {
  final store = InMemoryReservationStore();
  final email = EmailNotificationSender();
  final service = BookingService(catalog.all(), store, email);

  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Maya books R7 12-14 Nov: ${await service.reserve(maya, r7, nov(12, 14))}');
  print('Omar books R7 13-15 Nov: ${await service.reserve(omar, r7, nov(13, 15))}');
  print('Nora books R7 14-16 Nov: ${await service.reserve(nora, r7, nov(14, 16))}');
  print('Omar books R8 15-15 Nov: ${await service.reserve(omar, r8, nov(15, 15))}');
  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Maya cancels R101: ${boolText(service.cancel('R101'))}');
  print('Free rooms 12-14 Nov: ${names(service.findFreeRooms(nov(12, 14)))}');
  print('Confirmation emails sent: ${email.sent}');
}

Future<void> runRace() async {
  final store = InMemoryReservationStore();
  final service = BookingService(
    catalog.all(),
    store,
    EmailNotificationSender(),
    slowStep: const Duration(milliseconds: 500),
  );
  final stay = nov(12, 14);

  print('Maya and Omar both book R7 for 12-14 Nov at the same moment...');
  final mayaRequest = service.reserve(maya, r7, stay);
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final omarRequest = service.reserve(omar, r7, stay);
  final results = await Future.wait([mayaRequest, omarRequest]);

  print('Maya: ${results[0]}');
  print('Omar: ${results[1]}');
  final confirmed = store.countConfirmed(r7, stay);
  print('Confirmed reservations for R7 on 12-14 Nov: $confirmed');
  print(confirmed > 1
      ? 'Double booking! Both requests checked before either one saved.'
      : 'Only one guest has R7.');
}
