/// HTTP endpoints that adapt requests to public booking contracts.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'reservations/reservations.dart';
import 'rooms/rooms.dart';

typedef UnitOfWork = Future<T> Function<T>(
    FutureOr<T> Function(BookingService service) work);

const fields = ['guestName', 'guestEmail', 'room', 'checkIn', 'checkOut'];
const bodyDetail =
    'The body must be JSON with guestName, guestEmail, room, checkIn and checkOut.';
const dateDetail = 'checkIn and checkOut must be dates such as 2026-11-12.';
final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

Handler createApi(List<Room> rooms, UnitOfWork unitOfWork) {
  final router = Router();

  router.get('/openapi.yaml', (Request request) {
    final contract = File('docs/openapi.yaml');
    if (!contract.existsSync()) {
      return Response(500, body: 'API contract file was not found.');
    }
    return Response.ok(contract.readAsStringSync(),
        headers: {'content-type': 'application/yaml'});
  });

  router.get('/rooms/availability', (Request request) async {
    final query = request.url.queryParameters;
    final checkInText = query['checkIn'];
    final checkOutText = query['checkOut'];
    final checkIn = parseDate(checkInText);
    final checkOut = parseDate(checkOutText);
    if (checkIn == null || checkOut == null) {
      return problem(400, 'InvalidDates', dateDetail);
    }
    final stay = DateRange(checkIn, checkOut);
    if (!stay.isValid()) {
      return problem(400, 'InvalidDates', 'checkOut must be after checkIn.');
    }
    final limitText = query['limit'] ?? '20';
    final limit = int.tryParse(limitText);
    if (!RegExp(r'^[0-9]{1,3}$').hasMatch(limitText) || limit == null || limit < 1 || limit > 100) {
      return problem(400, 'InvalidRequest', 'limit must be a whole number from 1 to 100.');
    }

    final free = await unitOfWork((service) => service.findFreeRooms(stay));
    final after = query['after'] ?? '';
    final remaining = free.where((room) => room.number.compareTo(after) > 0).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final page = remaining.take(limit).toList();
    return jsonResponse(200, {
      'checkIn': checkInText,
      'checkOut': checkOutText,
      'rooms': [for (final room in page) {'number': room.number, 'type': room.type}],
      'next': remaining.length > page.length ? page.last.number : null,
    });
  });

  router.post('/reservations', (Request request) async {
    if (request.mimeType != 'application/json') {
      return problem(400, 'InvalidRequest', bodyDetail);
    }
    Object? decoded;
    try {
      decoded = jsonDecode(await request.readAsString());
    } on FormatException {
      return problem(400, 'InvalidRequest', bodyDetail);
    }
    final body = decoded is Map ? decoded : const <Object?, Object?>{};
    if (!fields.every((field) => body[field] is String && body[field] != '')) {
      return problem(400, 'InvalidRequest', bodyDetail);
    }
    final checkIn = parseDate(body['checkIn']);
    final checkOut = parseDate(body['checkOut']);
    if (checkIn == null || checkOut == null) {
      return problem(400, 'InvalidDates', dateDetail);
    }

    Room? room;
    for (final candidate in rooms) {
      if (candidate.number == body['room']) {
        room = candidate;
        break;
      }
    }
    if (room == null) {
      return problem(400, 'UnknownRoom', 'There is no room ${body['room']}.');
    }

    final guest = Guest(body['guestName'] as String, body['guestEmail'] as String);
    final result = await unitOfWork(
        (service) => service.reserve(guest, room!, DateRange(checkIn, checkOut)));
    return toHttp(result);
  });

  router.delete('/reservations/<id>', (Request request, String id) async {
    final cancelled = await unitOfWork((service) => service.cancel(id));
    if (!cancelled) {
      return problem(404, 'NotFound', 'There is no confirmed reservation $id.');
    }
    return Response(204);
  });

  return router.call;
}

DateTime? parseDate(Object? value) {
  if (value is! String || !datePattern.hasMatch(value)) return null;
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  if (parsed == null || !parsed.toIso8601String().startsWith(value)) return null;
  return parsed;
}

Response jsonResponse(int status, Object? value) => Response(
      status,
      body: jsonEncode(value),
      headers: {'content-type': 'application/json'},
    );

Response problem(int status, String title, String detail) => Response(
      status,
      body: jsonEncode({'title': title, 'status': status, 'detail': detail}),
      headers: {'content-type': 'application/problem+json'},
    );

Response toHttp(BookingResult result) {
  if (result.outcome == 'Accepted') {
    return jsonResponse(201, {
      'id': result.reservationId,
      'status': 'Confirmed',
      'notificationFailed': result.notificationFailed,
    });
  }
  if (result.outcome == 'Unavailable') {
    return problem(409, 'Unavailable',
        'The room is booked for at least one night of this stay.');
  }
  return problem(400, 'InvalidDates', 'checkOut must be after checkIn.');
}
