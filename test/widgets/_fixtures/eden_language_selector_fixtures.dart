// Do NOT regenerate via LLM — hand-built fixtures for EdenLanguageSelector.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenLanguageSelectorFixtures {
  EdenLanguageSelectorFixtures._();

  static const english = EdenLanguageOption(
    code: 'en',
    nativeLabel: 'English',
    englishLabel: 'English',
  );

  static const spanish = EdenLanguageOption(
    code: 'es',
    nativeLabel: 'Español',
    englishLabel: 'Spanish',
  );

  static const chinese = EdenLanguageOption(
    code: 'zh',
    nativeLabel: '中文',
    englishLabel: 'Chinese',
  );

  /// US federal default list expected codes per EO 13166 + Census Bureau
  /// Language Use Tables research.
  static const expectedDefaultCodes = ['en', 'es', 'zh', 'vi', 'ko', 'ru', 'ar'];
}
