import 'package:hotel_booking/rooms/rooms.dart';
import 'package:postgres/postgres.dart' hide DateRange;

import 'booking.dart';
import 'domain.dart';

const confirmedOverlaps = "FROM reservations WHERE room = @room AND status = 'Confirmed' "
    'AND check_in < @checkOut:date AND @checkIn:date < check_out';

/// PostgreSQL-backed store. A fresh instance is created for each HTTP request.
/// It tracks loaded reservation statuses so cancel writes at the end of the request.
class PostgresReservationStore implements ReservationStore {
  PostgresReservationStore(this._pool, this._rooms);

  final Pool<void> _pool;
  final List<Room> _rooms;
  final Map<Reservation, ReservationStatus> _loaded = {};

  @override
  Future<int> get count => _number('SELECT count(*) FROM reservations', const {});

  @override
  Future<bool> hasOverlap(Room room, DateRange stay) async =>
      await _number('SELECT count(*) $confirmedOverlaps', _overlapValues(room, stay)) > 0;

  @override
  Future<void> save(Reservation reservation) async {
    await _pool.execute(
      Sql.named('INSERT INTO reservations '
          '(id, guest_name, guest_email, room, check_in, check_out, status) '
          'VALUES (@id, @name, @email, @room, @checkIn:date, @checkOut:date, @status)'),
      parameters: {
        'id': reservation.id,
        'name': reservation.guest.name,
        'email': reservation.guest.email,
        'room': reservation.room.number,
        'checkIn': reservation.stay.checkIn,
        'checkOut': reservation.stay.checkOut,
        'status': statusName(reservation.status),
      },
    );
  }

  @override
  Future<Reservation?> find(String id) async {
    final rows = await _pool.execute(
      Sql.named('SELECT guest_name, guest_email, room, check_in, check_out, status '
          'FROM reservations WHERE id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final guestName = row[0] as String;
    final guestEmail = row[1] as String;
    final roomNumber = row[2] as String;
    final checkIn = row[3] as DateTime;
    final checkOut = row[4] as DateTime;
    final status = row[5] as String;
    final room = _rooms.firstWhere((room) => room.number == roomNumber);
    final reservation = Reservation(
      id,
      Guest(guestName, guestEmail),
      room,
      DateRange(checkIn, checkOut),
    );
    if (status == 'Cancelled') reservation.cancel();
    _loaded[reservation] = reservation.status;
    return reservation;
  }

  @override
  Future<int> countConfirmed(Room room, DateRange stay) =>
      _number('SELECT count(*) $confirmedOverlaps', _overlapValues(room, stay));

  Future<void> saveChanges() async {
    for (final entry in _loaded.entries) {
      if (entry.key.status != entry.value) {
        await _pool.execute(
          Sql.named('UPDATE reservations SET status = @status WHERE id = @id'),
          parameters: {'status': statusName(entry.key.status), 'id': entry.key.id},
        );
      }
    }
  }

  Map<String, Object> _overlapValues(Room room, DateRange stay) => {
        'room': room.number,
        'checkIn': stay.checkIn,
        'checkOut': stay.checkOut,
      };

  Future<int> _number(String sql, Map<String, Object> values) async =>
      (await _pool.execute(Sql.named(sql), parameters: values)).first.first as int;
}

String statusName(ReservationStatus status) =>
    status == ReservationStatus.confirmed ? 'Confirmed' : 'Cancelled';
