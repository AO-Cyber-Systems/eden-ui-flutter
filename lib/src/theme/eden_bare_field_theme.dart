import 'package:flutter/material.dart';

/// Wrap a text field in this when its PARENT owns the chrome.
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(color: cardColor, borderRadius: radius),
///   child: EdenBareFieldTheme(
///     child: TextField(
///       decoration: InputDecoration(hintText: 'Search…'),
///     ),
///   ),
/// )
/// ```
///
/// Inside it, a field inherits NOTHING from [EdenTheme]'s
/// `inputDecorationTheme`: no fill, no border in any state, no content
/// padding. The card above is the chrome, and the field paints only its text.
/// Anything the field does want it declares at the site, where a reader can
/// see it — [EdenSecretField] declares its own `OutlineInputBorder` inside
/// this wrapper, and that still works, because a decoration written at the
/// site always wins over the theme it is merged with.
///
/// ## The defect this exists to make impossible
///
/// `EdenTheme.inputDecorationTheme` is library-wide and declares `filled:
/// true` with an opaque `fillColor`, an `OutlineInputBorder` in
/// `colorScheme.outline` for `border`, `enabledBorder` and `errorBorder`, one
/// in `colorScheme.primary` for `focusedBorder`, and a 16x12 `contentPadding`.
/// A widget that draws its own background, puts a `TextField` on it, and says
/// `border: InputBorder.none` has NOT opted out of any of that:
///
///   * `InputDecoration.applyDefaults` fills THIRTY-ONE properties from the
///     theme independently of one another (`input_decorator.dart:4024`), and
///   * `_InputDecoratorState` chooses the border for the CURRENT state —
///     `enabledBorder` while enabled and unfocused, `focusedBorder` while
///     focused, `disabledBorder`, `errorBorder`, `focusedErrorBorder` — and
///     only falls back to `border` when the state's slot is null.
///
/// So `border: InputBorder.none` silences exactly one of six border slots and
/// nothing else. That cost this library two separate rounds of fixes — the
/// fill (`c5f367e`, `d3691f1`) and then the `enabledBorder` ring in seven
/// widgets — and a third round was guaranteed for as long as the answer was
/// "also turn off the next property".
///
/// ## Why this shape, and not the two obvious ones
///
/// **`InputDecoration.collapsed` does not cover the set.** Verified against
/// Flutter 3.41.9 rather than assumed: its constructor sets `filled = false`
/// and `border = InputBorder.none` and NOTHING else
/// (`input_decorator.dart:2872`), so `enabledBorder` — the slot that actually
/// paints while a field sits there enabled — still resolves from the theme,
/// along with `focusedBorder`, `errorBorder`, `contentPadding`, `hintStyle`
/// and the rest. It also has no `prefixIcon`, `suffixIcon` or `label`, which
/// three of this library's ten bare fields need.
///
/// **A shared `const InputDecoration` that nulls every property cannot be
/// written.** Null in an `InputDecoration` does not mean "nothing"; it means
/// "take the theme's". Opting out requires an explicit non-null value for
/// every property — the same enumeration, just written once — and the moment
/// Flutter or `EdenTheme` grows a thirty-second property the enumeration is
/// short again and the leak is back, silently.
///
/// **Replacing the theme is closed by construction.** [decorationTheme] is
/// built from scratch, not derived from `EdenTheme`'s, so nothing `EdenTheme`
/// declares can reach a field inside this wrapper — not the properties that
/// leaked, and not one added next year. The six border slots and `filled` are
/// stated explicitly because Flutter's OWN fallback for an unset border is a
/// visible `UnderlineInputBorder`; everything else is left unset, which means
/// Flutter's plain default rather than Eden's form chrome.
///
/// Pinned by `test/ui_oracle/field_border_overpaint_test.dart` (the rendered
/// frame, per widget) and `test/ui_oracle/bare_field_theme_guard_test.dart`
/// (the class: no bare field resolves anything of `EdenTheme`'s, and no file
/// declares a bare field without reaching for this).
class EdenBareFieldTheme extends StatelessWidget {
  const EdenBareFieldTheme({super.key, required this.child});

  /// Typically a `TextField` or `TextFormField`, or a small subtree
  /// containing one.
  final Widget child;

  /// The decoration theme a bare field sees: no fill, no border in ANY state,
  /// no content padding.
  ///
  /// Exposed so a test can assert against it and so a widget that needs the
  /// same neutrality somewhere this wrapper does not fit (a `Theme` it is
  /// already building, say) can use the identical value rather than a second
  /// hand-rolled one.
  static const InputDecorationTheme decorationTheme = InputDecorationTheme(
    filled: false,
    // All six slots, not just `border`: the state-specific slots are what
    // `_InputDecoratorState` actually reaches for, and each falls back to
    // the theme independently.
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    // The parent owns the spacing as well as the paint. A field that needs
    // padding of its own declares it at the site.
    contentPadding: EdgeInsets.zero,
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: decorationTheme),
      child: child,
    );
  }
}
