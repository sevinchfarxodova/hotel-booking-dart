import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args[0] : 'http://localhost:5080';
  final count = args.length > 1 ? int.parse(args[1]) : 1000;
  final searchUri = Uri.parse('$baseUrl/rooms/available?checkIn=2026-11-12&checkOut=2026-11-14');
  final statsUri = Uri.parse('$baseUrl/stats');

  final client = http.Client();
  try {
    final beforeRes = await client.get(statsUri);
    final beforeStats = jsonDecode(beforeRes.body) as Map<String, dynamic>;

    final latenciesMs = <double>[];
    final totalWatch = Stopwatch()..start();

    for (var i = 0; i < count; i++) {
      final sw = Stopwatch()..start();
      final res = await client.get(searchUri);
      sw.stop();
      if (res.statusCode != 200) {
        stderr.writeln('Request $i failed with status ${res.statusCode}');
        exit(1);
      }
      latenciesMs.add(sw.elapsedMicroseconds / 1000.0);
    }

    totalWatch.stop();

    final afterRes = await client.get(statsUri);
    final afterStats = jsonDecode(afterRes.body) as Map<String, dynamic>;

    latenciesMs.sort();
    final sum = latenciesMs.fold<double>(0, (a, b) => a + b);
    final avg = sum / latenciesMs.length;
    final p95Index = ((latenciesMs.length * 0.95).ceil() - 1).clamp(0, latenciesMs.length - 1);
    final p95 = latenciesMs[p95Index];

    final deltaSearches = (afterStats['searches'] as int) - (beforeStats['searches'] as int);
    final deltaQueries =
        (afterStats['databaseQueries'] as int) - (beforeStats['databaseQueries'] as int);
    final deltaHits = (afterStats['cacheHits'] as int) - (beforeStats['cacheHits'] as int);
    final deltaMisses = (afterStats['cacheMisses'] as int) - (beforeStats['cacheMisses'] as int);

    print('Requests:         $count');
    print('Total time:       ${totalWatch.elapsedMilliseconds} ms');
    print('Average latency:  ${avg.toStringAsFixed(2)} ms');
    print('p95 latency:      ${p95.toStringAsFixed(2)} ms');
    print('GET /stats delta: searches=$deltaSearches, databaseQueries=$deltaQueries, cacheHits=$deltaHits, cacheMisses=$deltaMisses');
  } finally {
    client.close();
  }
}
