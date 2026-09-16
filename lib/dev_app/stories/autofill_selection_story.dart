// lib/dev_app/stories/autofill_selection_story.dart
//
// Interactive stories for the four capabilities Objective 040 added:
// EdenFieldPurpose, EdenAutofillScope, EdenSelectableRegion and table TSV copy.
//
// WHY THESE EXIST
//   An API that lives only in dartdoc gets rediscovered wrongly. An API you can
//   click on in the explorer gets copied correctly. `autofill/purposes` in
//   particular turns the whole purpose-resolution table into something you can
//   scrub through, which is the single most useful artifact in the catalog for
//   this objective: it shows that ONE value resolves hints, keyboard, obscuring,
//   action and capitalization together, and that they cannot drift apart.
//
// Registered by `register_all.dart`. Every `build` is pure — no `setState`, no
// controllers created inside `build`; the two stories that need mutable state
// hold it in a private StatefulWidget declared below.

import 'package:flutter/material.dart';
// SelectedContent is declared in rendering/selection.dart and is not
// re-exported by material.dart.
import 'package:flutter/rendering.dart' show SelectedContent;

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

// ---------------------------------------------------------------------------
// Shared presentation helpers
// ---------------------------------------------------------------------------

/// A short explanatory paragraph shown above each demo.
class _Prose extends StatelessWidget {
  const _Prose(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Theme.of(context).brightness == Brightness.dark
              ? EdenColors.neutral[300]
              : EdenColors.neutral[700],
        ),
      ),
    );
  }
}

/// Renders a [TextInputType] the way a reader thinks of it, rather than the
/// long `TextInputType(name: ..., signed: null, decimal: null)` default.
String describeKeyboardType(TextInputType type) {
  final Map<String, dynamic> json = type.toJson();
  final String name = (json['name'] as String?) ?? type.toString();
  final List<String> extras = <String>[
    if (json['signed'] == true) 'signed',
    if (json['decimal'] == true) 'decimal',
  ];
  return extras.isEmpty ? name : '$name (${extras.join(', ')})';
}

/// Renders resolved autofill hints, keeping the null / empty distinction
/// visible.
///
/// `EdenFieldSemantics.autofillHints` uses `null` for "deliberately no autofill
/// purpose", while `TextField.autofillHints` defaults to `const <String>[]`.
/// Both read as "no identity" and the two types are deliberately different, so
/// the read-out names which one it is seeing rather than flattening them.
String describeAutofillHints(List<String>? hints) {
  if (hints == null) {
    return 'null - deliberately no autofill identity';
  }
  if (hints.isEmpty) {
    return 'empty list - no autofill identity';
  }
  if (hints.length == 1) {
    return hints.single;
  }
  return '${hints.first}  (then Android-only: ${hints.skip(1).join(', ')})';
}

// ---------------------------------------------------------------------------
// Story 1 - autofill/purposes
// ---------------------------------------------------------------------------

/// One field plus a read-out of everything the chosen purpose resolved.
class _PurposeExplorer extends StatelessWidget {
  const _PurposeExplorer({required this.purpose});

  final EdenFieldPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final EdenFieldSemantics s = purpose.semantics;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Prose(
            'One EdenFieldPurpose resolves the autofill hints, the keyboard, '
            'obscuring, the input action and capitalization as a single '
            'consistent set. There is no public path that lets a caller supply '
            'a hint and a mismatched keyboard, because that mismatch is exactly '
            'what this type exists to delete: TextField resolves a null '
            'keyboardType in its own initializer list, so Flutter never infers '
            'one from the hints, and AutofillHints.email only works with '
            'TextInputType.emailAddress.',
          ),
          EdenInput(
            label: 'Field',
            hint: 'type here to see the resolved behaviour',
            helperText: 'purpose: EdenFieldPurpose.${purpose.name}',
            purpose: purpose,
          ),
          const SizedBox(height: EdenSpacing.space5),
          Text(
            'RESOLVED SEMANTICS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: EdenColors.neutral[500],
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenKeyValueTable(
            copyable: true,
            items: <EdenKeyValue>[
              EdenKeyValue(
                key: 'autofillHints',
                value: describeAutofillHints(s.autofillHints),
                monospace: true,
              ),
              EdenKeyValue(
                key: 'keyboardType',
                value: describeKeyboardType(s.keyboardType),
                monospace: true,
              ),
              EdenKeyValue(
                key: 'obscureText',
                value: '${s.obscureText}',
                monospace: true,
              ),
              EdenKeyValue(
                key: 'textInputAction',
                value: s.textInputAction.name,
                monospace: true,
              ),
              EdenKeyValue(
                key: 'textCapitalization',
                value: s.textCapitalization.name,
                monospace: true,
              ),
              EdenKeyValue(
                key: 'autocorrect',
                value: '${s.autocorrect}',
                monospace: true,
              ),
              EdenKeyValue(
                key: 'enableSuggestions',
                value: '${s.enableSuggestions}',
                monospace: true,
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          const _Prose(
            'Hint order is load-bearing. iOS and web translate only the FIRST '
            'hint; Android reads all of them. Every list is ordered iOS and '
            'web first, with Android-only extras after index 0. And on web the '
            'DOM input type comes from the hint string, never from '
            'obscureText - an obscured field with no password-family hint '
            'renders as type="text", which puts the secret in plaintext in the '
            'DOM where no password manager can fill or save it.',
          ),
        ],
      ),
    );
  }
}

/// Interactive story for [EdenFieldPurpose] - the whole resolution table as a
/// knob.
final EdenStory autofillPurposesStory = EdenStory(
  id: 'autofill/purposes',
  component: 'autofill',
  name: 'Purposes',
  icon: Icons.password,
  knobs: const <KnobSpec>[
    EnumKnob<EdenFieldPurpose>(
      key: 'purpose',
      label: 'Purpose',
      values: EdenFieldPurpose.values,
      defaultValue: EdenFieldPurpose.email,
    ),
  ],
  build: (BuildContext context, KnobValues k) =>
      _PurposeExplorer(purpose: k.get<EdenFieldPurpose>('purpose')),
);

// ---------------------------------------------------------------------------
// Story 2 - autofill/login-form
// ---------------------------------------------------------------------------

/// A realistic credential form, so the SAVE half of autofill is explorable.
///
/// Stateful because it owns two [TextEditingController]s and a flag recording
/// that [EdenAutofillScopeState.commit] fired; a story `build` must stay pure.
class _LoginFormDemo extends StatefulWidget {
  const _LoginFormDemo();

  @override
  State<_LoginFormDemo> createState() => _LoginFormDemoState();
}

class _LoginFormDemoState extends State<_LoginFormDemo> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _committed = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Prose(
            'Correct hints make a field FILLABLE. Nothing makes it SAVABLE '
            'except one call - TextInput.finishAutofillContext(shouldSave: '
            'true) - which EdenAutofillScope exposes as commit(). Without it, '
            'no credential is ever offered for saving on web, iOS or Android.',
          ),
          const _Prose(
            'Fire commit() only once the credential has actually been '
            'ACCEPTED, after the sign-in request succeeds - never when the '
            'button is pressed. Committing a REJECTED attempt makes the OS and '
            'the password manager offer to save the wrong credentials, which '
            'the user then has to unpick by hand. That is also why this scope '
            'cancels rather than commits when it is disposed, inverting '
            'AutofillGroup default: navigating away from a form must not be a '
            'save.',
          ),
          EdenAutofillScope(
            child: Builder(
              builder: (BuildContext scopeContext) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EdenInput(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      purpose: EdenFieldPurpose.email,
                    ),
                    const SizedBox(height: EdenSpacing.space3),
                    EdenInput(
                      controller: _password,
                      label: 'Password',
                      hint: 'your password',
                      purpose: EdenFieldPurpose.currentPassword,
                    ),
                    const SizedBox(height: EdenSpacing.space4),
                    EdenButton(
                      label: 'Sign in, then commit',
                      icon: Icons.login,
                      onPressed: () {
                        // Stands in for "the sign-in request succeeded".
                        EdenAutofillScope.of(scopeContext).commit();
                        setState(() => _committed = true);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),
          if (_committed)
            const EdenBanner(
              message: 'commit() called - '
                  'TextInput.finishAutofillContext(shouldSave: true) has been '
                  'sent. On a real device this is the moment the platform '
                  'offers to save the credential.',
              variant: EdenBannerVariant.success,
            ),
          const SizedBox(height: EdenSpacing.space4),
          const _Prose(
            'One group, one hint each. The web engine derives both element.name '
            'and element.id from the hint string, so two fields sharing a hint '
            'inside one scope emit duplicate DOM ids. That is why this form '
            'pairs email with currentPassword rather than repeating a hint, and '
            'why the new-password / confirm pair is documented as a deliberate, '
            'separate decision.',
          ),
        ],
      ),
    );
  }
}

/// Interactive story for [EdenAutofillScope] - the SAVE half of autofill.
final EdenStory autofillLoginFormStory = EdenStory(
  id: 'autofill/login-form',
  component: 'autofill',
  name: 'Login Form',
  icon: Icons.login,
  knobs: const <KnobSpec>[],
  build: (BuildContext context, KnobValues k) => const _LoginFormDemo(),
);

// ---------------------------------------------------------------------------
// Story 3 - selection/region
// ---------------------------------------------------------------------------

/// A selectable surface with a live read-out of what is selected.
///
/// Stateful because it records the latest selection. It also passes
/// `onSelectionChanged`, which makes this a CONFIGURED region: a plain nested
/// region defers to an ancestor and becomes a no-op, so a configured one is
/// what keeps the `enabled` knob observable wherever the story is mounted.
class _SelectionRegionDemo extends StatefulWidget {
  const _SelectionRegionDemo({required this.enabled});

  final bool enabled;

  @override
  State<_SelectionRegionDemo> createState() => _SelectionRegionDemoState();
}

class _SelectionRegionDemoState extends State<_SelectionRegionDemo> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Prose(
            'Flutter widgets are not selectable by default. EdenSelectableRegion '
            'makes an entire subtree drag-selectable with no per-widget change, '
            'and on web it also calls BrowserContextMenu.disableContextMenu() '
            'once so that Flutter own Copy menu appears on right-click instead '
            'of the browser native menu. Both halves have to ship together, '
            'which is why they are one widget rather than a bare SelectionArea '
            'at each call site.',
          ),
          EdenSelectableRegion(
            enabled: widget.enabled,
            onSelectionChanged: (SelectedContent? content) {
              setState(() => _selected = content?.plainText ?? '');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Drag across this paragraph, the card below it and the table '
                  'under that. A single region spans all three, so one drag '
                  'can run straight through them. Plain Text needs no '
                  'per-widget change to take part.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: EdenSpacing.space3),
                const EdenCard(
                  title: 'A card inside the region',
                  subtitle: 'Its title and subtitle are selectable too.',
                ),
                const SizedBox(height: EdenSpacing.space3),
                const EdenKeyValueTable(
                  items: <EdenKeyValue>[
                    EdenKeyValue(key: 'Region', value: 'us-east-1'),
                    EdenKeyValue(key: 'Build', value: '2026.09.16'),
                  ],
                ),
                const SizedBox(height: EdenSpacing.space3),
                SelectionContainer.disabled(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: EdenColors.neutral[400]!),
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(EdenSpacing.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'EXCLUDED FROM SELECTION',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: EdenColors.neutral[500],
                            ),
                          ),
                          const SizedBox(height: EdenSpacing.space2),
                          const Text(
                            'This subtree is wrapped in '
                            'SelectionContainer.disabled, the documented '
                            'opt-out. Interactive subtrees belong here, or a '
                            'drag across the surface swallows their labels. '
                            'Drag through it and watch the read-out skip it.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: EdenSpacing.space2),
                          EdenButton(
                            label: 'An action, not text',
                            variant: EdenButtonVariant.secondary,
                            size: EdenButtonSize.sm,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space5),
          Text(
            'onSelectionChanged READ-OUT',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: EdenColors.neutral[500],
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenCard(
            child: Text(
              _selected.isEmpty ? '(nothing selected)' : _selected,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: EdenSpacing.space3),
          const _Prose(
            'SelectedContent carries plain text only - no offsets, no rich '
            'content. That is the entire notification surface available at the '
            'declared SDK floor, so do not build an API on top of it that '
            'implies otherwise.',
          ),
        ],
      ),
    );
  }
}

/// Interactive story for [EdenSelectableRegion].
final EdenStory selectionRegionStory = EdenStory(
  id: 'selection/region',
  component: 'selection',
  name: 'Region',
  icon: Icons.highlight_alt,
  knobs: const <KnobSpec>[
    BoolKnob(key: 'enabled', label: 'Enabled', defaultValue: true),
  ],
  build: (BuildContext context, KnobValues k) =>
      _SelectionRegionDemo(enabled: k.get<bool>('enabled')),
);

// ---------------------------------------------------------------------------
// Story 4 - selection/table-copy
// ---------------------------------------------------------------------------

/// Three rows, not one: with a single row "copy row" and "copy table" produce
/// byte-identical output, so a one-row demo would hide the difference it exists
/// to show.
const List<EdenTableRow> _kDemoRows = <EdenTableRow>[
  EdenTableRow(
    cells: <Widget>[Text('INV-1001'), Text('Acme Corp'), Text('1,240.50')],
    copyValues: <String>['INV-1001', 'Acme Corp', '1240.50'],
  ),
  EdenTableRow(
    cells: <Widget>[Text('INV-1002'), Text('Globex'), Text('318.00')],
    copyValues: <String>['INV-1002', 'Globex', '318.00'],
  ),
  EdenTableRow(
    cells: <Widget>[Text('INV-1003'), Text('Initech'), Text('9,875.25')],
    copyValues: <String>['INV-1003', 'Initech', '9875.25'],
  ),
];

/// Interactive story for the TSV copy affordance on both table widgets.
final EdenStory selectionTableCopyStory = EdenStory(
  id: 'selection/table-copy',
  component: 'selection',
  name: 'Table Copy',
  icon: Icons.table_view,
  knobs: const <KnobSpec>[],
  build: (BuildContext context, KnobValues k) => SingleChildScrollView(
    padding: const EdgeInsets.all(EdenSpacing.space4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Prose(
          'A selection region is not enough for tabular data. SelectionArea '
          'concatenates the selected fragments in tree order with NO tab or '
          'newline between cells, so drag-copying a table yields run-together '
          'text that is useless in a spreadsheet. Tabular surfaces therefore '
          'need an explicit TSV copy action IN ADDITION to the region - it is '
          'not something the region can fix.',
        ),
        const _Prose(
          'Both are opt-in per table (copyable: false by default), because a '
          'new icon appearing in every existing table unannounced would be a '
          'visual regression for downstream consumers. Note the copyValues on '
          'each row: supply them whenever a cell renders something other than '
          'plain text, so the copied value is the DATA rather than whatever '
          'string happened to be on screen - "1,240.50" on screen is rarely '
          'what belongs in a spreadsheet cell.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'EdenDataTable(copyable: true)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: EdenSpacing.space2),
                  EdenDataTable(
                    copyable: true,
                    columns: <EdenTableColumn>[
                      EdenTableColumn(label: 'Invoice'),
                      EdenTableColumn(label: 'Customer'),
                      EdenTableColumn(label: 'Amount'),
                    ],
                    rows: _kDemoRows,
                  ),
                ],
              ),
            ),
            const SizedBox(width: EdenSpacing.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'EdenKeyValueTable(copyable: true)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  const EdenKeyValueTable(
                    copyable: true,
                    items: <EdenKeyValue>[
                      EdenKeyValue(key: 'Invoice', value: 'INV-1001'),
                      EdenKeyValue(key: 'Customer', value: 'Acme Corp'),
                      EdenKeyValue(key: 'Amount', value: '1,240.50'),
                      EdenKeyValue(
                        key: 'Reference',
                        value: 'a3f9c2e1',
                        monospace: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: EdenSpacing.space3),
                  Text(
                    'Copy table writes every pair as TSV, one row per line, '
                    'which pastes into a spreadsheet as real columns.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: EdenColors.neutral[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);

// ---------------------------------------------------------------------------
// Registration list
// ---------------------------------------------------------------------------

/// The four Objective 040 stories, registered by `register_all.dart`.
final List<EdenStory> autofillSelectionStories = <EdenStory>[
  autofillPurposesStory,
  autofillLoginFormStory,
  selectionRegionStory,
  selectionTableCopyStory,
];
