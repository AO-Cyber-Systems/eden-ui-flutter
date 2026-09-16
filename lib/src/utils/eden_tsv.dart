// lib/src/utils/eden_tsv.dart
//
// TRD 40-05 — the single TSV dialect for every Eden table.
//
// WHY THIS EXISTS
// ---------------
// `SelectionArea` concatenates the selected fragments in TREE ORDER with NO tab
// and NO newline between them (40-RESEARCH.md section 5). Drag-copying a table
// therefore produces run-together text — "AliceAdminBobUser" — which is
// structurally unusable: no consumer can recover the grid from it.
//
// Free-form selection (TRD 40-02) and explicit TSV copy are NOT alternatives.
// Selection serves "grab that one value"; TSV copy serves "put this table in a
// spreadsheet". A tabular surface needs both.
//
// Every Eden table routes its copy action through the functions below, so the
// library emits exactly ONE TSV dialect. A widget that hand-rolls its own
// `join('\t')` is a bug: it will drift from the normalisation rules documented
// here and silently emit a different grid from its neighbours.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Between cells in a row.
///
/// TSV, not CSV. Spreadsheets paste tab-delimited clipboard text natively as
/// separate cells; CSV arrives as one cell per line and needs an import dialog,
/// plus a quote-escaping dialect this library should not own.
const String _kFieldDelimiter = '\t';

/// Between rows.
///
/// LF, never CRLF. The clipboard carries a Dart `String`, and Excel, Google
/// Sheets and Numbers all split LF-delimited clipboard text into rows. Emitting
/// CRLF would add a stray carriage return to the last cell of every row in the
/// consumers that do not strip it.
const String _kLineDelimiter = '\n';

/// Characters that would break the grid if they survived into a cell.
///
/// A run of them collapses to ONE space, so `"a\r\nb"` yields `"a b"` rather
/// than `"a  b"`.
final RegExp _kCellBreakers = RegExp(r'[\t\r\n]+');

/// Maximum wrapper nesting [edenExtractWidgetText] will descend through.
///
/// A cell is a leaf of a layout, not a page: eight levels is generous. The cap
/// exists so a pathological or accidentally self-similar tree cannot make a
/// copy button hang the UI thread.
const int _kMaxExtractDepth = 8;

/// Normalises one cell value for TSV.
///
/// **TSV has no escaping mechanism.** The format is purely positional: the nth
/// tab starts the nth column, full stop. A raw tab inside a value therefore
/// does not "look wrong" on paste — it silently shifts every later column of
/// that row by one, and the corruption is invisible until someone reads the
/// spreadsheet. A raw newline is worse: it splits one record into two.
///
/// The three repair strategies and why this one:
///
/// * **Escape** (`\t` -> the two characters backslash-t) — rejected. It makes
///   the payload lossless but requires every consumer to un-escape. A
///   spreadsheet does not, so the user sees a literal backslash-t in the cell.
/// * **Quote** (CSV's `"..."` with doubled quotes) — rejected. That is the CSV
///   dialect, not TSV; spreadsheets do not apply CSV quoting rules to
///   tab-delimited clipboard text, so the quotes land in the cell verbatim.
/// * **Collapse to a space** — chosen. Lossy in the rare cell that contains a
///   tab or newline, but the GRID stays intact, which is the entire point of
///   copying a table. A user who needs the exact bytes of one multi-line cell
///   selects and copies that cell directly (TRD 40-02 makes every surface
///   free-form selectable).
///
/// Also trims: leading and trailing whitespace in a cell is layout residue, not
/// data, and a leading space is visible in a spreadsheet cell.
///
/// Empty in, empty out. An empty cell stays empty and still occupies its
/// column — the delimiter around it is emitted regardless, so column alignment
/// survives a blank.
String edenTsvCell(String value) {
  return value.replaceAll(_kCellBreakers, ' ').trim();
}

/// Joins one row's [cells] into a single TAB-delimited line.
///
/// Every cell is passed through [edenTsvCell] first — there is no path into a
/// row that skips normalisation. No trailing delimiter is emitted, so an
/// N-cell row contains exactly N-1 tabs.
String edenTsvRow(List<String> cells) {
  return cells.map(edenTsvCell).join(_kFieldDelimiter);
}

/// Joins a grid into one NEWLINE-delimited TSV block.
///
/// Contract, relied on by every caller and by TRD 40-08:
///
/// * **Header is opt-in and explicit.** Pass [header] to emit a header line
///   first; omit it and none is emitted. It is a named argument rather than a
///   flag on the data because the two call sites differ: "copy table" wants
///   column names, "copy row" must never smuggle them in. Making the choice
///   visible at the call site keeps them from being confused.
/// * **No trailing line delimiter.** A trailing newline pastes into a
///   spreadsheet as a phantom empty row, which then shows up in row counts and
///   in any downstream `SUM`/`COUNTA`.
/// * **Ragged rows are preserved as-is, never padded.** If one row has fewer
///   cells than another, the output has a short line. Silently padding to the
///   widest row would invent empty cells the caller never supplied and hide the
///   modelling bug that produced the ragged grid.
/// * **An empty grid with no header produces an empty string** — not a lone
///   newline, not the string "null". An empty grid WITH a header produces just
///   the header line: the caller asked for column names, so copying an empty
///   table puts its columns on the clipboard.
String edenRowsToTsv(List<List<String>> rows, {List<String>? header}) {
  final List<String> lines = <String>[
    if (header != null) edenTsvRow(header),
    for (final List<String> row in rows) edenTsvRow(row),
  ];
  return lines.join(_kLineDelimiter);
}

/// Best-effort static text extraction from a cell [widget].
///
/// For tables whose cells are opaque `Widget`s ([EdenDataTable]), this recovers
/// something copyable without forcing every call site to restate its data.
/// Returns null when nothing textual is found; callers map null to an empty
/// cell so a missing value never becomes the literal string "null".
///
/// **This is a fallback, not the contract.** It reads whatever text happens to
/// be ON SCREEN, which for a formatted amount, a badge or a relative timestamp
/// is a rendering, not the underlying datum. Supply `EdenTableRow.copyValues`
/// whenever the copied value should be the DATA.
///
/// Walks the immutable Widget OBJECT graph directly — no `BuildContext`, no
/// element tree, no build required — so it is a pure function and unit-testable
/// without pumping anything.
///
/// Recognised:
///
/// * `Text` (prefers `data`, falls back to flattening `textSpan`) and
///   `RichText`. These are the only nodes that yield text.
/// * Single-child wrappers: `Padding`, `Align` (which subsumes `Center`),
///   `Flexible` (which subsumes `Expanded`), `SizedBox`, `Container`,
///   `ConstrainedBox`, `DecoratedBox`, `Tooltip`.
/// * Multi-child rows: `Flex` (which subsumes `Row` and `Column`) and `Wrap`.
///   Their textual children are joined with a single space; children that yield
///   nothing are skipped, so a `Row` of icons returns null rather than a run of
///   spaces.
///
/// Deliberately NOT recognised: buttons, `InkWell`, `GestureDetector` and every
/// other affordance. Exclusion is by omission from the whitelist above, and it
/// is intentional rather than an oversight — a button's label ("Copy", "Edit",
/// "Delete") is chrome. Recursing into it would paste the word "Edit" into a
/// spreadsheet cell as though it were the record's data. Anything unrecognised
/// yields null for the same reason: a guess is worse than a blank, and
/// `toString()` on an arbitrary widget produces diagnostic junk.
///
/// Descends at most [_kMaxExtractDepth] wrapper levels; deeper text is not
/// found.
String? edenExtractWidgetText(Widget widget) => _extract(widget, 0);

String? _extract(Widget widget, int depth) {
  if (depth > _kMaxExtractDepth) return null;

  // Leaves. The only nodes that actually carry text.
  if (widget is Text) {
    final String? data = widget.data;
    if (data != null) return data;
    return widget.textSpan?.toPlainText();
  }
  if (widget is RichText) {
    return widget.text.toPlainText();
  }

  // Single-child wrappers. Supertypes are used where the subtype adds no new
  // child field: Align covers Center, Flexible covers Expanded.
  final Widget? child = switch (widget) {
    Padding() => widget.child,
    Align() => widget.child,
    Flexible() => widget.child,
    SizedBox() => widget.child,
    Container() => widget.child,
    ConstrainedBox() => widget.child,
    DecoratedBox() => widget.child,
    Tooltip() => widget.child,
    _ => null,
  };
  if (child != null) return _extract(child, depth + 1);

  // Multi-child layouts. Flex covers Row and Column.
  final List<Widget>? children = switch (widget) {
    Flex() => widget.children,
    Wrap() => widget.children,
    _ => null,
  };
  if (children != null) {
    final List<String> parts = <String>[];
    for (final Widget c in children) {
      final String? text = _extract(c, depth + 1);
      if (text != null && text.isNotEmpty) parts.add(text);
    }
    return parts.isEmpty ? null : parts.join(' ');
  }

  // Unrecognised: an affordance, an icon, an avatar, a custom painter. A blank
  // cell is honest; a guess is not.
  return null;
}

/// Writes a TSV grid to the system clipboard.
///
/// The one place this library touches the clipboard for tabular data. Formats
/// via [edenRowsToTsv], so every documented rule above applies; does nothing
/// else — no toast, no haptic, no focus change. Surfacing feedback is the
/// caller's decision, because it differs between a dense table and a detail
/// panel.
Future<void> edenCopyTsv(List<List<String>> rows, {List<String>? header}) {
  return Clipboard.setData(
    ClipboardData(text: edenRowsToTsv(rows, header: header)),
  );
}
