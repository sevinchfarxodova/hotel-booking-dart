import 'dart:async';
import 'dart:convert';
import 'package:redis/redis.dart';
import 'rooms/rooms.dart';

/// Cache-aside store for room availability searches.
/// Key format: availability:v{version}:{checkIn}:{checkOut}
/// TTL: 30 seconds.
abstract interface class AvailabilityCache {
  Future<List<Room>?> get(String checkIn, String checkOut);
  Future<void> set(String checkIn, String checkOut, List<Room> rooms);
  Future<void> invalidate();
}

/// Redis-backed implementation with versioned keys and 30-second TTL.
class RedisAvailabilityCache implements AvailabilityCache {
  RedisAvailabilityCache(this._command, {this.ttlSeconds = 30});

  final Command _command;
  final int ttlSeconds;
  static const String _versionKey = 'availability:version';

  Future<int> _currentVersion() async {
    final raw = await _command.send_object(['GET', _versionKey]);
    if (raw == null) {
      await _command.send_object(['SETNX', _versionKey, '1']);
      return 1;
    }
    return int.tryParse(raw.toString()) ?? 1;
  }

  Future<String> _buildKey(String checkIn, String checkOut) async {
    final version = await _currentVersion();
    return 'availability:v$version:$checkIn:$checkOut';
  }

  @override
  Future<List<Room>?> get(String checkIn, String checkOut) async {
    final key = await _buildKey(checkIn, checkOut);
    final raw = await _command.send_object(['GET', key]);
    if (raw == null) return null;
    final decoded = jsonDecode(raw.toString()) as List<dynamic>;
    return decoded
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> set(String checkIn, String checkOut, List<Room> rooms) async {
    final key = await _buildKey(checkIn, checkOut);
    final payload = jsonEncode(rooms.map((r) => r.toJson()).toList());
    await _command.send_object(['SET', key, payload, 'EX', ttlSeconds.toString()]);
  }

  @override
  Future<void> invalidate() async {
    await _command.send_object(['INCR', _versionKey]);
  }
}

/// In-memory cache implementation for fast unit/API tests without a live Redis server.
class InMemoryAvailabilityCache implements AvailabilityCache {
  InMemoryAvailabilityCache({this.ttl = const Duration(seconds: 30)});

  final Duration ttl;
  int _version = 1;
  final Map<String, ({List<Room> rooms, DateTime expiresAt})> _entries = {};

  String _key(String checkIn, String checkOut) =>
      'availability:v$_version:$checkIn:$checkOut';

  @override
  Future<List<Room>?> get(String checkIn, String checkOut) async {
    final key = _key(checkIn, checkOut);
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.rooms;
  }

  @override
  Future<void> set(String checkIn, String checkOut, List<Room> rooms) async {
    final key = _key(checkIn, checkOut);
    _entries[key] = (
      rooms: List<Room>.unmodifiable(rooms),
      expiresAt: DateTime.now().add(ttl),
    );
  }

  @override
  Future<void> invalidate() async {
    _version++;
  }
}
