// EdenMediaPickerView — pure presentational upload/browse widget.
//
// Upstreamed from eden-biz CMS Studio (CMS-FE-04) into eden-ui-flutter.
// This file contains NO Riverpod, NO ConnectRPC, NO dart:html — it is safe to
// import in tests without triggering framework-specific compile cascades.
//
// The caller injects all IO as callbacks:
//   - uploadFn:          async ({filename, contentType, bytes}) → CDN URL string
//   - pickFileFn:        async () → PickedFile? (abstracted so tests skip dart:html)
//   - onUrlSelected:     callback when an asset URL is chosen or uploaded
//   - allowedMimeTypes:  closed set of accepted MIME types (defaults to common images)
//   - maxUploadBytes:    size gate (default 10 MB), shown in the format hint
//
// Two-tab layout:
//   Tab 0 — Library: EdenEmptyState stub until a real browseFn is wired
//             (ListMedia / equivalent backend RPC does not exist in generic form).
//   Tab 1 — Upload: file picker → uploadFn → CDN URL → onUrlSelected callback.
//
// Consumer wiring example (eden-biz CMS Studio):
//   EdenMediaPickerModal.show(context, ref: ref, onUrlSelected: (url) { ... });
//
// Consumer wiring example (mobile ID capture — future):
//   EdenMediaPickerView(
//     uploadFn: myPresignedUploadFn,
//     pickFileFn: myNativeFilePicker,
//     onUrlSelected: (url) => controller.attachIdPhoto(url),
//     allowedMimeTypes: const ['image/jpeg', 'image/png'],
//   );

import 'package:flutter/material.dart';

import 'eden_empty_state.dart';
import 'eden_button.dart';
import 'eden_inline_error_banner.dart';
import 'eden_spinner.dart';
import 'eden_toast.dart';

// ---------------------------------------------------------------------------
// PickedFile — cross-platform file abstraction
//
// Production implementations supply bytes from dart:html InputElement (web)
// or file_selector (native). Tests supply PickedFile directly via pickFileFn.
// ---------------------------------------------------------------------------

/// Cross-platform file representation passed to [UploadFn].
///
/// Name and mimeType are used for MIME validation and RPC request building.
/// Bytes are the raw file contents for the presigned-URL PUT payload.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final List<int> bytes;
}

// ---------------------------------------------------------------------------
// Callback type aliases — injected by caller, mocked in tests
// ---------------------------------------------------------------------------

/// Upload function signature — injected by the calling screen/modal.
///
/// Accepts file metadata + raw bytes; returns the public CDN URL for the
/// uploaded asset. Throws on RPC error or PUT failure.
///
/// Example (eden-biz UploadMedia RPC + presigned PUT + CDN URL derivation):
/// ```dart
/// Future<String> uploadFn({required filename, required contentType, required bytes}) async {
///   final resp = await client.uploadMedia(UploadMediaRequest(...));
///   await http.put(Uri.parse(resp.uploadUrl), body: Uint8List.fromList(bytes), ...);
///   return '${AppConfig.mediaCdnUrl}/${resp.storageKey}';
/// }
/// ```
typedef UploadFn = Future<String> Function({
  required String filename,
  required String contentType,
  required List<int> bytes,
});

/// File picker function signature — injected by the calling screen/modal.
///
/// Returns null if the user cancelled. Returns a [PickedFile] if a file was
/// chosen. The abstraction lets tests inject a PickedFile directly without
/// touching platform file-picker APIs.
typedef PickFileFn = Future<PickedFile?> Function();

// ---------------------------------------------------------------------------
// Default constants — mirrors the values from eden-biz cms_constants.dart
// (locked contract CMS-BE-01). Callers may override via constructor params.
// ---------------------------------------------------------------------------

/// Default allowed image MIME types.
const kEdenMediaPickerDefaultMimeTypes = <String>[
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/svg+xml',
];

/// Human-readable label for [kEdenMediaPickerDefaultMimeTypes].
const kEdenMediaPickerDefaultFormatsLabel = 'JPG, PNG, WebP, GIF, SVG';

/// Default maximum upload size in bytes (10 MB).
const kEdenMediaPickerDefaultMaxBytes = 10 * 1024 * 1024;

// ---------------------------------------------------------------------------
// EdenMediaPickerView — pure presentational widget
// ---------------------------------------------------------------------------

/// A tabbed upload/browse widget for selecting or uploading media assets.
///
/// Render this widget directly inside a modal, sheet, or full-screen page.
/// For a convenience modal wrapper see `EdenMediaPickerModal` in eden-biz.
///
/// All IO is injected via callbacks — no Riverpod, no ConnectRPC, no dart:html.
class EdenMediaPickerView extends StatefulWidget {
  const EdenMediaPickerView({
    super.key,
    required this.uploadFn,
    required this.pickFileFn,
    required this.onUrlSelected,
    this.allowedMimeTypes = kEdenMediaPickerDefaultMimeTypes,
    this.maxUploadBytes = kEdenMediaPickerDefaultMaxBytes,
  });

  /// Async function that uploads a file and returns its public CDN URL.
  final UploadFn uploadFn;

  /// Async function that opens the platform file picker.
  final PickFileFn pickFileFn;

  /// Called when an asset URL is selected or uploaded.
  final void Function(String url) onUrlSelected;

  /// Closed set of accepted MIME types. Validated client-side before upload.
  /// Defaults to [kEdenMediaPickerDefaultMimeTypes].
  final List<String> allowedMimeTypes;

  /// Maximum upload size in bytes. Shown in the format hint.
  /// Defaults to [kEdenMediaPickerDefaultMaxBytes] (10 MB).
  final int maxUploadBytes;

  @override
  State<EdenMediaPickerView> createState() => _EdenMediaPickerViewState();
}

class _EdenMediaPickerViewState extends State<EdenMediaPickerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    // Default to Upload tab (index 1) — primary user action is uploading.
    _tabs = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Upload flow
  // ---------------------------------------------------------------------------

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploadError = null;
    });

    // 1. Pick a file via injected pickFileFn.
    final picked = await widget.pickFileFn();
    if (picked == null) return; // user cancelled — no error

    // 2. Validate MIME type (client-side, before calling upload).
    final mimeType = picked.mimeType.toLowerCase();
    final allowed = widget.allowedMimeTypes.any((m) => mimeType == m);

    if (!allowed) {
      final label = _buildFormatsLabel();
      setState(() {
        _uploadError = 'Please select an image file ($label)';
      });
      return;
    }

    // 3. Upload via injected uploadFn.
    setState(() {
      _isUploading = true;
    });

    try {
      final cdnUrl = await widget.uploadFn(
        filename: picked.name,
        contentType: picked.mimeType,
        bytes: picked.bytes,
      );

      if (!mounted) return;

      // 4. Success — notify caller and show toast.
      widget.onUrlSelected(cdnUrl);
      EdenToast.show(
        context,
        message: 'Uploaded ${picked.name}',
        variant: EdenToastVariant.success,
      );
    } catch (e) {
      if (!mounted) return;

      // 5. Error — show inline banner (modal/view stays open).
      setState(() {
        _uploadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Derives a human-readable formats label from [allowedMimeTypes].
  /// Falls back to the default label when the set matches the default.
  String _buildFormatsLabel() {
    if (widget.allowedMimeTypes == kEdenMediaPickerDefaultMimeTypes) {
      return kEdenMediaPickerDefaultFormatsLabel;
    }
    return widget.allowedMimeTypes
        .map((m) => m.split('/').last.toUpperCase())
        .join(', ');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Library'),
              Tab(text: 'Upload'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildLibraryTab(),
                _buildUploadTab(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EdenButton(
                label: 'Cancel',
                variant: EdenButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Library tab — stub until a browseFn callback is added in a future wave
  // ---------------------------------------------------------------------------

  Widget _buildLibraryTab() {
    return const EdenEmptyState(
      title: 'Media library',
      description: 'Media browsing coming soon. Use the Upload tab to add images.',
      icon: Icons.photo_library_outlined,
    );
  }

  // ---------------------------------------------------------------------------
  // Upload tab
  // ---------------------------------------------------------------------------

  Widget _buildUploadTab() {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EdenSpinner(size: EdenSpinnerSize.md),
            SizedBox(height: 12),
            Text('Uploading…'),
          ],
        ),
      );
    }

    final formatsLabel = _buildFormatsLabel();
    final maxMb = widget.maxUploadBytes ~/ (1024 * 1024);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Error banner — shown when upload fails or MIME is invalid
          if (_uploadError != null) ...[
            EdenInlineErrorBanner(
              message: _uploadError!,
              onDismiss: () => setState(() => _uploadError = null),
            ),
            const SizedBox(height: 16),
          ],

          // File picker button
          Center(
            child: EdenButton(
              label: 'Choose file',
              icon: Icons.upload_file_outlined,
              onPressed: _pickAndUpload,
            ),
          ),
          const SizedBox(height: 12),

          // Format hint
          Center(
            child: Text(
              'Supported: $formatsLabel  ·  Max $maxMb MB',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
