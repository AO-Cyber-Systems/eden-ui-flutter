// FIXTURE -- MUST FIRE: no_magic_spacing.
//
// 13 is nobody's design decision. Both the EdgeInsets family and the
// SizedBox width/height pair are covered, because the same magic number
// reaches the screen either way.

class EdgeInsets {
  const EdgeInsets.all(num value);
  const EdgeInsets.symmetric({num? horizontal, num? vertical});
}

class SizedBox {
  const SizedBox({num? width, num? height});
}

class ShellSpacer {
  EdgeInsets padding() {
    return EdgeInsets.all(13); // EXPECT: no_magic_spacing
  }

  SizedBox gap() {
    return SizedBox(height: 13); // EXPECT: no_magic_spacing
  }

  static const EdgeInsets inset =
      EdgeInsets.symmetric(horizontal: 6, vertical: 1); // EXPECT: no_magic_spacing
}
