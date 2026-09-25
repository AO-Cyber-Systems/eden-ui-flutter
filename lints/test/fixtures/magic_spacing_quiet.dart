// FIXTURE -- MUST STAY QUIET: no_magic_spacing.
//
// Spacing comes from the scale. `EdgeInsets.zero`-equivalent zeros are also
// quiet: zero is not a magic number, it is the absence of one.

class EdgeInsets {
  const EdgeInsets.all(num value);
  const EdgeInsets.symmetric({num? horizontal, num? vertical});
}

class SizedBox {
  const SizedBox({num? width, num? height});
}

class EdenSpacing {
  static const num md = 12;
  static const num space4 = 16;
}

class ShellSpacer {
  EdgeInsets padding() {
    return EdgeInsets.all(EdenSpacing.md);
  }

  SizedBox gap() {
    return SizedBox(height: EdenSpacing.space4);
  }

  static const EdgeInsets inset = EdgeInsets.symmetric(horizontal: 0);
}
