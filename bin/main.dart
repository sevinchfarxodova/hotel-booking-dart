// P07 · P06 modules behind an HTTP API, with reservations stored in PostgreSQL.
// dart run bin/main.dart          -> API on http://localhost:5080 (start Docker first)
// dart run bin/main.dart --demo   -> P06 demo using in-memory stores
// dart run bin/main.dart --race   -> the deliberate race demonstration
import 'dart:async';
import 'dart:io';

import 'package:hotel_booking/api.dart';
import 'package:hotel_booking/notifications/src/email.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/postgres_store.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:hotel_booking/rooms/src/catalog.dart';
import 'package:hotel_booking/rooms/src/postgres_catalog.dart';
import 'package:postgres/postgres.dart' show Endpoint, Pool, PoolSettings, SslMode;
import 'package:shelf/shelf_io.dart';

final r7 = Room('R7', 'Standard');
final r8 = Room('R8', 'Deluxe');
const maya = Guest('Maya', 'maya@example.com');
const omar = Guest('Omar', 'omar@example.com');
const nora = Guest('Nora', 'nora@example.com');
final inMemoryCatalog = InMemoryRoomCatalog([r7, r8]);

DateRange nov(int checkIn, int checkOut) =>
    DateRange(DateTime.utc(2026, 11, checkIn), DateTime.utc(2026, 11, checkOut));

String names(List<Room> rooms) => rooms.map((room) => room.number).join(', ');
String boolText(bool value) => value ? 'True' : 'False';

Future<void> main(List<String> args) async {
  if (args.contains('--race')) {
    await runRace();
  } else if (args.contains('--demo')) {
    await runDemo();
  } else {
    await runApi();
  }
}

Future<void> runApi() async {
  final port = int.parse(Platform.environment['HOTEL_DB_PORT'] ?? '5432');
  final pool = Pool.withEndpoints([
    Endpoint(
      host: 'localhost',
      port: port,
      database: 'hotel',
      username: 'hotel',
      password: 'hotel',
    ),
  ], settings: PoolSettings(sslMode: SslMode.disable));

  final rooms = await PostgresRoomCatalog(pool).all();
  final email = EmailNotificationSender();

  Future<T> unitOfWork<T>(FutureOr<T> Function(BookingService service) work) async {
    final store = PostgresReservationStore(pool, rooms);
    final result = await work(BookingService(rooms, store, email));
    await store.saveChanges();
    return result;
  }

  await serve(createApi(rooms, unitOfWork), 'localhost', 5080);
  print('Listening on http://localhost:5080');
}

Future<void> runDemo() async {
  final store = InMemoryReservationStore();
  final email = EmailNotificationSender();
  final service = BookingService(inMemoryCatalog.all(), store, email);

  print('Free rooms 12-14 Nov: ${names(await service.findFreeRooms(nov(12, 14)))}');
  print('Maya books R7 12-14 Nov: ${await service.reserve(maya, r7, nov(12, 14))}');
  print('Omar books R7 13-15 Nov: ${await service.reserve(omar, r7, nov(13, 15))}');
  print('Nora books R7 14-16 Nov: ${await service.reserve(nora, r7, nov(14, 16))}');
  print('Omar books R8 15-15 Nov: ${await service.reserve(omar, r8, nov(15, 15))}');
  print('Free rooms 12-14 Nov: ${names(await service.findFreeRooms(nov(12, 14)))}');
  print('Maya cancels R101: ${boolText(await service.cancel('R101'))}');
  print('Free rooms 12-14 Nov: ${names(await service.findFreeRooms(nov(12, 14)))}');
  print('Confirmation emails sent: ${email.sent}');
}

Future<void> runRace() async {
  final store = InMemoryReservationStore();
  final service = BookingService(
    inMemoryCatalog.all(),
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
