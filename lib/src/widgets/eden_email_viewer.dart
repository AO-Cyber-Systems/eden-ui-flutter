import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A detailed email viewer with tabbed content for HTML, text, headers,
/// and raw source.
class EdenEmailViewer extends StatefulWidget {
  /// Creates an email viewer widget.
  const EdenEmailViewer({
    super.key,
    required this.subject,
    required this.from,
    this.to,
    this.cc,
    this.date,
    this.bodyHtml,
    this.bodyText,
    this.headersText,
    this.rawSource,
    this.attachmentCount = 0,
    this.onMarkRead,
    this.onMarkUnread,
    this.onDelete,
    this.onBack,
  });

  /// The email subject line.
  final String subject;

  /// The sender address.
  final String from;

  /// The recipient address.
  final String? to;

  /// The CC recipients.
  final String? cc;

  /// When the email was sent.
  final DateTime? date;

  /// The HTML body content.
  final String? bodyHtml;

  /// The plain text body content.
  final String? bodyText;

  /// The raw email headers.
  final String? headersText;

  /// The full raw email source.
  final String? rawSource;

  /// Number of attachments.
  final int attachmentCount;

  /// Called when mark-as-read is pressed.
  final VoidCallback? onMarkRead;

  /// Called when mark-as-unread is pressed.
  final VoidCallback? onMarkUnread;

  /// Called when delete is pressed.
  final VoidCallback? onDelete;

  /// Called when back is pressed.
  final VoidCallback? onBack;

  @override
  State<EdenEmailViewer> createState() => _EdenEmailViewerState();
}

class _EdenEmailViewerState extends State<EdenEmailViewer> {
  int _selectedTab = 0;

  List<_TabEntry> get _availableTabs {
    final tabs = <_TabEntry>[];
    if (widget.bodyHtml != null) {
      tabs.add(_TabEntry('HTML', widget.bodyHtml!));
    }
    if (widget.bodyText != null) {
      tabs.add(_TabEntry('Text', widget.bodyText!));
    }
    if (widget.headersText != null) {
      tabs.add(_TabEntry('Headers', widget.headersText!));
    }
    if (widget.rawSource != null) {
      tabs.add(_TabEntry('Source', widget.rawSource!));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = _availableTabs;

    if (_selectedTab >= tabs.length) {
      _selectedTab = 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          _buildMetadata(theme, isDark),
          if (tabs.isNotEmpty) ...[
            _buildTabBar(theme, isDark, tabs),
            Expanded(child: _buildTabContent(theme, isDark, tabs)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: EdenSpacing.space2),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: 'Back',
              ),
            ),
          Expanded(
            child: Text(
              widget.subject,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.onMarkRead != null)
            IconButton(
              icon: const Icon(Icons.mark_email_read_outlined),
              onPressed: widget.onMarkRead,
              tooltip: 'Mark as read',
            ),
          if (widget.onMarkUnread != null)
            IconButton(
              icon: const Icon(Icons.mark_email_unread_outlined),
              onPressed: widget.onMarkUnread,
              tooltip: 'Mark as unread',
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: EdenColors.error),
              onPressed: widget.onDelete,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme, bool isDark) {
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: EdenColors.neutral[500],
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodyMedium;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          _metadataRow('From', widget.from, labelStyle, valueStyle),
          if (widget.to != null)
            _metadataRow('To', widget.to!, labelStyle, valueStyle),
          if (widget.cc != null)
            _metadataRow('CC', widget.cc!, labelStyle, valueStyle),
          if (widget.date != null)
            _metadataRow(
              'Date',
              widget.date.toString(),
              labelStyle,
              valueStyle,
            ),
          if (widget.attachmentCount > 0)
            _metadataRow(
              'Attachments',
              '${widget.attachmentCount}',
              labelStyle,
              valueStyle,
            ),
        ],
      ),
    );
  }

  Widget _metadataRow(
    String label,
    String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: labelStyle),
          ),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark, List<_TabEntry> tabs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            _tabButton(theme, isDark, tabs[i].label, i),
        ],
      ),
    );
  }

  Widget _tabButton(ThemeData theme, bool isDark, String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.primary
                : EdenColors.neutral[500],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme, bool isDark, List<_TabEntry> tabs) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final content = tabs[_selectedTab].content;
    final isHtml = tabs[_selectedTab].label == 'HTML';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: SelectableText(
        content,
        style: isHtml
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
      ),
    );
  }
}

class _TabEntry {
  const _TabEntry(this.label, this.content);

  final String label;
  final String content;
}
