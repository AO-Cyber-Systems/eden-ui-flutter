// FIXTURE -- MUST STAY QUIET: text_style_needs_family.
//
// A family is named explicitly, so the style is reproducible off-theme.

class TextStyle {
  const TextStyle({int? fontSize, String? fontFamily, int? fontWeight});
}

class ShellLabel {
  TextStyle sectionLabel() {
    return TextStyle(fontSize: 14, fontFamily: 'Inter');
  }

  static const TextStyle badge =
      TextStyle(fontSize: 10, fontWeight: 700, fontFamily: 'Inter');
}
