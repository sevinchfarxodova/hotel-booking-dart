import 'dart:convert';
import 'package:hotel_booking/api.dart';
import 'package:hotel_booking/api_cache.dart';
import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late List<Room> rooms;
  late InMemoryReservationStore baseStore;
  late Stats stats;
  late InMemoryAvailabilityCache cache;
  late Handler handler;

  setUp(() {
    rooms = InMemoryRoomCatalog().all();
    baseStore = InMemoryReservationStore();
    stats = Stats();
    cache = InMemoryAvailabilityCache();
    handler = createApi(
      rooms,
      (work) => work(BookingService(
        rooms,
        CountingReservationStore(baseStore, stats),
        EmailNotificationSender(),
      )),
      stats,
      cache,
    );
  });

  test('GET /stats starts at zero and counts uncached search queries', () async {
    final uncachedHandler = createApi(
      rooms,
      (work) => work(BookingService(
        rooms,
        CountingReservationStore(baseStore, stats),
        EmailNotificationSender(),
      )),
      stats,
    );

    final initial = await uncachedHandler(Request('GET', Uri.parse('http://localhost/stats')));
    expect(jsonDecode(await initial.readAsString()), {
      'searches': 0,
      'databaseQueries': 0,
      'cacheHits': 0,
      'cacheMisses': 0,
    });

    await uncachedHandler(
      Request('GET', Uri.parse('http://localhost/rooms/available?checkIn=2026-11-12&checkOut=2026-11-14')),
    );

    final after = await uncachedHandler(Request('GET', Uri.parse('http://localhost/stats')));
    expect(jsonDecode(await after.readAsString()), {
      'searches': 1,
      'databaseQueries': 2,
      'cacheHits': 0,
      'cacheMisses': 0,
    });
  });

  test('Cache Test 1: second identical search is served from cache without hitting database', () async {
    final uri = Uri.parse('http://localhost/rooms/available?checkIn=2026-11-12&checkOut=2026-11-14');

    final res1 = await handler(Request('GET', uri));
    expect(res1.statusCode, 200);
    expect(stats.searches, 1);
    expect(stats.cacheMisses, 1);
    expect(stats.cacheHits, 0);
    expect(stats.databaseQueries, 2);

    final res2 = await handler(Request('GET', uri));
    expect(res2.statusCode, 200);
    expect(stats.searches, 2);
    expect(stats.cacheMisses, 1);
    expect(stats.cacheHits, 1);
    expect(stats.databaseQueries, 2); // No extra DB queries!
  });

  test('Cache Test 2: POST /reservations and DELETE /reservations invalidate cached availability', () async {
    final searchUri =
        Uri.parse('http://localhost/rooms/available?checkIn=2026-11-12&checkOut=2026-11-14');

    // 1. Prime the cache (R7 and R8 available).
    final initialSearch = await handler(Request('GET', searchUri));
    final initialRooms = jsonDecode(await initialSearch.readAsString()) as List;
    expect(initialRooms.map((r) => r['id']), containsAll(['R7', 'R8']));

    // 2. Book R7 -> invalidates cache.
    final bookRes = await handler(Request(
      'POST',
      Uri.parse('http://localhost/reservations'),
      body: jsonEncode({
        'roomId': 'R7',
        'guestName': 'Maya',
        'guestEmail': 'maya@example.com',
        'checkIn': '2026-11-12',
        'checkOut': '2026-11-14',
      }),
    ));
    expect(bookRes.statusCode, 201);
    final reservationId = (jsonDecode(await bookRes.readAsString()) as Map)['id'] as String;

    // 3. Next search misses stale cache and returns only R8.
    final afterBookSearch = await handler(Request('GET', searchUri));
    final afterBookRooms = jsonDecode(await afterBookSearch.readAsString()) as List;
    expect(afterBookRooms.map((r) => r['id']), equals(['R8']));
    expect(stats.cacheMisses, 2);

    // 4. Cancel reservation -> invalidates cache again.
    final cancelRes = await handler(
      Request('DELETE', Uri.parse('http://localhost/reservations/$reservationId')),
    );
    expect(cancelRes.statusCode, 204);

    // 5. Search after cancel reflects R7 available again.
    final afterCancelSearch = await handler(Request('GET', searchUri));
    final afterCancelRooms = jsonDecode(await afterCancelSearch.readAsString()) as List;
    expect(afterCancelRooms.map((r) => r['id']), containsAll(['R7', 'R8']));
    expect(stats.cacheMisses, 3);
  });
}
