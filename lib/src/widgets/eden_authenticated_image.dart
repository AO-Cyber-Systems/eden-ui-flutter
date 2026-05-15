import 'package:flutter/material.dart';

import 'eden_spinner.dart';

/// An image fetched via `Image.network` with an arbitrary headers map
/// (commonly `Authorization: Bearer …` or `X-Tenant: …` for signed-URL
/// per-tenant fetches).
///
/// **Library is transport-agnostic.** The widget does NOT mint tokens,
/// refresh sessions, or know about JWT/OAuth/cookies. Callers supply
/// headers either:
///   * Statically via [headers], OR
///   * Asynchronously via [headersBuilder] — useful when the token must be
///     resolved from a `flutter_secure_storage` lookup or refreshed first.
///
/// Matches the per-tenant signed-URL flow specified by obj 018-02 backend.
class EdenAuthenticatedImage extends StatefulWidget {
  const EdenAuthenticatedImage({
    super.key,
    required this.url,
    this.headers,
    this.headersBuilder,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Absolute image URL.
  final String url;

  /// Static headers map. Mutually compatible with [headersBuilder] —
  /// if both are provided, [headersBuilder] wins.
  final Map<String, String>? headers;

  /// Async headers resolver. Awaited in initState; image only resolves
  /// once this future completes.
  ///
  /// May return null to indicate "no headers — fetch anonymously".
  /// If the future throws, [errorWidget] is rendered.
  final Future<Map<String, String>?> Function()? headersBuilder;

  /// Widget shown while loading. Defaults to [EdenSpinner].
  final Widget? placeholder;

  /// Widget shown on load failure (404, network error, headersBuilder throws).
  /// Defaults to a broken-image icon.
  final Widget? errorWidget;

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<EdenAuthenticatedImage> createState() => _EdenAuthenticatedImageState();
}

class _EdenAuthenticatedImageState extends State<EdenAuthenticatedImage> {
  Map<String, String>? _resolvedHeaders;
  bool _headerError = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.headersBuilder != null) {
      widget.headersBuilder!().then((h) {
        if (!mounted) return;
        setState(() {
          _resolvedHeaders = h;
          _initialized = true;
        });
      }).catchError((Object _) {
        if (!mounted) return;
        setState(() {
          _headerError = true;
          _initialized = true;
        });
      });
    } else {
      _resolvedHeaders = widget.headers ?? const <String, String>{};
      _initialized = true;
    }
  }

  Widget _defaultPlaceholder() =>
      widget.placeholder ?? const Center(child: EdenSpinner());

  Widget _defaultError() =>
      widget.errorWidget ?? const Icon(Icons.broken_image, size: 32);

  @override
  Widget build(BuildContext context) {
    if (_headerError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _defaultError(),
      );
    }
    if (!_initialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _defaultPlaceholder(),
      );
    }
    // _initialized == true. _resolvedHeaders may be null (anonymous fetch).
    final headers = (_resolvedHeaders == null || _resolvedHeaders!.isEmpty)
        ? null
        : _resolvedHeaders;
    return Image.network(
      widget.url,
      headers: headers,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: _defaultPlaceholder(),
        );
      },
      errorBuilder: (context, error, stack) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: _defaultError(),
        );
      },
    );
  }
}
