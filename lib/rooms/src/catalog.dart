import '../rooms.dart';

/// List-backed catalog for the console demo and unit tests.
class InMemoryRoomCatalog implements RoomCatalog {
  InMemoryRoomCatalog(List<Room> rooms) : _rooms = List<Room>.unmodifiable(rooms);

  final List<Room> _rooms;

  @override
  List<Room> all() => _rooms;
}
