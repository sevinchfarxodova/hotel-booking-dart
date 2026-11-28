import 'package:postgres/postgres.dart';
import '../../rooms/rooms.dart';
import 'domain.dart';
import 'store.dart';

class PostgresReservationStore implements ReservationStore {
  PostgresReservationStore(this._session, this._rooms);

  final Session _session;
  final List<Room> _rooms;
  final List<Reservation> _pending = [];

  @override
  Future<int> get count async {
    final res = await _session.execute('SELECT COUNT(*) FROM reservations');
    return (res.first[0] as int) + _pending.length;
  }

  @override
  Future<bool> hasOverlap(Room room, DateRange stay) async {
    final res = await _session.execute(
      Sql.named('''
        SELECT 1 FROM reservations
        WHERE room_id = @roomId
          AND status = 'confirmed'
          AND check_in < @checkOut
          AND check_out > @checkIn
        LIMIT 1
      '''),
      parameters: {
        'roomId': room.id,
        'checkIn': stay.checkIn,
        'checkOut': stay.checkOut,
      },
    );
    return res.isNotEmpty;
  }

  @override
  Future<void> save(Reservation reservation) async {
    _pending.add(reservation);
  }

  @override
  Future<Reservation?> find(String id) async {
    for (final p in _pending) {
      if (p.id == id) return p;
    }
    final res = await _session.execute(
      Sql.named('''
        SELECT id, room_id, guest_name, guest_email, check_in, check_out, status
        FROM reservations
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
    if (res.isEmpty) return null;
    final row = res.first;
    final ci = row[4] as DateTime;
    final co = row[5] as DateTime;
    final status = row[6] == 'cancelled'
        ? ReservationStatus.cancelled
        : ReservationStatus.confirmed;
    final reservation = Reservation(
      id: row[0] as String,
      roomId: row[1] as String,
      guest: Guest(name: row[2] as String, email: row[3] as String),
      stay: DateRange(
        DateTime.utc(ci.year, ci.month, ci.day),
        DateTime.utc(co.year, co.month, co.day),
      ),
      status: status,
    );
    _pending.add(reservation);
    return reservation;
  }

  @override
  Future<int> countConfirmed(Room room, DateRange stay) async {
    final res = await _session.execute(
      Sql.named('''
        SELECT COUNT(*) FROM reservations
        WHERE room_id = @roomId
          AND status = 'confirmed'
          AND check_in < @checkOut
          AND check_out > @checkIn
      '''),
      parameters: {
        'roomId': room.id,
        'checkIn': stay.checkIn,
        'checkOut': stay.checkOut,
      },
    );
    return res.first[0] as int;
  }

  Future<void> saveChanges() async {
    for (final r in _pending) {
      await _session.execute(
        Sql.named('''
          INSERT INTO reservations (id, room_id, guest_name, guest_email, check_in, check_out, status)
          VALUES (@id, @roomId, @guestName, @guestEmail, @checkIn, @checkOut, @status)
          ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status
        '''),
        parameters: {
          'id': r.id,
          'roomId': r.roomId,
          'guestName': r.guest.name,
          'guestEmail': r.guest.email,
          'checkIn': r.stay.checkIn,
          'checkOut': r.stay.checkOut,
          'status': r.status.name,
        },
      );
    }
    _pending.clear();
  }
}
