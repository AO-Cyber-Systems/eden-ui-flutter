// test/tool/story_coverage_test.dart
//
// Unit tests for the PURE counting core of tool/story_coverage.dart
// (TRD 23-04). Every fixture here is hand-built — no LLM-generated test data,
// no fuzzy matching against the real barrel or registry.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';

import '../../tool/story_coverage.dart';

void main() {
  group('exportedWidgets', () {
    test(
        'case 1: three well-formed export lines return three PascalCase '
        'names', () {
      final names = exportedWidgets(const [
        "export 'src/widgets/eden_x.dart';",
        "export 'src/widgets/eden_y.dart';",
        "export 'src/widgets/eden_z.dart';",
      ]);

      expect(names, equals(['EdenX', 'EdenY', 'EdenZ']));
    });

    test(
        'case 1b: comment banners, blank lines and the leading `library;` '
        'declaration are ignored, not counted', () {
      final names = exportedWidgets(const [
        'library;',
        '',
        '// Widgets',
        "export 'src/widgets/eden_x.dart';",
        '   ',
        "export 'src/widgets/eden_y.dart';",
      ]);

      expect(names, equals(['EdenX', 'EdenY']));
    });

    test(
        'case 1c: a same-line show/hide clause is tolerated and does not '
        'change the derived name', () {
      final names = exportedWidgets(const [
        "export 'src/widgets/eden_map_view.dart' hide EdenMapMarker;",
      ]);

      expect(names, equals(['EdenMapView']));
    });

    test(
        'case 2: a line that does not match the expected export shape raises '
        'a named error carrying the 1-based line number, rather than being '
        'skipped', () {
      final lines = [
        "export 'src/widgets/eden_x.dart';",
        "export 'src/widgets/eden_y.dart'", // missing trailing semicolon
        "export 'src/widgets/eden_z.dart';",
      ];

      expect(
        () => exportedWidgets(lines),
        throwsA(
          isA<BarrelLineFormatError>()
              .having((e) => e.lineNumber, 'lineNumber', 2)
              .having((e) => e.line, 'line', lines[1]),
        ),
      );
    });
  });

  group('widgetsWithStory', () {
    EdenStory story({required String id, required String component}) =>
        EdenStory(
          id: id,
          component: component,
          name: 'Test',
          knobs: const [],
          build: (context, _) => const SizedBox.shrink(),
        );

    test(
        'case 3: a hand-built registry of two stories (components "buttons" '
        'and "cards") returns exactly the two widgets those components map '
        'to, and nothing else', () {
      final stories = [
        story(id: 'buttons/interactive', component: 'buttons'),
        story(id: 'cards/interactive', component: 'cards'),
      ];

      final covered = widgetsWithStory(stories);

      expect(covered, equals({'EdenButton', 'EdenCard'}));
    });

    test(
        'case 4: a widget listed in the hand-maintained indirect list counts '
        'as covered when its component has a registered story, and the '
        'reason string is carried through', () {
      final stories = [
        story(id: 'layouts/layouts', component: 'layouts'),
      ];

      final covered = widgetsWithStory(stories);

      expect(covered, contains('EdenLayoutExports'));
      expect(
        indirectComponentWidgets['layouts']!.reason,
        contains('EdenDesktopLayout'),
      );
    });

    test(
        'case 4b: an indirect entry is NOT added when no story registers its '
        'component — indirect coverage is conditional, exactly like direct '
        'coverage', () {
      final stories = [
        story(id: 'buttons/interactive', component: 'buttons'),
      ];

      final covered = widgetsWithStory(stories);

      expect(covered, isNot(contains('EdenLayoutExports')));
    });
  });

  group('computeCoverage', () {
    test(
        'a covered entry that is not in the exported set contributes nothing '
        '— a wrong mapping entry can never inflate the floor', () {
      final report = computeCoverage(
        exported: const ['EdenButton', 'EdenCard', 'EdenBadge'],
        covered: {'EdenButton', 'EdenTypo'}, // "EdenTypo" is not exported
      );

      expect(report.exportedWidgets, equals(3));
      expect(report.withStory, equals(1));
      expect(report.uncovered, equals(['EdenBadge', 'EdenCard']));
    });
  });
}
