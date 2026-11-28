// Four API behavior tests using the in-memory store; these run without Docker.
import 'dart:async';
import 'dart:convert';

import 'package:hotel_booking/api.dart';
import 'package:hotel_booking/notifications/src/email.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/reservations/src/store.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final hotelRooms = [Room('R7', 'Standard'), Room('R8', 'Deluxe')];
const search = '/rooms/availability?checkIn=2026-11-12&checkOut=2026-11-14';
const maya = {
  'guestName': 'Maya',
  'guestEmail': 'maya@example.com',
  'room': 'R7',
  'checkIn': '2026-11-12',
  'checkOut': '2026-11-14',
};
const omar = {
  'guestName': 'Omar',
  'guestEmail': 'omar@example.com',
  'room': 'R7',
  'checkIn': '2026-11-13',
  'checkOut': '2026-11-15',
};

Handler newApp() {
  final service = BookingService(
      hotelRooms, InMemoryReservationStore(), EmailNotificationSender());
  Future<T> unitOfWork<T>(FutureOr<T> Function(BookingService service) work) async =>
      await work(service);
  return createApi(hotelRooms, unitOfWork);
}

Future<Response> send(Handler app, String method, String path, [Object? body]) async =>
    await app(Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {'content-type': 'application/json'},
      ));

void main() {
  test('search answers 200 with the free rooms', () async {
    final response = await send(newApp(), 'GET', search);
    expect(response.statusCode, 200);
    expect(await response.readAsString(),
        '{"checkIn":"2026-11-12","checkOut":"2026-11-14","rooms":[{"number":"R7","type":"Standard"},{"number":"R8","type":"Deluxe"}],"next":null}');
  });

  test('booking answers 201, then 409 for a shared night', () async {
    final app = newApp();
    final first = await send(app, 'POST', '/reservations', maya);
    expect(first.statusCode, 201);
    expect(await first.readAsString(),
        '{"id":"R101","status":"Confirmed","notificationFailed":false}');
    final second = await send(app, 'POST', '/reservations', omar);
    expect(second.statusCode, 409);
    expect(jsonDecode(await second.readAsString())['title'], 'Unavailable');
  });

  test('wrong dates answer 400 with problem details', () async {
    final response = await send(
        newApp(), 'POST', '/reservations', {...maya, 'checkOut': '2026-11-12'});
    expect(response.statusCode, 400);
    expect(response.headers['content-type'], 'application/problem+json');
    expect(await response.readAsString(),
        '{"title":"InvalidDates","status":400,"detail":"checkOut must be after checkIn."}');
  });

  test('cancel answers 204, then 404', () async {
    final app = newApp();
    await send(app, 'POST', '/reservations', maya);
    expect((await send(app, 'DELETE', '/reservations/R101')).statusCode, 204);
    final second = await send(app, 'DELETE', '/reservations/R101');
    expect(second.statusCode, 404);
    expect(jsonDecode(await second.readAsString())['title'], 'NotFound');
  });
}
