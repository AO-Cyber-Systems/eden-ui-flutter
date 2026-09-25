// The guard that stops round three.
//
// WHY THIS FILE EXISTS. `EdenTheme`'s `inputDecorationTheme` is library-wide,
// and a field that means "my parent owns the chrome" has to opt out of ALL of
// it. Opting out property by property has now failed twice: `filled: false`
// in five widgets (`c5f367e`, `d3691f1`), then the `enabledBorder` ring in
// seven (`field_border_overpaint_test.dart`). `InputDecoration.applyDefaults`
// resolves thirty-one properties from the theme independently
// (`input_decorator.dart:4024`), so there was always another one.
//
// `EdenBareFieldTheme` closes the class by replacing the whole
// `InputDecorationTheme` for its subtree. This file holds that closed, in
// three checks that fail for three different future mistakes:
//
//   1. THE MECHANISM. Property-name driven, not a list someone maintains:
//      every property `EdenTheme` declares is read out of the theme's own
//      diagnostics, and each one must resolve DIFFERENTLY for a bare field.
//      Add `hintStyle` to `EdenTheme.inputDecorationTheme` tomorrow and this
//      check covers it without being edited. It also asserts the bare theme
//      carries nothing BEYOND its declared no-chrome set, which is what would
//      go wrong if someone rebuilt it as `EdenTheme...copyWith(...)`.
//
//   2. THE SITES. Every one of the ten surfaces that means "my parent owns
//      the chrome" is pumped in both themes, and on each of them EVERY
//      `InputDecorator` in the tree must be inside an `EdenBareFieldTheme`
//      and must resolve none of `EdenTheme`'s fill or borders. Remove the
//      wrapper from any of them, or add an eleventh field to one of those
//      widgets without it, and this fails naming the surface.
//
//   3. THE NEXT FILE. A source census over `lib/`: any file that declares a
//      field bare — `InputBorder.none` or `filled: false` inside an
//      `InputDecoration` — must reach for `EdenBareFieldTheme`, or carry an
//      `// eden-bare-field: exempt — <reason>` with a reason. Bytes are read
//      and decoded in Dart, never shelled out to `grep`, for the reason
//      `eden_field_purpose_guard_test.dart` gives at length: a guard that
//      passes vacuously is worse than no guard. The rule is exercised against
//      synthetic sources as well as the real tree, so a mis-globbed or empty
//      file set fails instead of passing.
//
// WHAT IS DELIBERATELY NOT ASSERTED. `contentPadding` is not compared against
// `EdenTheme`'s in check 2: `EdenPhotoCapturePage` declares 16x12 AT THE SITE
// — the same numbers the theme happens to use — precisely so that killing the
// leak moved none of its geometry. A site is allowed to choose any value it
// likes; what it may not do is INHERIT one.
library;

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// -----------------------------------------------------------------------------
// 1. The mechanism
// -----------------------------------------------------------------------------

/// Every property of an input-decoration theme, by name, read from the
/// object's own diagnostics so that a property added to Flutter or to
/// `EdenTheme` appears here without this file being edited.
Map<String, Object?> _properties(Object theme) {
  final Map<String, Object?> out = <String, Object?>{};
  for (final DiagnosticsNode node
      in (theme as Diagnosticable).toDiagnosticsNode().getProperties()) {
    final String? name = node.name;
    if (name != null) {
      out[name] = node.value;
    }
  }
  return out;
}

/// The same accessor `InputDecoration.applyDefaults` reads, for each of the
/// three themes this check compares.
Object _resolve(InputDecorationTheme theme) =>
    ThemeData.light().copyWith(inputDecorationTheme: theme).inputDecorationTheme;

/// The properties [EdenBareFieldTheme] states on purpose. Everything else it
/// leaves unset, which means Flutter's plain default rather than Eden's form
/// chrome.
const Set<String> _kDeclaredBare = <String>{
  'border',
  'enabledBorder',
  'disabledBorder',
  'focusedBorder',
  'errorBorder',
  'focusedErrorBorder',
  'contentPadding',
};

// -----------------------------------------------------------------------------
// 2. The sites
// -----------------------------------------------------------------------------

typedef _SurfaceBuilder = Widget Function();

class _Site {
  const _Site(this.name, this.build, {this.size = const Size(900, 700), this.after});
  final String name;
  final _SurfaceBuilder build;
  final Size size;
  final Future<void> Function(WidgetTester tester)? after;
}

final List<_Site> _kSites = <_Site>[
  _Site(
    '_TopBar (EdenDesktopLayout)',
    () => EdenDesktopLayout(
      navItems: const <EdenNavItem>[
        EdenNavItem(id: 'i', label: 'Inventory', icon: Icons.inventory_2),
      ],
      selectedId: 'i',
      onNavChanged: (_) {},
      topBar: const EdenTopBarConfig(
        title: 'Orders',
        showSearch: true,
        searchHint: 'Search orders…',
      ),
      body: const SizedBox(),
    ),
    size: const Size(1280, 800),
  ),
  _Site(
    'EdenPhotoCapturePage',
    () => EdenPhotoCapturePage(
      cameraPreviewBuilder: (_) => const ColoredBox(color: Color(0xFF3366AA)),
      onCapture: (EdenPhotoCaptureRequest r) async =>
          EdenCapturedPhoto(filePath: '', capturedAt: DateTime(2026)),
    ),
    after: (WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
    },
  ),
  _Site(
    'EdenRichTextEditor',
    () => const EdenRichTextEditor(placeholder: 'Write…'),
  ),
  _Site(
    'EdenSecretField',
    () => const Align(
      alignment: Alignment.topCenter,
      child: EdenSecretField(value: 'sk-123', label: 'API key'),
    ),
  ),
  _Site(
    'EdenEnvEditor',
    () => const Align(
      alignment: Alignment.topCenter,
      child: EdenEnvEditor(entries: <EdenEnvEntry>[
        EdenEnvEntry(key: 'API_URL', value: 'https://example.test'),
      ]),
    ),
  ),
  _Site(
    'EdenMessageInput',
    () => const Align(
      alignment: Alignment.topCenter,
      child: EdenMessageInput(placeholder: 'Message…'),
    ),
  ),
  _Site(
    'EdenMapView',
    () => const EdenMapView(mapBuilder: ColoredBox(color: Color(0xFFEEEEEE))),
  ),
  _Site(
    'EdenMarkdownEditor',
    () => const EdenMarkdownEditor(placeholder: 'Write markdown…'),
  ),
  _Site(
    'EdenLineItemEditor',
    () => EdenLineItemEditor<void>(
      items: const <EdenLineItem<void>>[
        EdenLineItem<void>(
          id: 'a',
          payload: null,
          description: 'Widget',
          quantity: 1,
          unitPrice: 10,
        ),
      ],
      onItemsChanged: (_) {},
    ),
    size: const Size(1200, 700),
  ),
  _Site(
    'EdenCommandPalette',
    () => const EdenCommandPalette(
      items: <EdenCommandItem>[EdenCommandItem(id: 'a', label: 'Do a thing')],
    ),
  ),
];

// -----------------------------------------------------------------------------
// 3. The source census
// -----------------------------------------------------------------------------

/// Line comments removed, so a file that merely TALKS about
/// `InputBorder.none` is not accused of using it. String literals are left
/// alone deliberately: a literal containing `InputBorder.none` would be
/// generated code or a test fixture, and neither belongs in `lib/`.
String _withoutLineComments(String source) => source
    .split('\n')
    .map((String line) {
      final int at = line.indexOf('//');
      return at == -1 ? line : line.substring(0, at);
    })
    .join('\n');

/// The rule, as a pure function over path -> source so it can be exercised on
/// synthetic input as well as on the real tree.
List<String> bareFieldViolations(Map<String, String> sources) {
  final List<String> out = <String>[];
  sources.forEach((String path, String raw) {
    final String code = _withoutLineComments(raw);
    final bool declaresField = code.contains('InputDecoration');
    final bool declaresBare =
        code.contains('InputBorder.none') || code.contains('filled: false');
    if (!declaresField || !declaresBare) {
      return;
    }
    if (code.contains('EdenBareFieldTheme')) {
      return;
    }
    final RegExpMatch? exemption =
        RegExp(r'//\s*eden-bare-field:\s*exempt\s*—\s*(\S.*)').firstMatch(raw);
    if (exemption != null) {
      return;
    }
    if (RegExp(r'//\s*eden-bare-field:\s*exempt').hasMatch(raw)) {
      out.add('$path: carries an eden-bare-field exemption with no reason '
          'after the em dash. Say why the parent does not own the chrome.');
      return;
    }
    out.add('$path: declares a field bare (InputBorder.none / filled: false) '
        'without EdenBareFieldTheme. Turning one property off leaves the '
        'other thirty on — wrap the field instead, or write '
        '// eden-bare-field: exempt — <why> if this really is not the class.');
  });
  return out;
}

/// The ten sites that adopted the wrapper. Named, so removing it from any one
/// of them fails HERE as well as in the pixel tests — a pixel test can be
/// deleted with the widget it covers; this cannot.
const List<String> _kAdoptedSites = <String>[
  'lib/src/widgets/eden_layout/eden_desktop_layout.dart',
  'lib/src/widgets/eden_photo_capture_page.dart',
  'lib/src/widgets/eden_rich_text_editor.dart',
  'lib/src/widgets/eden_secret_field.dart',
  'lib/src/widgets/eden_env_editor.dart',
  'lib/src/widgets/eden_message_input.dart',
  'lib/src/widgets/eden_map_view.dart',
  'lib/src/widgets/eden_markdown_editor.dart',
  'lib/src/widgets/eden_line_item_editor.dart',
  'lib/src/widgets/eden_command_palette.dart',
];

Map<String, String> _libSources() {
  final Directory lib = Directory('${Directory.current.path}/lib');
  if (!lib.existsSync()) {
    fail(
      'lib/ not found at ${lib.path}. Resolved from Directory.current = '
      '${Directory.current.path}. Remedy: run `flutter test` from the package '
      'root. NEVER let this resolve to nothing and pass.',
    );
  }
  final Map<String, String> out = <String, String>{};
  for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    // Decoded in Dart, so a NUL byte or any other control character is an
    // ordinary code point rather than something that silently truncates a
    // scan. Genuinely malformed UTF-8 throws and fails the test loudly.
    out[entity.path.replaceFirst('${Directory.current.path}/', '')] =
        utf8.decode(entity.readAsBytesSync());
  }
  return out;
}

void main() {
  group('1. the mechanism: nothing EdenTheme declares reaches a bare field',
      () {
    test('every property EdenTheme declares resolves differently when bare',
        () {
      final Map<String, Object?> flutterDefault =
          _properties(_resolve(const InputDecorationTheme()));
      final Map<String, Object?> bare =
          _properties(_resolve(EdenBareFieldTheme.decorationTheme));

      for (final ThemeData theme in <ThemeData>[
        EdenTheme.light(),
        EdenTheme.dark(),
      ]) {
        final Map<String, Object?> eden =
            _properties(theme.inputDecorationTheme);
        final Set<String> declared = <String>{
          for (final String name in eden.keys)
            if (eden[name] != flutterDefault[name]) name,
        };

        // Anti-vacuity: if this set were empty — a renamed getter, an
        // EdenTheme that stopped declaring a decoration theme — the loop
        // below would assert nothing and pass.
        expect(
          declared,
          containsAll(<String>[
            'filled',
            'fillColor',
            'border',
            'enabledBorder',
            'focusedBorder',
            'errorBorder',
            'contentPadding',
          ]),
          reason: 'EdenTheme.inputDecorationTheme is expected to declare at '
              'least the seven properties this library has been bitten by. It '
              'declared $declared. If a property moved, this guard is reading '
              'the wrong object and is worth nothing until that is fixed.',
        );

        for (final String name in declared) {
          expect(
            bare[name],
            isNot(eden[name]),
            reason: 'EdenTheme declares $name = ${eden[name]}, and a field '
                'inside EdenBareFieldTheme resolves the SAME value — so the '
                "theme's chrome is reaching a field whose parent owns the "
                'chrome. That is the defect this widget exists to make '
                'impossible; it means the bare theme is being derived from '
                "EdenTheme's rather than built from scratch.",
          );
        }
      }
    });

    test('the bare theme carries nothing beyond its declared no-chrome set',
        () {
      final Map<String, Object?> flutterDefault =
          _properties(_resolve(const InputDecorationTheme()));
      final Map<String, Object?> bare =
          _properties(_resolve(EdenBareFieldTheme.decorationTheme));

      final Set<String> stated = <String>{
        for (final String name in bare.keys)
          if (bare[name] != flutterDefault[name]) name,
      };

      expect(
        stated,
        _kDeclaredBare,
        reason: 'EdenBareFieldTheme.decorationTheme must state the six border '
            'slots and contentPadding — the six because Flutter\'s OWN '
            'fallback for an unset border is a visible UnderlineInputBorder — '
            'and nothing else, so that everything it does not name falls back '
            "to Flutter's default rather than to somebody's idea of Eden's "
            'chrome. It stated $stated.',
      );

      expect(
        bare['filled'],
        isFalse,
        reason: 'a bare field paints no fill. `filled` is false in Flutter\'s '
            'default too, which is why it is not in the set above — but it is '
            'stated explicitly in the theme and must stay false.',
      );
      for (final String slot in <String>[
        'border',
        'enabledBorder',
        'disabledBorder',
        'focusedBorder',
        'errorBorder',
        'focusedErrorBorder',
      ]) {
        expect(
          bare[slot],
          InputBorder.none,
          reason: '$slot must be InputBorder.none. The state-specific slots '
              'are what _InputDecoratorState actually reaches for; `border` '
              'alone covers none of them.',
        );
      }
    });
  });

  group('2. the sites: every field on a bare surface is wrapped, and resolves '
      'no Eden chrome', () {
    for (final _Site site in _kSites) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String label =
            '${site.name} (${mode == ThemeMode.light ? 'light' : 'dark'})';
        testWidgets(label, (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = site.size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: EdenTheme.light(),
            darkTheme: EdenTheme.dark(),
            themeMode: mode,
            home: Scaffold(body: site.build()),
          ));
          await tester.pumpAndSettle();
          await site.after?.call(tester);

          final Finder all = find.byType(InputDecorator);
          final int total = all.evaluate().length;
          expect(
            total,
            greaterThan(0),
            reason: '$label pumped no field at all, so this case is checking '
                'nothing. Fix the surface, not the assertion.',
          );

          final Finder wrapped = find.descendant(
            of: find.byType(EdenBareFieldTheme),
            matching: all,
          );
          expect(
            wrapped.evaluate().length,
            total,
            reason: '$label has $total field(s) and only '
                '${wrapped.evaluate().length} of them inside an '
                'EdenBareFieldTheme. A field on this surface takes its chrome '
                'from its parent; one that is not wrapped inherits '
                "EdenTheme's fill and its six borders instead, which is how "
                'both previous rounds of this defect happened.',
          );

          final ThemeData active =
              mode == ThemeMode.light ? EdenTheme.light() : EdenTheme.dark();
          final Object edenTheme = active.inputDecorationTheme;
          final Map<String, Object?> eden = _properties(edenTheme);

          for (final Element element in wrapped.evaluate()) {
            final InputDecorator decorator = element.widget as InputDecorator;
            final InputDecoration d = decorator.decoration;
            expect(
              d.filled,
              isNot(true),
              reason: '$label: a wrapped field still resolved filled: true, '
                  'so something is putting EdenTheme\'s fillColor back.',
            );
            final Map<String, Object?> resolved = <String, Object?>{
              'border': d.border,
              'enabledBorder': d.enabledBorder,
              'disabledBorder': d.disabledBorder,
              'focusedBorder': d.focusedBorder,
              'errorBorder': d.errorBorder,
              'focusedErrorBorder': d.focusedErrorBorder,
            };
            resolved.forEach((String slot, Object? value) {
              if (eden[slot] == null) {
                return;
              }
              expect(
                value,
                isNot(eden[slot]),
                reason: '$label: a wrapped field resolved $slot to '
                    "EdenTheme's own ${eden[slot]}. `border: InputBorder.none` "
                    'does not silence the state-specific slots; the wrapper '
                    'is supposed to.',
              );
            });
          }
        });
      }
    }
  });

  group('3. the source census: a bare field without the wrapper fails', () {
    test('the rule fires on a bare field that is not wrapped', () {
      final List<String> violations = bareFieldViolations(<String, String>{
        'lib/src/widgets/new_card.dart': '''
Widget build(BuildContext context) => Container(
      color: cardColor,
      child: TextField(
        decoration: InputDecoration(hintText: 'x', border: InputBorder.none),
      ),
    );
''',
      });
      expect(violations, hasLength(1));
      expect(violations.single, contains('new_card.dart'));
    });

    test('the rule is satisfied by the wrapper, and by a reasoned exemption',
        () {
      expect(
        bareFieldViolations(<String, String>{
          'lib/a.dart': '''
EdenBareFieldTheme(
  child: TextField(decoration: InputDecoration(border: InputBorder.none)),
)
''',
          'lib/b.dart': '''
// eden-bare-field: exempt — this is the theme's own definition of bare.
const InputDecorationTheme(filled: false, border: InputBorder.none);
''',
        }),
        isEmpty,
      );
    });

    test('a reasonless exemption is itself a violation', () {
      final List<String> violations = bareFieldViolations(<String, String>{
        'lib/c.dart': '''
// eden-bare-field: exempt
TextField(decoration: InputDecoration(border: InputBorder.none));
''',
      });
      expect(violations, hasLength(1));
      expect(violations.single, contains('no reason'));
    });

    test('a file that only MENTIONS InputBorder.none in prose is not accused',
        () {
      expect(
        bareFieldViolations(<String, String>{
          'lib/d.dart': '''
// `border: InputBorder.none` does not turn off enabledBorder.
TextField(decoration: InputDecoration(hintText: 'x'));
''',
        }),
        isEmpty,
      );
    });

    test('every lib/ file that declares a bare field reaches for the wrapper',
        () {
      final Map<String, String> sources = _libSources();

      // The census, pinned as lower bounds. A mis-globbed or silently empty
      // file set fails here instead of reporting zero violations.
      expect(sources.length, greaterThanOrEqualTo(500),
          reason: 'lib/ held ${sources.length} Dart files; it had 533 when '
              'this guard was written. A collapsed file set makes the rule '
              'below vacuous.');
      final int withDecoration = sources.values
          .where((String s) => _withoutLineComments(s).contains('InputDecoration'))
          .length;
      expect(withDecoration, greaterThanOrEqualTo(60),
          reason: '$withDecoration files use InputDecoration; there were 73.');

      expect(bareFieldViolations(sources), isEmpty);
    });

    test('all ten adopted sites still carry EdenBareFieldTheme', () {
      final Map<String, String> sources = _libSources();
      for (final String path in _kAdoptedSites) {
        final String? source = sources[path];
        expect(source, isNotNull, reason: '$path is gone from lib/.');
        expect(
          source!.contains('EdenBareFieldTheme'),
          isTrue,
          reason: '$path adopted EdenBareFieldTheme when the class was fixed '
              'and no longer references it. If the widget genuinely stopped '
              'having a field, remove it from _kAdoptedSites in the same '
              'commit and say so; if not, the theme leak is back.',
        );
      }
    });
  });
}
