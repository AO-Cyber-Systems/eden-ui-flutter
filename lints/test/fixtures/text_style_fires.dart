// FIXTURE -- MUST FIRE: text_style_needs_family.
//
// A TextStyle with no family inherits whatever the ambient theme happens to
// be, which is exactly the silent drift the token layer exists to prevent.

class TextStyle {
  const TextStyle({int? fontSize, String? fontFamily, int? fontWeight});
}

class ShellLabel {
  TextStyle sectionLabel() {
    return TextStyle(fontSize: 14); // EXPECT: text_style_needs_family
  }

  static const TextStyle badge =
      TextStyle(fontSize: 10, fontWeight: 700); // EXPECT: text_style_needs_family
}
