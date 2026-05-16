import 'package:flutter/foundation.dart';

import 'scheduler_models.dart';

typedef _Clock = DateTime Function();

/// State controller for [EdenScheduler]. Extracted from the previous inline
/// `_EdenSchedulerState`. Holds `view`, `focusedDate`, `selectedResources`,
/// `selectedEventIds`, `search`. Notifies listeners on every state change.
///
/// Lifecycle: when the consumer constructs and passes an external controller
/// to [EdenScheduler], the consumer owns disposal. When [EdenScheduler] is
/// constructed without a controller, it creates one internally and disposes
/// it itself.
///
/// Clock injection allows deterministic tests of `goToday()`.
class EdenSchedulerController extends ChangeNotifier {
  EdenSchedulerController({
    EdenSchedulerView initialView = EdenSchedulerView.week,
    DateTime? initialDate,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _view = initialView,
        _focusedDate =
            _stripTime(initialDate ?? (clock ?? DateTime.now).call());

  final _Clock _clock;
  EdenSchedulerView _view;
  DateTime _focusedDate;
  final Set<String> _selectedResources = <String>{};
  final Set<String> _selectedEventIds = <String>{};
  String _search = '';

  EdenSchedulerView get view => _view;
  DateTime get focusedDate => _focusedDate;
  DateTime get today => _stripTime(_clock());
  Set<String> get selectedResources => Set.unmodifiable(_selectedResources);
  Set<String> get selectedEventIds => Set.unmodifiable(_selectedEventIds);
  String get search => _search;

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  void setView(EdenSchedulerView v) {
    if (v == _view) return;
    _view = v;
    notifyListeners();
  }

  void setFocusedDate(DateTime d) {
    final stripped = _stripTime(d);
    if (stripped == _focusedDate) return;
    _focusedDate = stripped;
    notifyListeners();
  }

  /// Navigate the focused date by [delta] units appropriate to the current
  /// view (1 day, 1 week, 1 month).
  void navigate(int delta) {
    switch (_view) {
      case EdenSchedulerView.month:
        _focusedDate =
            DateTime(_focusedDate.year, _focusedDate.month + delta, 1);
        break;
      case EdenSchedulerView.week:
      case EdenSchedulerView.workWeek:
      case EdenSchedulerView.list:
      case EdenSchedulerView.swimlane:
        _focusedDate = _focusedDate.add(Duration(days: 7 * delta));
        break;
      case EdenSchedulerView.day:
      case EdenSchedulerView.mobile:
        _focusedDate = _focusedDate.add(Duration(days: delta));
        break;
    }
    notifyListeners();
  }

  /// Reset focused date to clock-provided today.
  void goToday() {
    final t = today;
    if (t == _focusedDate) return;
    _focusedDate = t;
    notifyListeners();
  }

  /// Toggle membership of [resourceId] in the resource filter.
  void toggleResourceFilter(String resourceId) {
    if (_selectedResources.contains(resourceId)) {
      _selectedResources.remove(resourceId);
    } else {
      _selectedResources.add(resourceId);
    }
    notifyListeners();
  }

  /// Set the search query (trimmed). No-op when unchanged.
  void setSearch(String value) {
    final trimmed = value.trim();
    if (trimmed == _search) return;
    _search = trimmed;
    notifyListeners();
  }

  /// Toggle membership of [eventId] in the active selection.
  void toggleSelection(String eventId) {
    if (_selectedEventIds.contains(eventId)) {
      _selectedEventIds.remove(eventId);
    } else {
      _selectedEventIds.add(eventId);
    }
    notifyListeners();
  }

  /// Clear all selected events. No-op when already empty.
  void clearSelection() {
    if (_selectedEventIds.isEmpty) return;
    _selectedEventIds.clear();
    notifyListeners();
  }
}
