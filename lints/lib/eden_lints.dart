/// Eden UI custom_lint rules.
///
/// DEV-ONLY. This package is a `dev_dependencies` path entry of the root
/// package and is never reachable from the published `lib/`, so neither
/// eden-biz nor aodex resolves it.
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/no_magic_spacing.dart';
import 'src/no_raw_color.dart';
import 'src/scope.dart';
import 'src/text_style_needs_family.dart';

export 'src/ctor.dart';
export 'src/no_magic_spacing.dart';
export 'src/no_raw_color.dart';
export 'src/scan.dart';
export 'src/scope.dart';
export 'src/text_style_needs_family.dart';

PluginBase createPlugin() => _EdenLintsPlugin();

class _EdenLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // NOTE ON THE YAML SHAPE. custom_lint parses a rule entry as
    // `item.keys.first` = the rule name and `item.entries.skip(1)` = its
    // options, so the options are SIBLING keys of the rule name inside the
    // same list item -- NOT nested under it. Nesting them parses cleanly,
    // yields an empty options map, and every path is then silently skipped:
    // `dart run custom_lint` reports "No issues found!" whether or not the
    // rules work. That false green is what the differential control in this
    // TRD caught; see analysis_options.yaml for the shape that works.
    List<String> pathsFor(String rule) =>
        enforcedPathsFrom(configs.rules[rule]?.json);
    List<String> legacyFor(String rule) =>
        legacyExemptionsFrom(configs.rules[rule]?.json);

    return <LintRule>[
      NoRawColor(
        enforcedPaths: pathsFor(kNoRawColor),
        legacyExemptions: legacyFor(kNoRawColor),
      ),
      TextStyleNeedsFamily(
        enforcedPaths: pathsFor(kTextStyleNeedsFamily),
        legacyExemptions: legacyFor(kTextStyleNeedsFamily),
      ),
      NoMagicSpacing(
        enforcedPaths: pathsFor(kNoMagicSpacing),
        legacyExemptions: legacyFor(kNoMagicSpacing),
      ),
    ];
  }
}
