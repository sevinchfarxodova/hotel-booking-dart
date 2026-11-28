import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api_cache.dart';
import 'reservations/reservations.dart';
import 'rooms/rooms.dart';

// The four counters of GET /stats. A plain ++ is exact: Dart runs every request on one isolate.
class Stats {
  int searches = 0;
  int databaseQueries = 0;
  int cacheHits = 0;
  int cacheMisses = 0;

  Map<String, int> toJson() => {
        'searches': searches,
        'databaseQueries': databaseQueries,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
      };
}

// Passes every call on to the real store and counts it: each call is one question to the database.
class CountingReservationStore implements ReservationStore {
  CountingReservationStore(this._store, this._stats);

  final ReservationStore _store;
  final Stats _stats;

  @override
  FutureOr<int> get count {
    _stats.databaseQueries++;
    return _store.count;
  }

  @override
  FutureOr<bool> hasOverlap(Room room, DateRange stay) {
    _stats.databaseQueries++;
    return _store.hasOverlap(room, stay);
  }

  @override
  FutureOr<void> save(Reservation reservation) {
    _stats.databaseQueries++;
    return _store.save(reservation);
  }

  @override
  FutureOr<Reservation?> find(String id) {
    _stats.databaseQueries++;
    return _store.find(id);
  }

  @override
  FutureOr<int> countConfirmed(Room room, DateRange stay) {
    _stats.databaseQueries++;
    return _store.countConfirmed(room, stay);
  }
}

typedef UnitOfWork = Future<Response> Function(
  Future<Response> Function(BookingService service) work,
);

Handler createApi(
  List<Room> rooms,
  UnitOfWork unitOfWork,
  Stats stats, [
  AvailabilityCache? cache,
]) {
  final router = Router();

  Response jsonResponse(int status, Object body) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );

  // GET /stats
  router.get('/stats', (Request request) {
    return jsonResponse(200, stats.toJson());
  });

  // GET /rooms/available?checkIn=YYYY-MM-DD&checkOut=YYYY-MM-DD
  router.get('/rooms/available', (Request request) async {
    final checkIn = request.url.queryParameters['checkIn'];
    final checkOut = request.url.queryParameters['checkOut'];
    if (checkIn == null || checkOut == null) {
      return jsonResponse(400, {'error': 'checkIn and checkOut are required'});
    }

    final DateRange stay;
    try {
      stay = DateRange.parse(checkIn, checkOut);
    } catch (e) {
      return jsonResponse(400, {'error': 'Invalid date range: $e'});
    }

    stats.searches++;

    if (cache != null) {
      final cached = await cache.get(stay.checkInIso, stay.checkOutIso);
      if (cached != null) {
        stats.cacheHits++;
        return jsonResponse(200, cached.map((r) => r.toJson()).toList());
      }
      stats.cacheMisses++;
    }

    return unitOfWork((service) async {
      final available = await service.availableRooms(stay);
      if (cache != null) {
        await cache.set(stay.checkInIso, stay.checkOutIso, available);
      }
      return jsonResponse(200, available.map((r) => r.toJson()).toList());
    });
  });

  // POST /reservations
  router.post('/reservations', (Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return jsonResponse(400, {'error': 'Invalid JSON'});
    }

    final roomId = body['roomId'] as String?;
    final guestName = body['guestName'] as String?;
    final guestEmail = body['guestEmail'] as String?;
    final checkIn = body['checkIn'] as String?;
    final checkOut = body['checkOut'] as String?;

    if (roomId == null ||
        guestName == null ||
        guestEmail == null ||
        checkIn == null ||
        checkOut == null) {
      return jsonResponse(400, {'error': 'Missing required reservation fields'});
    }

    final DateRange stay;
    try {
      stay = DateRange.parse(checkIn, checkOut);
    } catch (e) {
      return jsonResponse(400, {'error': 'Invalid date range: $e'});
    }

    final response = await unitOfWork((service) async {
      final result = await service.book(
        roomId,
        Guest(name: guestName, email: guestEmail),
        stay,
      );
      return switch (result) {
        BookingConfirmed(:final reservation) => jsonResponse(201, reservation.toJson()),
        RoomUnavailable() => jsonResponse(409, {'error': 'Room $roomId is not available'}),
        UnknownRoom() => jsonResponse(404, {'error': 'Unknown room $roomId'}),
      };
    });

    // Step 6: Invalidate cache after database commit succeeds.
    if (response.statusCode == 201 && cache != null) {
      await cache.invalidate();
    }
    return response;
  });

  // DELETE /reservations/<id>
  router.delete('/reservations/<id>', (Request request, String id) async {
    final response = await unitOfWork((service) async {
      final cancelled = await service.cancel(id);
      if (!cancelled) {
        return jsonResponse(404, {'error': 'Reservation $id not found'});
      }
      return Response(204);
    });

    // Step 6: Invalidate cache after cancellation commits.
    if (response.statusCode == 204 && cache != null) {
      await cache.invalidate();
    }
    return response;
  });

  return router.call;
}
