import 'package:hotel_booking/notifications/notifications.dart';
import 'package:hotel_booking/reservations/reservations.dart';
import 'package:hotel_booking/rooms/rooms.dart';
import 'package:test/test.dart';

void main() {
  test('books available room and rejects overlapping stay', () async {
    final rooms = InMemoryRoomCatalog().all();
    final store = InMemoryReservationStore();
    final email = EmailNotificationSender();
    final service = BookingService(rooms, store, email);
    final stay = DateRange.parse('2026-11-12', '2026-11-14');

    final first = await service.book('R7', const Guest(name: 'Maya', email: 'maya@example.com'), stay);
    expect(first, isA<BookingConfirmed>());

    final second = await service.book('R7', const Guest(name: 'Omar', email: 'omar@example.com'), stay);
    expect(second, isA<RoomUnavailable>());
  });

  test('cancelling a reservation restores availability', () async {
    final rooms = InMemoryRoomCatalog().all();
    final store = InMemoryReservationStore();
    final service = BookingService(rooms, store, EmailNotificationSender());
    final stay = DateRange.parse('2026-11-12', '2026-11-14');

    final confirmed =
        await service.book('R7', const Guest(name: 'Maya', email: 'maya@example.com'), stay)
            as BookingConfirmed;
    expect(await service.cancel(confirmed.reservation.id), isTrue);

    final available = await service.availableRooms(stay);
    expect(available.map((r) => r.id), contains('R7'));
  });
}
