import '../rooms.dart';

/// List-backed catalog. Only application wiring and tests should construct it.
class InMemoryRoomCatalog implements RoomCatalog {
  InMemoryRoomCatalog(List<Room> rooms) : _rooms = List<Room>.unmodifiable(rooms);

  final List<Room> _rooms;

  @override
  List<Room> all() => _rooms;
}
