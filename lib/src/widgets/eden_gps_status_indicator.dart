import 'package:flutter/material.dart';

import 'eden_app_mode.dart';
import 'map_providers/eden_map_types.dart' show EdenLatLng;

/// GPS signal quality + permission state, codified per
/// `.planning/COMPANION_UX_PATTERNS_2026-05-15.md` §P-17.
///
/// Three meaningful signal qualities + an "unavailable" terminal state
/// for when GPS is off or permission is denied.
enum EdenGpsStatus { high, moderate, poor, unavailable }

/// Cross-vertical GPS status pill + accuracy + lat/lng readout.
///
/// Promoted from trades-only to library-level per P-17 evidence:
/// fuel (route adherence), medical (home-visit chain-of-custody), gov
/// (field inspection) all need it. Use-case matrix coverage: UC-02,
/// UC-28, UC-30, UC-39.
///
/// **Transport-agnostic.** Consumer subscribes to `geolocator` /
/// `location` / equivalent platform stream and pushes the resolved
/// [EdenGpsStatus] + [EdenLatLng] + [accuracyMeters] in. Library
/// renders only.
///
/// **Mode-aware compression.** Reads
/// `EdenAppModeScope.maybeOf(context)`:
///   - `fieldCompanion` or absent scope → full UI (pill + accuracy +
///     coords).
///   - `admin` → compact UI (pill + accuracy only, no coords).
///   - `askUser` → full UI (fallback to full).
/// Override via the [compact] constructor arg: `true` = force compact,
/// `false` = force full, `null` (default) = read from the scope.
///
/// When [status] is [EdenGpsStatus.unavailable], accuracy + coords are
/// meaningless — the widget renders the gray pill + 'GPS unavailable'
/// text only, regardless of [compact] or mode.
class EdenGpsStatusIndicator extends StatelessWidget {
  const EdenGpsStatusIndicator({
    super.key,
    required this.status,
    this.accuracyMeters,
    this.position,
    this.compact,
  });

  final EdenGpsStatus status;
  final double? accuracyMeters;
  final EdenLatLng? position;

  /// null = read from `EdenAppModeScope` (admin → compact, else full).
  /// true = force compact. false = force full.
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final useCompact = compact ?? _shouldUseCompact(context);
    final isUnavailable = status == EdenGpsStatus.unavailable;
    return Semantics(
      label: _semanticsLabel(),
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(context),
          if (!isUnavailable && accuracyMeters != null) ...[
            const SizedBox(width: 8),
            Text('${accuracyMeters!.round()} m'),
          ],
          if (!isUnavailable && !useCompact && position != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatCoords(position!),
                style: const TextStyle(fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldUseCompact(BuildContext context) {
    final scope = EdenAppModeScope.maybeOf(context);
    if (scope == null) return false; // graceful default = full
    return scope.currentMode == EdenAppMode.admin;
  }

  Widget _pill(BuildContext context) {
    final (Color bgColor, String label) = switch (status) {
      EdenGpsStatus.high => (Colors.green.shade100, 'High'),
      EdenGpsStatus.moderate => (Colors.amber.shade100, 'Moderate'),
      EdenGpsStatus.poor => (Colors.red.shade100, 'Poor'),
      EdenGpsStatus.unavailable => (Colors.grey.shade200, 'GPS unavailable'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label),
    );
  }

  String _formatCoords(EdenLatLng p) =>
      '${p.lat.toStringAsFixed(6)}, ${p.lng.toStringAsFixed(6)}';

  String _semanticsLabel() {
    if (status == EdenGpsStatus.unavailable) return 'GPS unavailable';
    final qty = status.name; // 'high' / 'moderate' / 'poor'
    final acc = accuracyMeters?.round() ?? 0;
    return 'GPS signal: $qty, accuracy $acc meters';
  }
}
