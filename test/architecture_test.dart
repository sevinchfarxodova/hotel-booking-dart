import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('BookingService does not import api_cache or redis', () {
    final bookingFile = File('lib/reservations/src/booking.dart');
    final source = bookingFile.readAsStringSync();
    expect(source.contains('api_cache.dart'), isFalse);
    expect(source.contains('package:redis'), isFalse);
  });
}
