import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Display mode for the markdown editor.
enum EdenMarkdownEditorMode { edit, preview, split }

/// Markdown editor with formatting toolbar.
class EdenMarkdownEditor extends StatefulWidget {
  const EdenMarkdownEditor({
    super.key,
    this.controller,
    this.onChanged,
    this.mode = EdenMarkdownEditorMode.edit,
    this.onModeChanged,
    this.minLines = 8,
    this.maxLines,
    this.placeholder = 'Write something...',
    this.previewBuilder,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final EdenMarkdownEditorMode mode;
  final ValueChanged<EdenMarkdownEditorMode>? onModeChanged;
  final int minLines;
  final int? maxLines;
  final String placeholder;
  final Widget Function(String markdown)? previewBuilder;

  @override
  State<EdenMarkdownEditor> createState() => _EdenMarkdownEditorState();
}

class _EdenMarkdownEditorState extends State<EdenMarkdownEditor> {
  late TextEditingController _controller;
  late EdenMarkdownEditorMode _mode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _mode = widget.mode;
  }

  @override
  void didUpdateWidget(EdenMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
    }
    if (widget.mode != oldWidget.mode) {
      _mode = widget.mode;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(theme, isDark),
          Divider(
            height: 1,
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
          ),
          _buildBody(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? EdenColors.neutral[800]! : EdenColors.neutral[50]!,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      child: Row(
        children: [
          Expanded(
            child: EdenMarkdownToolbar(
              controller: _controller,
              onChanged: widget.onChanged,
            ),
          ),
          _buildModeToggle(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme, bool isDark) {
    Widget modeButton(EdenMarkdownEditorMode m, IconData icon, String tip) {
      final active = _mode == m;
      return Tooltip(
        message: tip,
        child: InkWell(
          borderRadius: EdenRadii.borderRadiusSm,
          onTap: () {
            setState(() => _mode = m);
            widget.onModeChanged?.call(m);
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: active
                  ? theme.colorScheme.primary
                  : (isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1,
          height: 20,
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
        modeButton(EdenMarkdownEditorMode.edit, Icons.edit_outlined, 'Edit'),
        modeButton(EdenMarkdownEditorMode.preview, Icons.visibility_outlined, 'Preview'),
        modeButton(EdenMarkdownEditorMode.split, Icons.vertical_split_outlined, 'Split'),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    switch (_mode) {
      case EdenMarkdownEditorMode.edit:
        return _buildEditor(theme, isDark);
      case EdenMarkdownEditorMode.preview:
        return _buildPreview(theme, isDark);
      case EdenMarkdownEditorMode.split:
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildEditor(theme, isDark)),
              VerticalDivider(
                width: 1,
                color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
              ),
              Expanded(child: _buildPreview(theme, isDark)),
            ],
          ),
        );
    }
  }

  Widget _buildEditor(ThemeData theme, bool isDark) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _wrapSelection('**', '**'),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _wrapSelection('_', '_'),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _wrapSelection('**', '**'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _wrapSelection('_', '_'),
      },
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        minLines: widget.minLines,
        maxLines: widget.maxLines ?? widget.minLines * 2,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
          ),
          contentPadding: const EdgeInsets.all(EdenSpacing.space3),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.colorScheme.onSurface,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, bool isDark) {
    if (widget.previewBuilder != null) {
      return Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: widget.previewBuilder!(_controller.text),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Text(
        _controller.text.isEmpty ? 'Nothing to preview' : _controller.text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: _controller.text.isEmpty
              ? (isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!)
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _wrapSelection(String before, String after) {
    final text = _controller.text;
    final sel = _controller.selection;

    if (!sel.isValid || sel.isCollapsed) {
      final offset = sel.baseOffset;
      final newText = '$before$after';
      _controller.text = text.substring(0, offset) + newText + text.substring(offset);
      _controller.selection = TextSelection.collapsed(offset: offset + before.length);
    } else {
      final selected = text.substring(sel.start, sel.end);
      final newText = '$before$selected$after';
      _controller.text = text.substring(0, sel.start) + newText + text.substring(sel.end);
      _controller.selection = TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      );
    }
    widget.onChanged?.call(_controller.text);
  }
}

/// Standalone toolbar for markdown formatting.
class EdenMarkdownToolbar extends StatelessWidget {
  const EdenMarkdownToolbar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[600]!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolbarButton(Icons.format_bold, 'Bold', () => _wrap('**', '**'), iconColor),
          _toolbarButton(Icons.format_italic, 'Italic', () => _wrap('_', '_'), iconColor),
          _toolbarButton(Icons.strikethrough_s, 'Strikethrough', () => _wrap('~~', '~~'), iconColor),
          _divider(isDark),
          _toolbarButton(Icons.title, 'H1', () => _prefix('# '), iconColor),
          _toolbarButton(Icons.text_fields, 'H2', () => _prefix('## '), iconColor),
          _toolbarButton(Icons.text_format, 'H3', () => _prefix('### '), iconColor),
          _divider(isDark),
          _toolbarButton(Icons.format_list_bulleted, 'Bullet list', () => _prefix('- '), iconColor),
          _toolbarButton(Icons.format_list_numbered, 'Numbered list', () => _prefix('1. '), iconColor),
          _divider(isDark),
          _toolbarButton(Icons.code, 'Code', () => _wrap('`', '`'), iconColor),
          _toolbarButton(Icons.format_quote, 'Blockquote', () => _prefix('> '), iconColor),
          _toolbarButton(Icons.link, 'Link', () => _insertLink(), iconColor),
          _divider(isDark),
          _toolbarButton(Icons.horizontal_rule, 'Divider', () => _insert('\n---\n'), iconColor),
        ],
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onPressed, Color color) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: EdenRadii.borderRadiusSm,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _wrap(String before, String after) {
    final text = controller.text;
    final sel = controller.selection;

    if (!sel.isValid || sel.isCollapsed) {
      final offset = sel.baseOffset;
      final newText = '$before$after';
      controller.text = text.substring(0, offset) + newText + text.substring(offset);
      controller.selection = TextSelection.collapsed(offset: offset + before.length);
    } else {
      final selected = text.substring(sel.start, sel.end);
      final replacement = '$before$selected$after';
      controller.text = text.substring(0, sel.start) + replacement + text.substring(sel.end);
      controller.selection = TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      );
    }
    onChanged?.call(controller.text);
  }

  void _prefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    final offset = sel.isValid ? sel.baseOffset : text.length;

    // Find the start of the current line
    int lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    controller.text = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    controller.selection = TextSelection.collapsed(offset: offset + prefix.length);
    onChanged?.call(controller.text);
  }

  void _insert(String content) {
    final text = controller.text;
    final sel = controller.selection;
    final offset = sel.isValid ? sel.baseOffset : text.length;

    controller.text = text.substring(0, offset) + content + text.substring(offset);
    controller.selection = TextSelection.collapsed(offset: offset + content.length);
    onChanged?.call(controller.text);
  }

  void _insertLink() {
    final text = controller.text;
    final sel = controller.selection;

    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final replacement = '[$selected](url)';
      controller.text = text.substring(0, sel.start) + replacement + text.substring(sel.end);
      controller.selection = TextSelection(
        baseOffset: sel.start + selected.length + 3,
        extentOffset: sel.start + selected.length + 6,
      );
    } else {
      final offset = sel.isValid ? sel.baseOffset : text.length;
      const linkText = '[text](url)';
      controller.text = text.substring(0, offset) + linkText + text.substring(offset);
      controller.selection = TextSelection(
        baseOffset: offset + 1,
        extentOffset: offset + 5,
      );
    }
    onChanged?.call(controller.text);
  }
}
