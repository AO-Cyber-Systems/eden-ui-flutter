/// EdenQrCode — wraps qr_flutter's QrImageView with Eden styling defaults.
///
/// TSB-FE-01 (Objective 023): upstream widget for CollectPaymentModal's
/// Stripe Checkout QR path. Minimal v1 API — extend EdenQrCodeStyle as needed.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Optional style overrides for [EdenQrCode].
///
/// Explicit [Color] values are required by qr_flutter's painter; omitting
/// them causes a null-dereference in [QrPainter._drawFinderPatternItem].
class EdenQrCodeStyle {
  const EdenQrCodeStyle({
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.eyeStyle = const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    this.dataModuleStyle = const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  });

  final Color backgroundColor;

  /// Foreground (module) colour — used if no explicit [dataModuleStyle] is set.
  final Color foregroundColor;
  final QrEyeStyle eyeStyle;
  final QrDataModuleStyle dataModuleStyle;
}

/// A QR code widget wrapping [QrImageView] from qr_flutter.
///
/// [data] is the string encoded in the QR (e.g., a Stripe Checkout URL).
/// [size] defaults to 200. Supply [style] to customise eye/module shapes.
class EdenQrCode extends StatelessWidget {
  const EdenQrCode({
    super.key,
    required this.data,
    this.size = 200.0,
    this.style,
  });

  final String data;
  final double size;
  final EdenQrCodeStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? const EdenQrCodeStyle();
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: s.backgroundColor,
      eyeStyle: s.eyeStyle,
      dataModuleStyle: s.dataModuleStyle,
      errorStateBuilder: (ctx, err) => SizedBox.square(
        dimension: size,
        child: const Center(child: Icon(Icons.qr_code_2, size: 48)),
      ),
    );
  }
}
