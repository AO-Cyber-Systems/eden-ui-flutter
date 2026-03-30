import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A marker to display on the map.
class EdenMapMarker {
  /// Creates a map marker.
  const EdenMapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.label,
    this.color,
    this.icon,
    this.isSelected = false,
    this.category,
    this.metadata = const {},
  });

  /// Unique identifier for this marker.
  final String id;

  /// Latitude coordinate.
  final double latitude;

  /// Longitude coordinate.
  final double longitude;

  /// Display label for the marker.
  final String label;

  /// Marker pin color. Falls back to primary if null.
  final Color? color;

  /// Optional icon to show on the pin.
  final IconData? icon;

  /// Whether this marker is currently selected.
  final bool isSelected;

  /// Category used for filtering.
  final String? category;

  /// Arbitrary metadata attached to the marker.
  final Map<String, dynamic> metadata;
}

/// Detail information for a selected marker.
class EdenMarkerDetail {
  /// Creates marker detail data.
  const EdenMarkerDetail({
    required this.title,
    this.subtitle,
    this.address,
    this.phone,
    this.statusLabel,
    this.statusColor,
    this.actions = const [],
  });

  /// Primary title.
  final String title;

  /// Secondary description.
  final String? subtitle;

  /// Street address.
  final String? address;

  /// Phone number.
  final String? phone;

  /// Text shown in the status badge.
  final String? statusLabel;

  /// Color of the status badge.
  final Color? statusColor;

  /// Action buttons displayed in the detail panel.
  final List<EdenMarkerAction> actions;
}

/// An action button in the marker detail panel.
class EdenMarkerAction {
  /// Creates a marker action.
  const EdenMarkerAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// Display label.
  final String label;

  /// Button icon.
  final IconData icon;

  /// Tap handler.
  final VoidCallback onTap;
}

/// A filter category chip.
class EdenMapFilter {
  /// Creates a filter chip model.
  const EdenMapFilter({
    required this.id,
    required this.label,
    this.color,
    this.isSelected = false,
  });

  /// Unique key.
  final String id;

  /// Display label.
  final String label;

  /// Chip color.
  final Color? color;

  /// Whether this filter is active.
  final bool isSelected;
}

/// A legend entry describing a marker colour.
class EdenMapLegendItem {
  /// Creates a legend item.
  const EdenMapLegendItem({
    required this.color,
    required this.label,
  });

  /// The colour swatch.
  final Color color;

  /// Human-readable meaning.
  final String label;
}

// ---------------------------------------------------------------------------
// EdenMapView
// ---------------------------------------------------------------------------

/// A map integration wrapper that overlays search, filters, zoom controls,
/// marker details, and a legend on top of a consumer-provided map widget.
///
/// Because eden-ui-flutter carries no platform dependencies the actual map
/// rendering is delegated to [mapBuilder]. All interactivity is signalled
/// through callbacks so the consumer can wire up whichever map SDK they use.
class EdenMapView extends StatefulWidget {
  /// Creates an Eden map view.
  const EdenMapView({
    super.key,
    required this.mapBuilder,
    this.markers = const [],
    this.filters = const [],
    this.legend = const [],
    this.selectedMarkerDetail,
    this.isLoading = false,
    this.showMarkerDrawer = false,
    this.searchHint = 'Search locations...',
    this.initialSearchText,
    this.currentDate,
    this.onMarkerTap,
    this.onSearchChanged,
    this.onFilterChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onMyLocation,
    this.onDateChanged,
    this.onDetailDismissed,
  });

  /// The consumer-provided map widget.
  final Widget mapBuilder;

  /// Markers to show on the map.
  final List<EdenMapMarker> markers;

  /// Filter chips displayed above the map.
  final List<EdenMapFilter> filters;

  /// Legend entries.
  final List<EdenMapLegendItem> legend;

  /// When non-null the detail bottom sheet is shown.
  final EdenMarkerDetail? selectedMarkerDetail;

  /// Whether to show a loading overlay on the map.
  final bool isLoading;

  /// Whether the marker list side drawer is visible.
  final bool showMarkerDrawer;

  /// Placeholder text for the search bar.
  final String searchHint;

  /// Initial value for the search field.
  final String? initialSearchText;

  /// Currently selected date for the date navigation bar.
  final DateTime? currentDate;

  // Callbacks -----------------------------------------------------------------

  /// Called when a marker is tapped, with its id.
  final ValueChanged<String>? onMarkerTap;

  /// Called as the user types in the search bar.
  final ValueChanged<String>? onSearchChanged;

  /// Called when a filter chip is toggled, with its id.
  final ValueChanged<String>? onFilterChanged;

  /// Called when the zoom-in button is pressed.
  final VoidCallback? onZoomIn;

  /// Called when the zoom-out button is pressed.
  final VoidCallback? onZoomOut;

  /// Called when the current-location button is pressed.
  final VoidCallback? onMyLocation;

  /// Called when the date is changed via the date navigation bar.
  final ValueChanged<DateTime>? onDateChanged;

  /// Called when the detail bottom sheet is dismissed.
  final VoidCallback? onDetailDismissed;

  @override
  State<EdenMapView> createState() => _EdenMapViewState();
}

class _EdenMapViewState extends State<EdenMapView>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _detailSheetController;
  late final Animation<Offset> _detailSlide;

  bool _legendExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialSearchText ?? '');

    _detailSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _detailSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _detailSheetController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.selectedMarkerDetail != null) {
      _detailSheetController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant EdenMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarkerDetail != null &&
        oldWidget.selectedMarkerDetail == null) {
      _detailSheetController.forward();
    } else if (widget.selectedMarkerDetail == null &&
        oldWidget.selectedMarkerDetail != null) {
      _detailSheetController.reverse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _detailSheetController.dispose();
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
      children: [
        // Map content
        Positioned.fill(child: widget.mapBuilder),

        // Loading overlay
        if (widget.isLoading) _buildLoadingOverlay(theme, isDark),

        // Search bar + filter chips at top
        Positioned(
          top: EdenSpacing.space4,
          left: EdenSpacing.space4,
          right: EdenSpacing.space4,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildSearchBar(theme, isDark),
                if (widget.filters.isNotEmpty) ...[
                  const SizedBox(height: EdenSpacing.space2),
                  _buildFilterChips(theme, isDark),
                ],
              ],
            ),
          ),
        ),

        // Date navigation bar
        if (widget.currentDate != null)
          Positioned(
            top: EdenSpacing.space4 +
                56 +
                (widget.filters.isNotEmpty ? 48 : 0) +
                MediaQuery.of(context).padding.top,
            left: EdenSpacing.space4,
            right: EdenSpacing.space4,
            child: _buildDateNavBar(theme, isDark),
          ),

        // Zoom controls + my location on right side
        Positioned(
          right: EdenSpacing.space4,
          bottom: widget.selectedMarkerDetail != null ? 260 : 120,
          child: _buildMapControls(theme, isDark),
        ),

        // Legend
        if (widget.legend.isNotEmpty)
          Positioned(
            left: EdenSpacing.space4,
            bottom: widget.selectedMarkerDetail != null ? 260 : 120,
            child: _buildLegend(theme, isDark),
          ),

        // Marker list drawer
        if (widget.showMarkerDrawer)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 280,
            child: _buildMarkerDrawer(theme, isDark),
          ),

        // Marker detail bottom sheet
        if (widget.selectedMarkerDetail != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _detailSlide,
              child: _buildDetailSheet(
                theme,
                isDark,
                widget.selectedMarkerDetail!,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Loading overlay
  // ---------------------------------------------------------------------------

  Widget _buildLoadingOverlay(ThemeData theme, bool isDark) {
    return Positioned.fill(
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            decoration: BoxDecoration(
              color: isDark ? EdenColors.neutral[800] : Colors.white,
              borderRadius: EdenRadii.borderRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: EdenSpacing.space3),
                Text(
                  'Loading map...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : Colors.white,
        borderRadius: EdenRadii.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.onSearchChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white : EdenColors.neutral[900],
        ),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color:
                        isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: EdenSpacing.space2),
        itemBuilder: (context, index) {
          final filter = widget.filters[index];
          final chipColor =
              filter.color ?? theme.colorScheme.primary;
          return GestureDetector(
            onTap: () => widget.onFilterChanged?.call(filter.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
                vertical: EdenSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: filter.isSelected
                    ? chipColor.withValues(alpha: 0.2)
                    : (isDark ? EdenColors.neutral[800] : Colors.white),
                borderRadius: EdenRadii.borderRadiusFull,
                border: Border.all(
                  color: filter.isSelected
                      ? chipColor
                      : (isDark
                          ? EdenColors.neutral[600]!
                          : EdenColors.neutral[300]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: filter.isSelected
                        ? chipColor
                        : (isDark
                            ? EdenColors.neutral[300]
                            : EdenColors.neutral[700]),
                    fontWeight: filter.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date navigation bar
  // ---------------------------------------------------------------------------

  Widget _buildDateNavBar(ThemeData theme, bool isDark) {
    final date = widget.currentDate!;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label = '${months[date.month - 1]} ${date.day}, ${date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : Colors.white,
        borderRadius: EdenRadii.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconButton(
            icon: Icons.chevron_left,
            onTap: () => widget.onDateChanged
                ?.call(date.subtract(const Duration(days: 1))),
            theme: theme,
            isDark: isDark,
            size: 28,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : EdenColors.neutral[900],
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          _iconButton(
            icon: Icons.chevron_right,
            onTap: () =>
                widget.onDateChanged?.call(date.add(const Duration(days: 1))),
            theme: theme,
            isDark: isDark,
            size: 28,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map controls (zoom + my location)
  // ---------------------------------------------------------------------------

  Widget _buildMapControls(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(
          icon: Icons.add,
          onTap: widget.onZoomIn,
          theme: theme,
          isDark: isDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(EdenRadii.lg),
            topRight: Radius.circular(EdenRadii.lg),
          ),
        ),
        Container(
          height: 1,
          width: 44,
          color: isDark ? EdenColors.neutral[700] : EdenColors.neutral[200],
        ),
        _buildControlButton(
          icon: Icons.remove,
          onTap: widget.onZoomOut,
          theme: theme,
          isDark: isDark,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(EdenRadii.lg),
            bottomRight: Radius.circular(EdenRadii.lg),
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        _buildControlButton(
          icon: Icons.my_location,
          onTap: widget.onMyLocation,
          theme: theme,
          isDark: isDark,
          borderRadius: EdenRadii.borderRadiusLg,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ThemeData theme,
    required bool isDark,
    required BorderRadius borderRadius,
  }) {
    return Material(
      color: isDark ? EdenColors.neutral[800] : Colors.white,
      borderRadius: borderRadius,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : EdenColors.neutral[700],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Legend
  // ---------------------------------------------------------------------------

  Widget _buildLegend(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _legendExpanded = !_legendExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(EdenSpacing.space3),
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[800] : Colors.white,
          borderRadius: EdenRadii.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.legend_toggle,
                  size: 16,
                  color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                ),
                const SizedBox(width: EdenSpacing.space1),
                Text(
                  'Legend',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
                  ),
                ),
                const SizedBox(width: EdenSpacing.space1),
                Icon(
                  _legendExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 16,
                  color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                ),
              ],
            ),
            if (_legendExpanded) ...[
              const SizedBox(height: EdenSpacing.space2),
              ...widget.legend.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                      Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? EdenColors.neutral[300]
                              : EdenColors.neutral[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Marker list drawer
  // ---------------------------------------------------------------------------

  Widget _buildMarkerDrawer(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Text(
                'Markers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : EdenColors.neutral[900],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? EdenColors.neutral[700] : EdenColors.neutral[200],
            ),
            Expanded(
              child: widget.markers.isEmpty
                  ? Center(
                      child: Text(
                        'No markers',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? EdenColors.neutral[500]
                              : EdenColors.neutral[400],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                      itemCount: widget.markers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: EdenSpacing.space4,
                        color: isDark
                            ? EdenColors.neutral[800]
                            : EdenColors.neutral[100],
                      ),
                      itemBuilder: (context, index) {
                        final marker = widget.markers[index];
                        return _buildMarkerListItem(theme, isDark, marker);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerListItem(
    ThemeData theme,
    bool isDark,
    EdenMapMarker marker,
  ) {
    final pinColor = marker.color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: () => widget.onMarkerTap?.call(marker.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space3,
        ),
        color: marker.isSelected
            ? pinColor.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: pinColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marker.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          marker.isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? Colors.white : EdenColors.neutral[900],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (marker.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      marker.category!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? EdenColors.neutral[500]
                            : EdenColors.neutral[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (marker.isSelected)
              Icon(
                Icons.check_circle,
                size: 16,
                color: pinColor,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Marker detail bottom sheet
  // ---------------------------------------------------------------------------

  Widget _buildDetailSheet(
    ThemeData theme,
    bool isDark,
    EdenMarkerDetail detail,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.xl),
          topRight: Radius.circular(EdenRadii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: EdenSpacing.space4),

              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : EdenColors.neutral[900],
                      ),
                    ),
                  ),
                  if (detail.statusLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space2,
                        vertical: EdenSpacing.space1,
                      ),
                      decoration: BoxDecoration(
                        color: (detail.statusColor ?? EdenColors.emerald)
                            .withValues(alpha: 0.15),
                        borderRadius: EdenRadii.borderRadiusFull,
                      ),
                      child: Text(
                        detail.statusLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              detail.statusColor ?? EdenColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: EdenSpacing.space2),
                  GestureDetector(
                    onTap: widget.onDetailDismissed,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color:
                          isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                    ),
                  ),
                ],
              ),

              // Subtitle
              if (detail.subtitle != null) ...[
                const SizedBox(height: EdenSpacing.space1),
                Text(
                  detail.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark ? EdenColors.neutral[400] : EdenColors.neutral[600],
                  ),
                ),
              ],

              const SizedBox(height: EdenSpacing.space3),

              // Address
              if (detail.address != null)
                _detailRow(
                  Icons.location_on_outlined,
                  detail.address!,
                  theme,
                  isDark,
                ),

              // Phone
              if (detail.phone != null)
                _detailRow(
                  Icons.phone_outlined,
                  detail.phone!,
                  theme,
                  isDark,
                ),

              // Action buttons
              if (detail.actions.isNotEmpty) ...[
                const SizedBox(height: EdenSpacing.space4),
                Row(
                  children: detail.actions.map((action) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action == detail.actions.last
                              ? 0
                              : EdenSpacing.space2,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: action.onTap,
                          icon: Icon(action.icon, size: 18),
                          label: Text(action.label),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: EdenRadii.borderRadiusMd,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: EdenSpacing.space3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _iconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ThemeData theme,
    required bool isDark,
    double size = 36,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: 20,
          color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EdenMapClusterIndicator
// ---------------------------------------------------------------------------

/// A circular badge showing a count of clustered markers.
///
/// Place this on the map to represent multiple markers that overlap at the
/// current zoom level.
class EdenMapClusterIndicator extends StatelessWidget {
  /// Creates a cluster indicator.
  const EdenMapClusterIndicator({
    super.key,
    required this.count,
    this.color,
    this.size = 40,
    this.onTap,
  });

  /// Number of markers in this cluster.
  final int count;

  /// Background colour. Falls back to the theme primary.
  final Color? color;

  /// Diameter of the circle.
  final double size;

  /// Called when the cluster is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg.withValues(alpha: 0.85),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          count > 999 ? '999+' : count.toString(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: count > 99 ? 10 : 12,
          ),
        ),
      ),
    );
  }
}
