import 'package:postgres/postgres.dart';
import 'catalog.dart';

class PostgresRoomCatalog implements RoomCatalog {
  PostgresRoomCatalog(this._pool);

  final Pool _pool;

  @override
  Future<List<Room>> all() async {
    final result = await _pool.execute(
      'SELECT id, type, capacity, price_per_night FROM rooms ORDER BY id',
    );
    return result
        .map((row) => Room(
              id: row[0] as String,
              type: row[1] as String,
              capacity: row[2] as int,
              pricePerNight: row[3] as int,
            ))
        .toList();
  }

  @override
  Future<Room?> findById(String id) async {
    final result = await _pool.execute(
      Sql.named('SELECT id, type, capacity, price_per_night FROM rooms WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return Room(
      id: row[0] as String,
      type: row[1] as String,
      capacity: row[2] as int,
      pricePerNight: row[3] as int,
    );
  }
}
