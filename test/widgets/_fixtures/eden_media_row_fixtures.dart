// Do NOT regenerate via LLM — hand-built fixtures for EdenMediaRow.
//
// Hand-picked media-row items covering the icon / count / label / trailing
// combinations exercised in 003-08-TRD.md test list.
//
// Add new fixtures by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenMediaRowFixtures {
  EdenMediaRowFixtures._();

  static EdenMediaRowItem photosItem({VoidCallback? onAdd}) {
    return EdenMediaRowItem(
      icon: Icons.camera_alt,
      label: 'photos',
      count: '7',
      onAddPressed: onAdd,
    );
  }

  static EdenMediaRowItem docsItem({VoidCallback? onAdd}) {
    return EdenMediaRowItem(
      icon: Icons.description,
      label: 'documents',
      count: '3',
      onAddPressed: onAdd,
    );
  }

  static EdenMediaRowItem budgetItem({String trailing = '1 CO'}) {
    return EdenMediaRowItem(
      icon: Icons.attach_money,
      label: 'budget',
      count: r'$24,500',
      trailingText: trailing,
    );
  }

  static const EdenMediaRowItem longLabelItem = EdenMediaRowItem(
    icon: Icons.list,
    label: 'a really long label that should ellipsize on narrow viewports',
  );

  static const EdenMediaRowItem noCountItem = EdenMediaRowItem(
    icon: Icons.star,
    label: 'favorited',
  );
}
