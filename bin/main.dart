import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:redis/redis.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:hotel_booking/api.dart';
import 'package:hotel_booking/api_cache.dart';
import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/rooms/rooms.dart';

Future<void> main() async {
  await runApi();
}

Future<void> runApi() async {
  // The wiring for the web app: PostgreSQL from docker-compose.yml (HOTEL_DB_PORT only if 5432 is taken).
  final dbPort = int.parse(Platform.environment['HOTEL_DB_PORT'] ?? '5432');
  final pool = Pool.withEndpoints([
    Endpoint(
      host: 'localhost',
      port: dbPort,
      database: 'hotel',
      username: 'hotel',
      password: 'hotel',
    ),
  ], settings: PoolSettings(sslMode: SslMode.disable));

  final rooms = await PostgresRoomCatalog(pool).all();
  final email = EmailNotificationSender();
  final stats = Stats();

  // Connect to Redis cache from docker-compose.yml (HOTEL_REDIS_PORT only if 6379 is taken).
  AvailabilityCache? cache;
  if (Platform.environment['HOTEL_NO_CACHE'] != '1') {
    final redisPort = int.parse(Platform.environment['HOTEL_REDIS_PORT'] ?? '6379');
    final conn = RedisConnection();
    final command = await conn.connect('localhost', redisPort);
    cache = RedisAvailabilityCache(command, ttlSeconds: 30);
  }

  // One request: a fresh store in a transaction, counted for GET /stats; save what changed at the end.
  Future<Response> unitOfWork(
    Future<Response> Function(BookingService service) work,
  ) {
    return pool.runTx((session) async {
      final store = PostgresReservationStore(session, rooms);
      final counting = CountingReservationStore(store, stats);
      final response = await work(BookingService(rooms, counting, email));
      await store.saveChanges();
      return response;
    });
  }

  final handler = createApi(rooms, unitOfWork, stats, cache);
  final server = await shelf_io.serve(handler, 'localhost', 5080);
  print('Listening on http://${server.address.host}:${server.port}');
}
