import 'package:postgres/postgres.dart';

import '../rooms.dart';

/// Reads room inventory from the Rooms-owned PostgreSQL table.
class PostgresRoomCatalog implements RoomCatalog {
  PostgresRoomCatalog(this._pool);

  final Pool<void> _pool;

  @override
  Future<List<Room>> all() async {
    final rows = await _pool.execute('SELECT number, type FROM rooms ORDER BY number');
    return [for (final row in rows) Room(row[0] as String, row[1] as String)];
  }
}
