// FIXTURE -- MUST STAY QUIET: no_raw_color.
//
// Colours come from the token layer. A rule that cannot stay quiet is as
// useless as one that cannot fire: it is indistinguishable from a broken rule
// until somebody reads the output, and by then it has been switched off.
//
// No `// EXPECT:` markers here -- the test asserts zero reports.

class EdenColors {
  static const List<int> neutral = <int>[0, 1, 2];
  static const int surface = 3;
}

class ShellHeader {
  int background() {
    return EdenColors.neutral[500];
  }

  static const int divider = EdenColors.surface;
}
