// EdenPhotoCapturePage — full-screen photo capture flow with annotation.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// photo_capture_page.dart (322 LOC). Port strips:
//   - Placeholder `_simulateCapture` fabricating a fake path → consumer's
//     `onCapture` callback returns a real `EdenCapturedPhoto`.
//   - `String? existingPhotoPath` + `String? annotation` string callbacks
//     → typed `EdenCapturedPhoto` value type for both ends.
//
// Library imports ZERO concrete camera SDKs (no `camera_awesome` /
// `image_picker` / `camera` / etc.). All capture work goes through the
// consumer-supplied callbacks.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show File;

import '../tokens/spacing.dart';

/// Immutable captured photo passed to / from [EdenPhotoCapturePage].
///
/// **Prefer [bytes] over [filePath]** for cross-platform support — `Image.file`
/// requires `dart:io` (not available on web). When [bytes] is non-null, the
/// page renders via `Image.memory`. When [bytes] is null and [filePath] is
/// supplied, the page falls back to `Image.file` on non-web platforms.
class EdenCapturedPhoto {
  const EdenCapturedPhoto({
    required this.filePath,
    this.bytes,
    this.mimeType = 'image/jpeg',
    required this.capturedAt,
  });

  final String filePath;
  final Uint8List? bytes;
  final String mimeType;
  final DateTime capturedAt;
}

/// Context passed to [EdenPhotoCapturePage]'s `onCapture` callback so the
/// consumer knows what's being photographed (appointment id, field id, etc).
class EdenPhotoCaptureRequest {
  const EdenPhotoCaptureRequest({
    this.appointmentId,
    this.fieldId,
    this.existingPhoto,
    this.suggestedCategory,
  });

  final String? appointmentId;
  final String? fieldId;
  final EdenCapturedPhoto? existingPhoto;
  final String? suggestedCategory;
}

/// Result returned via `Navigator.pop` when the user taps "Use Photo".
class EdenPhotoCaptureResult {
  const EdenPhotoCaptureResult({
    required this.photo,
    this.annotation,
    this.category,
    required this.capturedAt,
  });

  final EdenCapturedPhoto photo;
  final String? annotation;
  final String? category;
  final DateTime capturedAt;
}

/// Full-screen single-photo capture page with annotation + optional
/// categorization. Designed for companion-mode field crew flows.
///
/// **Constructor assert:** at least one of [onCapture] / [onPickFromGallery]
/// must be non-null. A page with neither is silently broken (no way to
/// produce a photo); the assert surfaces this at construction.
///
/// **State machine:**
///   - Pre-capture: shutter + gallery + flash icons; no photo preview.
///   - Capturing (`_isCapturing == true`): spinner over shutter.
///   - Post-capture: photo preview + annotation TextField + Retake / Use
///     Photo button row.
///
/// **`categoryRequired`:** only gates Use Photo POST-capture. Pre-capture
/// state is unaffected — the shutter is always tappable.
class EdenPhotoCapturePage extends StatefulWidget {
  const EdenPhotoCapturePage({
    super.key,
    this.appointmentId,
    this.fieldId,
    this.appBarTitle = 'Capture Photo',
    this.cameraPreviewBuilder,
    this.onCapture,
    this.onPickFromGallery,
    this.onToggleFlash,
    this.categories,
    this.categoryRequired = false,
  }) : assert(onCapture != null || onPickFromGallery != null,
            'EdenPhotoCapturePage requires at least one of onCapture or onPickFromGallery');

  final String? appointmentId;
  final String? fieldId;
  final String appBarTitle;
  final WidgetBuilder? cameraPreviewBuilder;
  final Future<EdenCapturedPhoto?> Function(EdenPhotoCaptureRequest)?
      onCapture;
  final Future<EdenCapturedPhoto?> Function()? onPickFromGallery;
  final VoidCallback? onToggleFlash;
  final List<String>? categories;
  final bool categoryRequired;

  @override
  State<EdenPhotoCapturePage> createState() => _EdenPhotoCapturePageState();
}

class _EdenPhotoCapturePageState extends State<EdenPhotoCapturePage> {
  EdenCapturedPhoto? _capturedPhoto;
  final _annotationController = TextEditingController();
  String? _selectedCategory;
  bool _isCapturing = false;

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (widget.onCapture == null || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final photo = await widget.onCapture!.call(EdenPhotoCaptureRequest(
        appointmentId: widget.appointmentId,
        fieldId: widget.fieldId,
        existingPhoto: _capturedPhoto,
        suggestedCategory: _selectedCategory,
      ));
      if (!mounted) return;
      if (photo != null) {
        setState(() => _capturedPhoto = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Capture failed: $e',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickGallery() async {
    if (widget.onPickFromGallery == null) return;
    try {
      final photo = await widget.onPickFromGallery!.call();
      if (!mounted) return;
      if (photo != null) {
        setState(() => _capturedPhoto = photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gallery failed: $e',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  void _retake() {
    setState(() {
      _capturedPhoto = null;
      _annotationController.clear();
      _selectedCategory = null;
    });
  }

  bool get _canUsePhoto {
    if (_capturedPhoto == null) return false;
    if (widget.categoryRequired && _selectedCategory == null) return false;
    return true;
  }

  void _confirmAndReturn() {
    if (!_canUsePhoto) return;
    final annotation = _annotationController.text.trim();
    final result = EdenPhotoCaptureResult(
      photo: _capturedPhoto!,
      annotation: annotation.isEmpty ? null : annotation,
      category: _selectedCategory,
      capturedAt: DateTime.now(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.appBarTitle),
        actions: [
          if (_capturedPhoto != null)
            TextButton(
              onPressed: _canUsePhoto ? _confirmAndReturn : null,
              child: const Text(
                'Use Photo',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreviewArea()),
          if (_capturedPhoto != null &&
              widget.categories != null &&
              widget.categories!.isNotEmpty)
            _buildCategoryChips(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_capturedPhoto == null) {
      // Pre-capture: builder OR placeholder.
      if (widget.cameraPreviewBuilder != null) {
        return widget.cameraPreviewBuilder!(context);
      }
      return const _ViewfinderPlaceholder();
    }

    // Post-capture: photo preview + annotation overlay.
    final photo = _capturedPhoto!;
    return Stack(
      children: [
        Positioned.fill(child: _photoImage(photo)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            color: Colors.black.withValues(alpha: 0.55),
            child: TextField(
              controller: _annotationController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoImage(EdenCapturedPhoto photo) {
    if (photo.bytes != null) {
      return Image.memory(photo.bytes!, fit: BoxFit.contain);
    }
    if (!kIsWeb && photo.filePath.isNotEmpty) {
      return Image.file(File(photo.filePath), fit: BoxFit.contain);
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _buildCategoryChips() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.categories!.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, index) {
            final cat = widget.categories![index];
            final selected = _selectedCategory == cat;
            return FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  _selectedCategory = val ? cat : null;
                });
              },
              backgroundColor: Colors.white12,
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: _capturedPhoto == null
          ? _preCaptureControls()
          : _postCaptureControls(),
    );
  }

  Widget _preCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Gallery
        if (widget.onPickFromGallery != null)
          IconButton(
            key: const ValueKey('eden_photo_capture_gallery'),
            iconSize: 32,
            color: Colors.white,
            onPressed: _isCapturing ? null : _pickGallery,
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from gallery',
          )
        else
          const SizedBox(width: 32),
        // Shutter
        GestureDetector(
          key: const ValueKey('eden_photo_capture_shutter'),
          onTap: _isCapturing ? null : _capture,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: _isCapturing ? Colors.white24 : Colors.transparent,
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        // Flash
        if (widget.onToggleFlash != null)
          IconButton(
            key: const ValueKey('eden_photo_capture_flash'),
            iconSize: 32,
            color: Colors.white,
            onPressed: _isCapturing ? null : widget.onToggleFlash,
            icon: const Icon(Icons.flash_auto_outlined),
            tooltip: 'Toggle flash',
          )
        else
          const SizedBox(width: 32),
      ],
    );
  }

  Widget _postCaptureControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _retake,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding:
                  const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _canUsePhoto ? _confirmAndReturn : null,
            icon: const Icon(Icons.check),
            label: const Text('Use Photo'),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPlaceholder extends StatelessWidget {
  const _ViewfinderPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white38),
            SizedBox(height: 12),
            Text(
              'Camera viewfinder placeholder',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
