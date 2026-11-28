// Three dependency rules for the four modular boundaries.
// The test reads source imports so it needs no extra architecture package.
import 'dart:io';

import 'package:test/test.dart';

typedef ModuleUse = ({String file, String target, String module, bool internal});

List<ModuleUse> importsOf(String module) {
  final uses = <ModuleUse>[];
  final folder = Directory('lib/$module');
  if (!folder.existsSync()) fail('Missing module folder: ${folder.path}');

  for (final entity in folder.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final file = entity.path.replaceAll(r'\', '/');
    final sourcePath = file.startsWith('lib/') ? file.substring(4) : file;
    final text = entity.readAsStringSync();
    for (final match in RegExp(r"""^\s*import\s+['"]([^'"]+)['"]""", multiLine: true).allMatches(text)) {
      final target = match[1]!;
      late final List<String> parts;
      if (target.startsWith('package:hotel_booking/')) {
        parts = target.substring('package:hotel_booking/'.length).split('/');
      } else if (target.startsWith('dart:') || target.startsWith('package:')) {
        continue;
      } else {
        final resolved = Uri.parse('package:hotel_booking/$sourcePath').resolve(target).path;
        parts = resolved.split('/')..removeWhere((part) => part.isEmpty);
        if (parts.isNotEmpty && parts.first == 'hotel_booking') parts.removeAt(0);
      }
      if (parts.isEmpty) continue;
      uses.add((file: file, target: target, module: parts[0],
        internal: parts.length > 1 && parts[1] == 'src'));
    }
  }
  return uses;
}

void main() {
  test('Reservations uses only public contracts of other modules', () {
    for (final use in importsOf('reservations')) {
      expect(use.module == 'reservations' || !use.internal, isTrue,
          reason: '${use.file} imports internal module path ${use.target}');
    }
  });

  test('Rooms does not depend on another business module', () {
    for (final use in importsOf('rooms')) {
      expect({'reservations', 'payments', 'notifications'}, isNot(contains(use.module)),
          reason: '${use.file} imports ${use.target}');
    }
  });

  test('Payments and Notifications do not depend on Reservations', () {
    for (final module in ['payments', 'notifications']) {
      for (final use in importsOf(module)) {
        expect(use.module, isNot('reservations'),
            reason: '${use.file} imports ${use.target}');
      }
    }
  });
}
