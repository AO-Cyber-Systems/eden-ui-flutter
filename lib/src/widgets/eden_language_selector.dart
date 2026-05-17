import 'package:flutter/material.dart';

/// Layout for [EdenLanguageSelector] — `button` for a single button +
/// dropdown menu (compact), `chips` for a horizontal Wrap row.
enum EdenLanguageSelectorLayout { button, chips }

/// A language option for [EdenLanguageSelector].
///
/// [code] is a BCP 47 / ISO 639 code (e.g. `'en'`, `'es'`, `'zh'`).
/// [nativeLabel] is the language name in its own script (e.g. `'中文'`).
/// [englishLabel] is the language name in English (used as tooltip /
/// secondary display).
@immutable
class EdenLanguageOption {
  const EdenLanguageOption({
    required this.code,
    required this.nativeLabel,
    required this.englishLabel,
  });

  final String code;
  final String nativeLabel;
  final String englishLabel;
}

/// Default option lists shipped with the library.
class EdenLanguageOptions {
  EdenLanguageOptions._();

  /// The 7 most-spoken non-English languages in U.S. federal contexts,
  /// per Executive Order 13166 (Improving Access to Services for Persons
  /// with Limited English Proficiency) + Census Bureau Language Use
  /// Tables: English, Spanish, Chinese, Vietnamese, Korean, Russian,
  /// Arabic.
  ///
  /// Consumers can override by passing a custom [List<EdenLanguageOption>]
  /// to [EdenLanguageSelector.options].
  static const List<EdenLanguageOption> usFederalDefault = [
    EdenLanguageOption(
      code: 'en',
      nativeLabel: 'English',
      englishLabel: 'English',
    ),
    EdenLanguageOption(
      code: 'es',
      nativeLabel: 'Español',
      englishLabel: 'Spanish',
    ),
    EdenLanguageOption(
      code: 'zh',
      nativeLabel: '中文',
      englishLabel: 'Chinese',
    ),
    EdenLanguageOption(
      code: 'vi',
      nativeLabel: 'Tiếng Việt',
      englishLabel: 'Vietnamese',
    ),
    EdenLanguageOption(
      code: 'ko',
      nativeLabel: '한국어',
      englishLabel: 'Korean',
    ),
    EdenLanguageOption(
      code: 'ru',
      nativeLabel: 'Русский',
      englishLabel: 'Russian',
    ),
    EdenLanguageOption(
      code: 'ar',
      nativeLabel: 'العربية',
      englishLabel: 'Arabic',
    ),
  ];
}

/// USWDS-pattern language selector.
///
/// Two layouts:
///   - [EdenLanguageSelectorLayout.button] — compact: a single
///     [PopupMenuButton] showing current native label; tap reveals all
///     options as a menu.
///   - [EdenLanguageSelectorLayout.chips] — horizontal [Wrap] of
///     [ChoiceChip]s; the current option is `selected`.
///
/// Required for federal-mandate i18n compliance per Executive Order
/// 13166 and Section 508. The default option list
/// [EdenLanguageOptions.usFederalDefault] is research-confirmed from
/// EO 13166 + Census Bureau Language Use Tables.
///
/// Library scope: SELECTION ONLY. The widget does not change app locale
/// — consumer wires the locale change in response to the
/// [onLanguageChanged] callback. Library UI strings ('Language selector')
/// are English-only; consumer wraps in their own i18n layer if needed.
///
/// Civilian re-use: any consumer app needing i18n toggle, not just
/// federal.
class EdenLanguageSelector extends StatelessWidget {
  const EdenLanguageSelector({
    super.key,
    required this.current,
    required this.onLanguageChanged,
    this.options = EdenLanguageOptions.usFederalDefault,
    this.layout = EdenLanguageSelectorLayout.button,
  });

  final EdenLanguageOption current;
  final ValueChanged<EdenLanguageOption> onLanguageChanged;
  final List<EdenLanguageOption> options;
  final EdenLanguageSelectorLayout layout;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Language selector, current: ${current.nativeLabel}',
      child: layout == EdenLanguageSelectorLayout.button
          ? _ButtonLayout(
              current: current,
              options: options,
              onLanguageChanged: onLanguageChanged,
            )
          : _ChipsLayout(
              current: current,
              options: options,
              onLanguageChanged: onLanguageChanged,
            ),
    );
  }
}

class _ButtonLayout extends StatelessWidget {
  const _ButtonLayout({
    required this.current,
    required this.options,
    required this.onLanguageChanged,
  });

  final EdenLanguageOption current;
  final List<EdenLanguageOption> options;
  final ValueChanged<EdenLanguageOption> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EdenLanguageOption>(
      tooltip: 'Select language',
      onSelected: onLanguageChanged,
      itemBuilder: (context) {
        return [
          for (final option in options)
            PopupMenuItem<EdenLanguageOption>(
              value: option,
              child: Semantics(
                button: true,
                label: 'Switch to ${option.nativeLabel}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(option.nativeLabel)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '(${option.englishLabel})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16),
            const SizedBox(width: 6),
            Text(current.nativeLabel),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ChipsLayout extends StatelessWidget {
  const _ChipsLayout({
    required this.current,
    required this.options,
    required this.onLanguageChanged,
  });

  final EdenLanguageOption current;
  final List<EdenLanguageOption> options;
  final ValueChanged<EdenLanguageOption> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          Semantics(
            button: true,
            label: 'Switch to ${option.nativeLabel}',
            child: ChoiceChip(
              label: Text(option.nativeLabel),
              tooltip: option.englishLabel,
              selected: option.code == current.code,
              onSelected: (_) => onLanguageChanged(option),
            ),
          ),
      ],
    );
  }
}
