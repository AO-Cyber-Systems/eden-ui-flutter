import 'package:flutter/material.dart';

import '../eden_ui.dart';
import 'explorer/story_shell.dart';
import 'registry/story_registry.dart';

/// Builds the explorer route for [settings] from the [StoryRegistry].
///
/// `/` → landing (no story selected); `/story/<id>` → that story when it is
/// registered; any unknown route → landing. Never returns `null`, so a stale or
/// invalid URL hash still lands on the explorer.
///
/// URL strategy is Flutter web's DEFAULT hash strategy — deep links take the
/// form `/#/story/<id>` (becoming `/flutter/#/story/<id>` under the portal's
/// `--base-href /flutter/`). The default hash strategy is kept (no path-URL
/// strategy, no server rewrites), so the eden-docs `http.FileServer` serves the
/// bundle unchanged.
Route<dynamic> generateExplorerRoute(RouteSettings settings) {
  final name = settings.name ?? '/';
  String? storyId;
  if (name.startsWith('/story/')) {
    // Use replaceFirst (not split) so nested ids like `buttons/interactive`
    // survive the leading `/story/` strip.
    final id = name.replaceFirst('/story/', '');
    if (StoryRegistry.instance.byId(id) != null) {
      storyId = id;
    }
  }
  return MaterialPageRoute<dynamic>(
    settings: settings,
    builder: (_) => Scaffold(body: StoryShell(initialStoryId: storyId)),
  );
}

/// Dev catalog app — the Flutter component explorer ("our own Widgetbook").
///
/// Navigation is driven entirely by [generateExplorerRoute] off the
/// [StoryRegistry]; per-canvas theme (profile / brand / brightness / viewport)
/// is controlled by the StoryShell toolbar, so the legacy HomeScreen theme
/// toggles are no longer needed.
class EdenDevApp extends StatelessWidget {
  const EdenDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eden UI — Dev Catalog',
      debugShowCheckedModeBanner: false,
      theme: EdenTheme.light(brand: EdenColors.gold),
      darkTheme: EdenTheme.dark(brand: EdenColors.gold),
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: generateExplorerRoute,
    );
  }
}
