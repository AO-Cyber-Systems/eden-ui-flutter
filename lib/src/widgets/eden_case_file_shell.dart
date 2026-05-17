import 'package:flutter/material.dart';

import 'eden_audit_log_viewer.dart';
import 'eden_classification_banner.dart';
import 'eden_file_upload.dart' show EdenUploadStatus;

/// A single document attached to a case file.
@immutable
class EdenCaseFileDocument {
  const EdenCaseFileDocument({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
    this.status = EdenUploadStatus.complete,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;
  final EdenUploadStatus status;
}

/// A contact associated with a case file (subject, witness, counsel, etc.).
@immutable
class EdenCaseFileContact {
  const EdenCaseFileContact({
    required this.id,
    required this.name,
    required this.role,
    this.contactInfo = const {},
  });

  final String id;
  final String name;
  final String role;
  final Map<String, String> contactInfo;
}

/// A note attached to a case file.
///
/// When [isPrivileged] is true (e.g. attorney-client privileged
/// communication), the note renders with an inline `PRIVILEGED`
/// classification banner.
@immutable
class EdenCaseFileNote {
  const EdenCaseFileNote({
    required this.id,
    required this.author,
    required this.timestamp,
    required this.content,
    this.isPrivileged = false,
  });

  final String id;
  final String author;
  final DateTime timestamp;
  final String content;
  final bool isPrivileged;
}

/// A single Activity entry for the Activity tab of [EdenCaseFileShell].
///
/// Lightweight by design (the shell doesn't compose `EdenActivityFeed`
/// to avoid pulling in mention/comment features). For richer activity
/// UX outside the case-file context, use `EdenActivityFeed`.
@immutable
class EdenCaseFileActivity {
  const EdenCaseFileActivity({
    required this.id,
    required this.actor,
    required this.timestamp,
    required this.title,
    this.body,
  });

  final String id;
  final String actor;
  final DateTime timestamp;
  final String title;
  final String? body;
}

/// The data payload for [EdenCaseFileShell].
@immutable
class EdenCaseFileData {
  const EdenCaseFileData({
    required this.caseId,
    required this.caseTitle,
    required this.status,
    required this.openedAt,
    this.classification,
    this.assignedTo,
    this.headerMetadata = const {},
    this.activityEntries,
    this.documents,
    this.contacts,
    this.notes,
    this.auditEntries,
  });

  final String caseId;
  final String caseTitle;
  final String status;
  final DateTime openedAt;

  /// Optional ICD 710 classification. When non-null, the entire shell
  /// is wrapped in [EdenClassificationBannerScaffold].
  final EdenClassificationLevel? classification;

  final String? assignedTo;
  final Map<String, String> headerMetadata;
  final List<EdenCaseFileActivity>? activityEntries;
  final List<EdenCaseFileDocument>? documents;
  final List<EdenCaseFileContact>? contacts;
  final List<EdenCaseFileNote>? notes;
  final List<EdenAuditLogEntry>? auditEntries;
}

/// Multi-tab regulated dossier composite — the Objective 011 capstone.
///
/// Composes:
///   - [EdenClassificationBannerScaffold] (011-01) for optional
///     classification overlay.
///   - [EdenAuditLogViewer] (011-04) as the `Audit` tab.
///   - [EdenClassificationBanner] (011-01) inline for `PRIVILEGED` notes.
///
/// Six standard tabs: Overview / Activity / Documents / Contacts / Notes
/// / Audit. Each tab has an empty-state for missing/empty data.
///
/// Federal use: DHHS social services case, DOJ case file, IG investigation,
/// patient chart, legal matter.
///
/// Civilian re-use: same shell serves any complex dossier workflow —
/// legal matters, insurance claims, enterprise CRM contact records.
class EdenCaseFileShell extends StatelessWidget {
  const EdenCaseFileShell({super.key, required this.data});

  final EdenCaseFileData data;

  String _formatDate(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)}';
  }

  String _formatDateTime(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${_formatDate(t)} ${pad(t.hour)}:${pad(t.minute)}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(data: data),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Activity'),
              Tab(text: 'Documents'),
              Tab(text: 'Contacts'),
              Tab(text: 'Notes'),
              Tab(text: 'Audit'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(
                  data: data,
                  formatDate: _formatDate,
                ),
                _ActivityTab(
                  data: data,
                  formatDateTime: _formatDateTime,
                ),
                _DocumentsTab(
                  data: data,
                  formatDateTime: _formatDateTime,
                  formatSize: _formatSize,
                ),
                _ContactsTab(data: data),
                _NotesTab(
                  data: data,
                  formatDateTime: _formatDateTime,
                ),
                _AuditTab(data: data),
              ],
            ),
          ),
        ],
      ),
    );

    if (data.classification != null) {
      return EdenClassificationBannerScaffold(
        level: data.classification!,
        child: body,
      );
    }
    return body;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});
  final EdenCaseFileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  data.caseTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.caseId,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data, required this.formatDate});
  final EdenCaseFileData data;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _KvRow(label: 'Opened', value: formatDate(data.openedAt)),
      if (data.assignedTo != null)
        _KvRow(label: 'Assigned to', value: data.assignedTo!),
      ...data.headerMetadata.entries
          .map((kv) => _KvRow(label: kv.key, value: kv.value)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.data, required this.formatDateTime});
  final EdenCaseFileData data;
  final String Function(DateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final entries = data.activityEntries ?? const [];
    if (entries.isEmpty) {
      return const Center(child: Text('No activity yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, idx) {
        final a = entries[idx];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.history),
          title: Text(a.title, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${a.actor} · ${formatDateTime(a.timestamp)}',
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({
    required this.data,
    required this.formatDateTime,
    required this.formatSize,
  });
  final EdenCaseFileData data;
  final String Function(DateTime) formatDateTime;
  final String Function(int) formatSize;

  @override
  Widget build(BuildContext context) {
    final docs = data.documents ?? const [];
    if (docs.isEmpty) {
      return const Center(child: Text('No documents yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final d = docs[idx];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(d.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${formatSize(d.sizeBytes)} · ${d.uploadedBy} · ${formatDateTime(d.uploadedAt)}',
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            d.status.name,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.data});
  final EdenCaseFileData data;

  @override
  Widget build(BuildContext context) {
    final contacts = data.contacts ?? const [];
    if (contacts.isEmpty) {
      return const Center(child: Text('No contacts yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: contacts.length,
      itemBuilder: (context, idx) {
        final c = contacts[idx];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.person_outline),
          title: Text(c.name, style: const TextStyle(fontSize: 13)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.role,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...c.contactInfo.entries.map(
                (kv) => Text(
                  '${kv.key}: ${kv.value}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.data, required this.formatDateTime});
  final EdenCaseFileData data;
  final String Function(DateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final notes = data.notes ?? const [];
    if (notes.isEmpty) {
      return const Center(child: Text('No notes yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notes.length,
      itemBuilder: (context, idx) {
        final n = notes[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (n.isPrivileged)
                const EdenClassificationBanner(
                  level: EdenClassificationLevel.custom,
                  labelText: 'PRIVILEGED',
                  backgroundColor: Color(0xFF6B21A8),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${n.author} · ${formatDateTime(n.timestamp)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.content,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.data});
  final EdenCaseFileData data;

  @override
  Widget build(BuildContext context) {
    final entries = data.auditEntries ?? const [];
    return EdenAuditLogViewer(entries: entries, showFilters: false);
  }
}
