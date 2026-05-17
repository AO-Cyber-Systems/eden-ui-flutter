import 'package:flutter/material.dart';

/// Layout for [EdenAgencyIdentifier] — `header` for a compact top-of-page
/// strip, `footer` for the full block layout with parent department +
/// contact links at the bottom of a page.
enum EdenAgencyIdentifierLayout { header, footer }

/// A contact link rendered in the footer layout of [EdenAgencyIdentifier].
///
/// Tap fires the [EdenAgencyIdentifier.onContactLinkTap] callback with
/// this instance — consumer wires URL launching (e.g., `url_launcher`)
/// in app code so the library remains transport-agnostic.
@immutable
class EdenAgencyContactLink {
  const EdenAgencyContactLink({required this.label, required this.url});

  final String label;
  final String url;
}

/// Identity payload for [EdenAgencyIdentifier].
///
/// Encodes the federal agency seal + agency name + parent department +
/// optional contact links list. Library is content-agnostic; consumer
/// builds the [EdenAgencyIdentity] from their own catalog.
@immutable
class EdenAgencyIdentity {
  const EdenAgencyIdentity({
    required this.agencyName,
    required this.parentDepartment,
    this.seal,
    this.contactLinks = const [],
  });

  /// Agency display name (e.g., 'Department of Defense').
  final String agencyName;

  /// Parent department or umbrella org (e.g., 'Federal Government').
  final String parentDepartment;

  /// Optional agency seal/logo. Use an `Icon`, custom-painted seal, or
  /// `null` — the library cannot ship image assets, so consumers pass a
  /// `Widget?` (e.g., `const Icon(Icons.shield_outlined, size: 32)`).
  final Widget? seal;

  /// Optional contact-link list. Empty by default. Rendered only in
  /// [EdenAgencyIdentifierLayout.footer].
  final List<EdenAgencyContactLink> contactLinks;
}

/// USWDS v3.13 agency identifier — agency seal + name (header layout) or
/// full block with parent department + contact links (footer layout).
///
/// Pair with [EdenUSWDSBanner] to form the standard USWDS page chrome.
///
/// Civilian re-use: although named for federal agency contexts, the
/// widget works equally well as a generic "org footer" pattern for
/// commercial verticals — pass a custom [EdenAgencyIdentity] with the
/// org name, parent group, and contact-style links.
class EdenAgencyIdentifier extends StatelessWidget {
  const EdenAgencyIdentifier({
    super.key,
    required this.identity,
    this.layout = EdenAgencyIdentifierLayout.header,
    this.onContactLinkTap,
  });

  final EdenAgencyIdentity identity;
  final EdenAgencyIdentifierLayout layout;

  /// Fires when a contact link is tapped (footer layout only). Consumer
  /// wires URL launching against the [EdenAgencyContactLink.url].
  final ValueChanged<EdenAgencyContactLink>? onContactLinkTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        '${identity.agencyName}, part of ${identity.parentDepartment} — agency identifier';
    return Semantics(
      label: semanticLabel,
      container: true,
      child: layout == EdenAgencyIdentifierLayout.header
          ? _Header(identity: identity)
          : _Footer(identity: identity, onContactLinkTap: onContactLinkTap),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.identity});

  final EdenAgencyIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (identity.seal != null) ...[
            identity.seal!,
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              identity.agencyName,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.identity, this.onContactLinkTap});

  final EdenAgencyIdentity identity;
  final ValueChanged<EdenAgencyContactLink>? onContactLinkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF162E51),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (identity.seal != null) ...[
            identity.seal!,
            const SizedBox(height: 12),
          ],
          Text(
            identity.agencyName,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            identity.parentDepartment,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 13,
            ),
          ),
          if (identity.contactLinks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final link in identity.contactLinks)
                  Semantics(
                    button: true,
                    label: link.label,
                    child: InkWell(
                      onTap: () => onContactLinkTap?.call(link),
                      child: Text(
                        link.label,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
