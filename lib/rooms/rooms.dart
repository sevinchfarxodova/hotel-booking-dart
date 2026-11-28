/// Rooms: the inventory offered for sale. This is the public module contract.
library;

import 'dart:async';

class Room {
  const Room(this.number, this.type);

  final String number;
  final String type;

  @override
  bool operator ==(Object other) => other is Room && other.number == number;

  @override
  int get hashCode => number.hashCode;
}

/// Public promise for reading the hotel's room inventory.
/// PostgreSQL may answer asynchronously; an in-memory catalog can answer now.
abstract interface class RoomCatalog {
  FutureOr<List<Room>> all();
}
