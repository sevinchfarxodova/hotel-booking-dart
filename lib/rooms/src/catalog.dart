import 'dart:async';

class Room {
  const Room({
    required this.id,
    required this.type,
    required this.capacity,
    required this.pricePerNight,
  });

  final String id;
  final String type;
  final int capacity;
  final int pricePerNight;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'capacity': capacity,
        'pricePerNight': pricePerNight,
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        type: json['type'] as String,
        capacity: json['capacity'] as int,
        pricePerNight: json['pricePerNight'] as int,
      );
}

abstract interface class RoomCatalog {
  FutureOr<List<Room>> all();
  FutureOr<Room?> findById(String id);
}

class InMemoryRoomCatalog implements RoomCatalog {
  InMemoryRoomCatalog([List<Room>? initialRooms])
      : _rooms = initialRooms ??
            const [
              Room(id: 'R7', type: 'Standard Double', capacity: 2, pricePerNight: 120),
              Room(id: 'R8', type: 'Deluxe Suite', capacity: 4, pricePerNight: 220),
            ];

  final List<Room> _rooms;

  @override
  List<Room> all() => List.unmodifiable(_rooms);

  @override
  Room? findById(String id) {
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }
}
