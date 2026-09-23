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
