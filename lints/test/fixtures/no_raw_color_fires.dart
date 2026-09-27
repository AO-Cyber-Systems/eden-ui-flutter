// FIXTURE -- MUST FIRE: no_raw_color.
//
// Two call shapes on purpose. A bare `Color(...)` parses as a MethodInvocation
// when nothing is resolved; a `const Color(...)` is an
// InstanceCreationExpression in both the resolved and unresolved worlds. A
// rule that recognised only one of the two would pass half its tests and never
// fire in CI.
//
// Every line that must be reported carries a trailing `// EXPECT:` marker; the
// test asserts the reported lines are EXACTLY the marked ones.

class Color {
  const Color(int value);
}

class ShellHeader {
  Color background() {
    return Color(0xFF112233); // EXPECT: no_raw_color
  }

  static const Color divider = Color(0x11000000); // EXPECT: no_raw_color
}
