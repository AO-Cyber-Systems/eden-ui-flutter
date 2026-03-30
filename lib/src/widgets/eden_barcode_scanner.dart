import 'barcode_scanner/barcode_scanner_overlays.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Data models & enums
// ---------------------------------------------------------------------------

/// Supported barcode format.
enum EdenBarcodeFormat {
  qrCode('QR Code'),
  code128('Code 128'),
  code39('Code 39'),
  ean13('EAN-13'),
  ean8('EAN-8'),
  upcA('UPC-A'),
  upcE('UPC-E'),
  pdf417('PDF417'),
  dataMatrix('Data Matrix'),
  aztec('Aztec');

  const EdenBarcodeFormat(this.label);

  /// Human-readable name.
  final String label;
}

/// Scanning mode.
enum EdenScanMode {
  /// Stop after the first barcode is detected.
  single,

  /// Keep scanning continuously.
  continuous,
}

/// Current scanner status.
enum EdenScannerStatus {
  /// Actively scanning.
  scanning,

  /// A barcode has been detected.
  detected,

  /// No barcode found after a scan attempt.
  notFound,

  /// Idle / waiting.
  idle,
}

/// A record of a previously scanned barcode.
class EdenScanRecord {
  /// Creates a scan record.
  const EdenScanRecord({
    required this.value,
    required this.format,
    required this.timestamp,
  });

  /// The barcode payload.
  final String value;

  /// Detected format.
  final EdenBarcodeFormat format;

  /// When the scan occurred.
  final DateTime timestamp;
}

// ---------------------------------------------------------------------------
// EdenBarcodeScanner
// ---------------------------------------------------------------------------

/// A barcode scanner UI that renders a viewfinder overlay, scanning animation,
/// controls, result display, and scan history on top of a consumer-provided
/// camera preview widget.
///
/// The actual camera access is delegated to [cameraPreview] so that this
/// library remains free of platform plugins.
class EdenBarcodeScanner extends StatefulWidget {
  /// Creates an Eden barcode scanner.
  const EdenBarcodeScanner({
    super.key,
    required this.cameraPreview,
    this.status = EdenScannerStatus.idle,
    this.scanMode = EdenScanMode.single,
    this.scannedValue,
    this.scannedFormat,
    this.supportedFormats = const [
      EdenBarcodeFormat.qrCode,
      EdenBarcodeFormat.code128,
      EdenBarcodeFormat.ean13,
    ],
    this.history = const [],
    this.isFlashOn = false,
    this.isFrontCamera = false,
    this.showHistory = false,
    this.showManualEntry = false,
    this.viewfinderSize = 260,
    this.onBarcodeDetected,
    this.onManualEntry,
    this.onFlashToggle,
    this.onCameraSwitch,
    this.onConfirm,
    this.onRetry,
    this.onHistoryItemTap,
    this.onScanModeChanged,
  });

  /// Consumer-provided camera preview widget.
  final Widget cameraPreview;

  /// Current scanner status.
  final EdenScannerStatus status;

  /// Whether to scan once or continuously.
  final EdenScanMode scanMode;

  /// The most recently detected barcode value.
  final String? scannedValue;

  /// The most recently detected barcode format.
  final EdenBarcodeFormat? scannedFormat;

  /// Formats this scanner supports — shown as badges.
  final List<EdenBarcodeFormat> supportedFormats;

  /// Recent scan history.
  final List<EdenScanRecord> history;

  /// Flash (torch) state.
  final bool isFlashOn;

  /// Whether the front camera is active.
  final bool isFrontCamera;

  /// Whether to show the history panel.
  final bool showHistory;

  /// Whether to show the manual entry field.
  final bool showManualEntry;

  /// Width and height of the viewfinder rectangle.
  final double viewfinderSize;

  // Callbacks -----------------------------------------------------------------

  /// Called when a barcode is detected, with its raw value.
  final ValueChanged<String>? onBarcodeDetected;

  /// Called when the user submits a manually typed barcode.
  final ValueChanged<String>? onManualEntry;

  /// Called when the flash button is toggled.
  final VoidCallback? onFlashToggle;

  /// Called when the camera switch button is tapped.
  final VoidCallback? onCameraSwitch;

  /// Called when the user confirms a scanned result.
  final ValueChanged<String>? onConfirm;

  /// Called when the user wants to retry scanning.
  final VoidCallback? onRetry;

  /// Called when a history item is tapped, with its value.
  final ValueChanged<String>? onHistoryItemTap;

  /// Called when the scan mode is toggled.
  final ValueChanged<EdenScanMode>? onScanModeChanged;

  @override
  State<EdenBarcodeScanner> createState() => _EdenBarcodeScannerState();
}

class _EdenBarcodeScannerState extends State<EdenBarcodeScanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLinePosition;
  final TextEditingController _manualController = TextEditingController();
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _showManualInput = widget.showManualEntry;

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanLinePosition = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.status == EdenScannerStatus.scanning) {
      _scanLineController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EdenBarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == EdenScannerStatus.scanning &&
        !_scanLineController.isAnimating) {
      _scanLineController.repeat(reverse: true);
    } else if (widget.status != EdenScannerStatus.scanning &&
        _scanLineController.isAnimating) {
      _scanLineController.stop();
    }
    if (widget.showManualEntry != oldWidget.showManualEntry) {
      setState(() => _showManualInput = widget.showManualEntry);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Positioned.fill(child: widget.cameraPreview),

        // Viewfinder overlay
        Positioned.fill(
          child: CustomPaint(
            painter: ViewfinderPainter(
              viewfinderSize: widget.viewfinderSize,
              overlayColor: Colors.black.withValues(alpha: 0.55),
              borderColor: widget.status == EdenScannerStatus.detected
                  ? EdenColors.emerald
                  : Colors.white,
              cornerLength: 24,
              cornerWidth: 3,
            ),
          ),
        ),

        // Scanning line animation
        if (widget.status == EdenScannerStatus.scanning)
          _buildScanLine(theme),

        // Top controls bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildTopBar(theme, isDark),
          ),
        ),

        // Status message
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.5 +
              widget.viewfinderSize / 2 +
              EdenSpacing.space4,
          child: _buildStatusMessage(theme, isDark),
        ),

        // Format badges
        if (widget.supportedFormats.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.5 +
                widget.viewfinderSize / 2 +
                EdenSpacing.space12,
            child: _buildFormatBadges(theme, isDark),
          ),

        // Bottom panel: result, manual entry, history
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: _buildBottomPanel(theme, isDark),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Scanning line
  // ---------------------------------------------------------------------------

  Widget _buildScanLine(ThemeData theme) {
    return AnimatedBuilder(
      animation: _scanLinePosition,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final topOffset = size.height / 2 -
            widget.viewfinderSize / 2 +
            _scanLinePosition.value * widget.viewfinderSize;
        final leftOffset = size.width / 2 - widget.viewfinderSize / 2 + 4;

        return Positioned(
          top: topOffset,
          left: leftOffset,
          child: Container(
            width: widget.viewfinderSize - 8,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  EdenColors.emerald.withValues(alpha: 0.8),
                  EdenColors.emerald,
                  EdenColors.emerald.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: EdenColors.emerald.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Scan mode toggle
          GestureDetector(
            onTap: () {
              final newMode = widget.scanMode == EdenScanMode.single
                  ? EdenScanMode.continuous
                  : EdenScanMode.single;
              widget.onScanModeChanged?.call(newMode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
                vertical: EdenSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: EdenRadii.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.scanMode == EdenScanMode.continuous
                        ? Icons.repeat
                        : Icons.crop_free,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: EdenSpacing.space1),
                  Text(
                    widget.scanMode == EdenScanMode.continuous
                        ? 'Continuous'
                        : 'Single',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flash toggle
              _circleButton(
                icon: widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
                isActive: widget.isFlashOn,
                onTap: widget.onFlashToggle,
                theme: theme,
              ),
              const SizedBox(width: EdenSpacing.space3),
              // Camera switch
              _circleButton(
                icon: Icons.cameraswitch_outlined,
                isActive: false,
                onTap: widget.onCameraSwitch,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? EdenColors.gold.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.5),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status message
  // ---------------------------------------------------------------------------

  Widget _buildStatusMessage(ThemeData theme, bool isDark) {
    String message;
    Color color;

    switch (widget.status) {
      case EdenScannerStatus.scanning:
        message = 'Scanning...';
        color = Colors.white;
      case EdenScannerStatus.detected:
        message = 'Barcode detected';
        color = EdenColors.emerald;
      case EdenScannerStatus.notFound:
        message = 'No barcode found';
        color = EdenColors.red;
      case EdenScannerStatus.idle:
        message = 'Point camera at a barcode';
        color = Colors.white.withValues(alpha: 0.7);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: EdenRadii.borderRadiusFull,
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Format badges
  // ---------------------------------------------------------------------------

  Widget _buildFormatBadges(ThemeData theme, bool isDark) {
    return Center(
      child: Wrap(
        spacing: EdenSpacing.space1,
        runSpacing: EdenSpacing.space1,
        alignment: WrapAlignment.center,
        children: widget.supportedFormats.map((format) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: EdenRadii.borderRadiusSm,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              format.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom panel
  // ---------------------------------------------------------------------------

  Widget _buildBottomPanel(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.xl),
          topRight: Radius.circular(EdenRadii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? EdenColors.neutral[600] : EdenColors.neutral[300],
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
              ),
            ),
            const SizedBox(height: EdenSpacing.space3),

            // Scanned result
            if (widget.scannedValue != null)
              _buildResultCard(theme, isDark),

            // Manual entry toggle / input
            if (_showManualInput) ...[
              if (widget.scannedValue != null)
                const SizedBox(height: EdenSpacing.space3),
              _buildManualEntry(theme, isDark),
            ] else ...[
              const SizedBox(height: EdenSpacing.space2),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showManualInput = true),
                  child: Text(
                    'Enter barcode manually',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Scan history
            if (widget.showHistory && widget.history.isNotEmpty) ...[
              const SizedBox(height: EdenSpacing.space4),
              _buildHistorySection(theme, isDark),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result card
  // ---------------------------------------------------------------------------

  Widget _buildResultCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: widget.status == EdenScannerStatus.detected
              ? EdenColors.emerald.withValues(alpha: 0.4)
              : (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                size: 20,
                color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
              ),
              const SizedBox(width: EdenSpacing.space2),
              if (widget.scannedFormat != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: EdenRadii.borderRadiusSm,
                  ),
                  child: Text(
                    widget.scannedFormat!.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              const Icon(
                Icons.check_circle,
                size: 18,
                color: EdenColors.emerald,
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space2),
          Text(
            widget.scannedValue!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : EdenColors.neutral[900],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: EdenSpacing.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
                    side: BorderSide(
                      color: isDark
                          ? EdenColors.neutral[600]!
                          : EdenColors.neutral[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: EdenSpacing.space3),
                  ),
                  child: const Text('Retry'),
                ),
              ),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(
                child: FilledButton(
                  onPressed: widget.scannedValue != null
                      ? () =>
                          widget.onConfirm?.call(widget.scannedValue!)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: EdenSpacing.space3),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Manual entry
  // ---------------------------------------------------------------------------

  Widget _buildManualEntry(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Entry',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : EdenColors.neutral[900],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type barcode value...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[400],
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space3,
                      vertical: EdenSpacing.space2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusMd,
                      borderSide: BorderSide(
                        color: isDark
                            ? EdenColors.neutral[600]!
                            : EdenColors.neutral[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusMd,
                      borderSide: BorderSide(
                        color: isDark
                            ? EdenColors.neutral[600]!
                            : EdenColors.neutral[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusMd,
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      widget.onManualEntry?.call(value);
                      _manualController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: EdenSpacing.space2),
              FilledButton(
                onPressed: () {
                  final value = _manualController.text.trim();
                  if (value.isNotEmpty) {
                    widget.onManualEntry?.call(value);
                    _manualController.clear();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: EdenRadii.borderRadiusMd,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space3,
                    vertical: EdenSpacing.space2,
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scan history
  // ---------------------------------------------------------------------------

  Widget _buildHistorySection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Scans',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.history.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
            ),
            itemBuilder: (context, index) {
              final record = widget.history[index];
              return _buildHistoryItem(theme, isDark, record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
    ThemeData theme,
    bool isDark,
    EdenScanRecord record,
  ) {
    final time =
        '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => widget.onHistoryItemTap?.call(record.value),
      borderRadius: EdenRadii.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space2,
          horizontal: EdenSpacing.space1,
        ),
        child: Row(
          children: [
            Icon(
              Icons.qr_code,
              size: 16,
              color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : EdenColors.neutral[900],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    record.format.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[500],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

