import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Languages recognized by the highlight package.
const _supportedLanguages = {
  'dart', 'python', 'py', 'javascript', 'js', 'typescript', 'ts',
  'java', 'kotlin', 'swift', 'go', 'rust', 'c', 'cpp', 'csharp', 'cs',
  'ruby', 'rb', 'php', 'html', 'css', 'scss', 'sql', 'shell', 'bash',
  'sh', 'zsh', 'yaml', 'yml', 'json', 'xml', 'markdown', 'md',
  'dockerfile', 'graphql', 'r', 'scala', 'lua', 'perl', 'haskell',
  'elixir', 'erlang', 'clojure', 'ocaml', 'fsharp', 'powershell',
  'objectivec', 'matlab', 'groovy', 'vim', 'makefile', 'cmake',
  'nginx', 'ini', 'toml', 'diff', 'http', 'protobuf', 'terraform',
};

/// Common language aliases mapped to highlight.js names.
const _languageAliases = {
  'py': 'python',
  'js': 'javascript',
  'ts': 'typescript',
  'rb': 'ruby',
  'cs': 'csharp',
  'sh': 'bash',
  'zsh': 'bash',
  'yml': 'yaml',
  'md': 'markdown',
};

/// Mirrors the eden_code_block Rails component.
///
/// Displays code in a dark block with optional language label, copy button,
/// and syntax highlighting via [flutter_highlight].
///
/// When [syntaxHighlighting] is true (default) and the [language] is
/// recognized, code is rendered with color tokens using the VS 2015 theme.
/// Falls back to plain monospace text for unrecognized languages.
class EdenCodeBlock extends StatelessWidget {
  const EdenCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.lineNumbers = false,
    this.copyable = true,
    this.syntaxHighlighting = true,
    this.streaming = false,
  });

  final String code;
  final String? language;
  final bool lineNumbers;
  final bool copyable;

  /// Whether to apply syntax highlighting. Defaults to true.
  /// When false, renders plain monospace text (same as legacy behavior).
  final bool syntaxHighlighting;

  /// When true, shows a subtle streaming indicator below the code and
  /// hides the copy button. The code body still renders live.
  final bool streaming;

  /// Resolve the language string to a highlight.js-compatible name,
  /// or null if not recognized.
  String? get _resolvedLanguage {
    if (language == null || language!.isEmpty) return null;
    final lang = language!.trim().toLowerCase();
    final mapped = _languageAliases[lang] ?? lang;
    return _supportedLanguages.contains(lang) ? mapped : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EdenColors.neutral[900],
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language label and copy button
          if (language != null || (copyable && !streaming))
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space2,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: EdenColors.neutral[700]!),
                ),
              ),
              child: Row(
                children: [
                  if (language != null)
                    Text(
                      language!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: EdenColors.neutral[400],
                      ),
                    ),
                  const Spacer(),
                  if (copyable && !streaming)
                    Semantics(
                      label: 'Copy code',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: EdenColors.neutral[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color: EdenColors.neutral[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Code body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: _buildCodeBody(),
          ),
          // Streaming indicator
          if (streaming)
            Padding(
              padding: const EdgeInsets.only(
                left: EdenSpacing.space4,
                bottom: EdenSpacing.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: EdenColors.neutral[500],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Generating...',
                    style: TextStyle(
                      fontSize: 11,
                      color: EdenColors.neutral[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeBody() {
    final resolved = syntaxHighlighting ? _resolvedLanguage : null;
    final trimmed = code.trimRight();

    if (resolved != null) {
      return _buildHighlighted(trimmed, resolved);
    }

    // Plain monospace (legacy behavior or unknown language)
    if (lineNumbers) {
      return _buildPlainWithLineNumbers(trimmed);
    }

    return Text(
      trimmed,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: EdenColors.neutral[100],
        height: 1.5,
      ),
    );
  }

  Widget _buildHighlighted(String trimmed, String lang) {
    if (lineNumbers) {
      // With line numbers: render each line with HighlightView isn't practical,
      // so fall back to plain + line numbers for now.
      return _buildPlainWithLineNumbers(trimmed);
    }

    return HighlightView(
      trimmed,
      language: lang,
      theme: vs2015Theme,
      textStyle: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.5,
      ),
    );
  }

  Widget _buildPlainWithLineNumbers(String trimmed) {
    final lines = trimmed.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        return Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${entry.key + 1}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: EdenColors.neutral[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              entry.value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: EdenColors.neutral[100],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
