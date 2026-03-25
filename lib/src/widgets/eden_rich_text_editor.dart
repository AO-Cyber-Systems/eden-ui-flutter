import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Content format for the rich text editor.
enum EdenRichTextFormat { markdown, plaintext }

/// Toolbar actions available in the editor.
enum EdenRichTextAction {
  bold,
  italic,
  underline,
  strikethrough,
  h1,
  h2,
  h3,
  bulletList,
  numberedList,
  link,
  code,
  blockquote,
  divider,
}

/// A rich text editor with formatting toolbar.
///
/// Stores content as markdown internally. Toolbar buttons wrap or prefix
/// selected text with markdown syntax. A preview toggle renders a basic
/// markdown preview.
class EdenRichTextEditor extends StatefulWidget {
  const EdenRichTextEditor({
    super.key,
    this.initialValue,
    this.onChanged,
    this.label,
    this.placeholder,
    this.errorText,
    this.format = EdenRichTextFormat.markdown,
    this.readOnly = false,
    this.minHeight = 200,
    this.maxHeight = 500,
    this.showToolbar = true,
    this.toolbarActions,
    this.enabled = true,
  });

  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? placeholder;
  final String? errorText;
  final EdenRichTextFormat format;
  final bool readOnly;
  final double minHeight;
  final double maxHeight;
  final bool showToolbar;
  final List<EdenRichTextAction>? toolbarActions;
  final bool enabled;

  @override
  State<EdenRichTextEditor> createState() => _EdenRichTextEditorState();
}

class _EdenRichTextEditorState extends State<EdenRichTextEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showPreview = false;

  static const List<EdenRichTextAction> _defaultActions = [
    EdenRichTextAction.bold,
    EdenRichTextAction.italic,
    EdenRichTextAction.underline,
    EdenRichTextAction.strikethrough,
    EdenRichTextAction.divider,
    EdenRichTextAction.h1,
    EdenRichTextAction.h2,
    EdenRichTextAction.h3,
    EdenRichTextAction.divider,
    EdenRichTextAction.bulletList,
    EdenRichTextAction.numberedList,
    EdenRichTextAction.divider,
    EdenRichTextAction.link,
    EdenRichTextAction.code,
    EdenRichTextAction.blockquote,
  ];

  List<EdenRichTextAction> get _actions =>
      widget.toolbarActions ?? _defaultActions;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? EdenColors.error
        : isDark
            ? EdenColors.neutral[600]!
            : EdenColors.neutral[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: EdenRadii.borderRadiusMd,
            color: isDark ? EdenColors.neutral[900]! : Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showToolbar && !widget.readOnly)
                _buildToolbar(theme, isDark),
              _showPreview
                  ? _buildPreview(theme, isDark)
                  : _buildEditor(theme, isDark),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space1,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? EdenColors.neutral[700]!
                : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                for (final action in _actions)
                  if (action == EdenRichTextAction.divider)
                    _buildToolbarDivider(isDark)
                  else
                    _buildToolbarButton(theme, action),
              ],
            ),
          ),
          if (widget.format == EdenRichTextFormat.markdown)
            _buildPreviewToggle(theme),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(ThemeData theme, EdenRichTextAction action) {
    final meta = _actionMeta(action);
    final isEnabled = widget.enabled && !_showPreview;

    return Tooltip(
      message: meta.tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: isEnabled ? () => _applyAction(action) : null,
          icon: Icon(meta.icon, size: 18),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          color: theme.colorScheme.onSurfaceVariant,
          disabledColor: theme.colorScheme.onSurfaceVariant
              .withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildToolbarDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
    );
  }

  Widget _buildPreviewToggle(ThemeData theme) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: () => setState(() => _showPreview = !_showPreview),
        icon: Icon(
          _showPreview ? Icons.edit_outlined : Icons.visibility_outlined,
          size: 16,
        ),
        label: Text(
          _showPreview ? 'Edit' : 'Preview',
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme, bool isDark) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        onChanged: widget.onChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: widget.format == EdenRichTextFormat.markdown
              ? null
              : null,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          contentPadding: const EdgeInsets.all(EdenSpacing.space3),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, bool isDark) {
    final content = _controller.text;
    final rendered = _renderMarkdown(content, theme);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: content.isEmpty
            ? Text(
                'Nothing to preview',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            : rendered,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toolbar actions — wrap or prefix selected text with markdown syntax
  // ---------------------------------------------------------------------------

  void _applyAction(EdenRichTextAction action) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (!selection.isValid) {
      _focusNode.requestFocus();
      return;
    }

    final selected = selection.textInside(text);
    final before = selection.textBefore(text);
    final after = selection.textAfter(text);

    String newText;
    int newStart;
    int newEnd;

    switch (action) {
      case EdenRichTextAction.bold:
        newText = '$before**$selected**$after';
        newStart = selection.start + 2;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.italic:
        newText = '$before*$selected*$after';
        newStart = selection.start + 1;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.underline:
        // Markdown does not natively support underline; use HTML tags.
        newText = '$before<u>$selected</u>$after';
        newStart = selection.start + 3;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.strikethrough:
        newText = '$before~~$selected~~$after';
        newStart = selection.start + 2;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.h1:
        newText = _prefixLine(before, after, selected, '# ');
        newStart = selection.start + 2;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.h2:
        newText = _prefixLine(before, after, selected, '## ');
        newStart = selection.start + 3;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.h3:
        newText = _prefixLine(before, after, selected, '### ');
        newStart = selection.start + 4;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.bulletList:
        newText = _prefixLine(before, after, selected, '- ');
        newStart = selection.start + 2;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.numberedList:
        newText = _prefixLine(before, after, selected, '1. ');
        newStart = selection.start + 3;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.link:
        newText = '$before[$selected](url)$after';
        newStart = selection.start + 1;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.code:
        if (selected.contains('\n')) {
          newText = '$before```\n$selected\n```$after';
          newStart = selection.start + 4;
          newEnd = newStart + selected.length;
        } else {
          newText = '$before`$selected`$after';
          newStart = selection.start + 1;
          newEnd = newStart + selected.length;
        }

      case EdenRichTextAction.blockquote:
        newText = _prefixLine(before, after, selected, '> ');
        newStart = selection.start + 2;
        newEnd = newStart + selected.length;

      case EdenRichTextAction.divider:
        return; // Not an action
    }

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
    );
    widget.onChanged?.call(newText);
    _focusNode.requestFocus();
  }

  /// Ensures the prefix is placed at the start of the current line.
  String _prefixLine(
    String before,
    String after,
    String selected,
    String prefix,
  ) {
    // If the cursor is at the beginning of a line, just prefix.
    if (before.isEmpty || before.endsWith('\n')) {
      return '$before$prefix$selected$after';
    }
    // Otherwise, insert a newline before the prefix.
    return '$before\n$prefix$selected$after';
  }

  // ---------------------------------------------------------------------------
  // Basic markdown preview renderer
  // ---------------------------------------------------------------------------

  Widget _renderMarkdown(String text, ThemeData theme) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            _inlineFormat(line.substring(4)),
            style: theme.textTheme.titleSmall,
          ),
        ));
      } else if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            _inlineFormat(line.substring(3)),
            style: theme.textTheme.titleMedium,
          ),
        ));
      } else if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            _inlineFormat(line.substring(2)),
            style: theme.textTheme.titleLarge,
          ),
        ));
      } else if (line.startsWith('> ')) {
        children.add(_buildBlockquote(theme, line.substring(2)));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        children.add(_buildListItem(theme, line.substring(2), false));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final content = line.replaceFirst(RegExp(r'^\d+\.\s'), '');
        final number = line.split('.').first;
        children.add(_buildListItem(theme, content, true, number: number));
      } else if (line.startsWith('```')) {
        // Collect code block lines.
        final codeLines = <String>[];
        int j = i + 1;
        while (j < lines.length && !lines[j].startsWith('```')) {
          codeLines.add(lines[j]);
          j++;
        }
        children.add(_buildCodeBlock(theme, codeLines.join('\n')));
        i = j; // skip past closing ```
      } else if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
      } else {
        children.add(_buildRichInlineText(theme, line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBlockquote(ThemeData theme, String text) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark
                ? EdenColors.neutral[600]!
                : EdenColors.neutral[300]!,
            width: 3,
          ),
        ),
        color: isDark
            ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
            : EdenColors.neutral[100]!,
      ),
      child: _buildRichInlineText(theme, text),
    );
  }

  Widget _buildListItem(
    ThemeData theme,
    String text,
    bool ordered, {
    String? number,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              ordered ? '$number.' : '\u2022',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(child: _buildRichInlineText(theme, text)),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(ThemeData theme, String code) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Text(
        code,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  /// Renders inline markdown formatting (bold, italic, code, strikethrough).
  Widget _buildRichInlineText(ThemeData theme, String text) {
    return Text(
      _inlineFormat(text),
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
    );
  }

  /// Strip inline markdown syntax for preview display (simplified).
  String _inlineFormat(String text) {
    // Bold: **text** or __text__
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*|__(.+?)__'),
      (m) => m.group(1) ?? m.group(2) ?? '',
    );
    // Italic: *text* or _text_
    text = text.replaceAllMapped(
      RegExp(r'\*(.+?)\*|_(.+?)_'),
      (m) => m.group(1) ?? m.group(2) ?? '',
    );
    // Strikethrough: ~~text~~
    text = text.replaceAllMapped(
      RegExp(r'~~(.+?)~~'),
      (m) => m.group(1) ?? '',
    );
    // Inline code: `text`
    text = text.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (m) => m.group(1) ?? '',
    );
    // Underline: <u>text</u>
    text = text.replaceAllMapped(
      RegExp(r'<u>(.+?)</u>'),
      (m) => m.group(1) ?? '',
    );
    // Links: [text](url) -> text
    text = text.replaceAllMapped(
      RegExp(r'\[(.+?)\]\(.+?\)'),
      (m) => m.group(1) ?? '',
    );
    return text;
  }

  _ActionMeta _actionMeta(EdenRichTextAction action) {
    switch (action) {
      case EdenRichTextAction.bold:
        return const _ActionMeta(Icons.format_bold, 'Bold');
      case EdenRichTextAction.italic:
        return const _ActionMeta(Icons.format_italic, 'Italic');
      case EdenRichTextAction.underline:
        return const _ActionMeta(Icons.format_underline, 'Underline');
      case EdenRichTextAction.strikethrough:
        return const _ActionMeta(Icons.strikethrough_s, 'Strikethrough');
      case EdenRichTextAction.h1:
        return const _ActionMeta(Icons.looks_one, 'Heading 1');
      case EdenRichTextAction.h2:
        return const _ActionMeta(Icons.looks_two, 'Heading 2');
      case EdenRichTextAction.h3:
        return const _ActionMeta(Icons.looks_3, 'Heading 3');
      case EdenRichTextAction.bulletList:
        return const _ActionMeta(Icons.format_list_bulleted, 'Bullet list');
      case EdenRichTextAction.numberedList:
        return const _ActionMeta(Icons.format_list_numbered, 'Numbered list');
      case EdenRichTextAction.link:
        return const _ActionMeta(Icons.link, 'Link');
      case EdenRichTextAction.code:
        return const _ActionMeta(Icons.code, 'Code');
      case EdenRichTextAction.blockquote:
        return const _ActionMeta(Icons.format_quote, 'Blockquote');
      case EdenRichTextAction.divider:
        return const _ActionMeta(Icons.more_horiz, 'Divider');
    }
  }
}

class _ActionMeta {
  const _ActionMeta(this.icon, this.tooltip);
  final IconData icon;
  final String tooltip;
}
