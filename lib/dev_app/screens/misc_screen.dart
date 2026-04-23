import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class MiscScreen extends StatelessWidget {
  const MiscScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Misc')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          const Section(
            title: 'Progress Bars',
            child: Column(
              children: [
                EdenProgress(value: 0.25, label: 'Upload', showPercentage: true),
                SizedBox(height: 16),
                EdenProgress(value: 0.6, size: EdenProgressSize.sm, color: EdenColors.success),
                SizedBox(height: 16),
                EdenProgress(value: 0.85, size: EdenProgressSize.lg, color: EdenColors.warning, showPercentage: true),
              ],
            ),
          ),
          Section(
            title: 'Spinners',
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenSpinnerSize.values.map((s) => EdenSpinner(size: s)).toList(),
            ),
          ),
          const Section(
            title: 'Skeletons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EdenSkeleton.circle(size: 40),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EdenSkeleton.text(width: 160),
                          SizedBox(height: 8),
                          EdenSkeleton.text(width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                EdenSkeleton.block(height: 100),
              ],
            ),
          ),
          const Section(
            title: 'Dividers',
            child: Column(
              children: [
                EdenDivider(),
                SizedBox(height: 8),
                EdenDivider(label: 'OR'),
                SizedBox(height: 8),
                EdenDivider(label: 'Section Break'),
              ],
            ),
          ),
          Section(
            title: 'Tooltip',
            child: Row(
              children: [
                EdenTooltip(
                  message: 'This is a tooltip!',
                  child: EdenButton(
                    label: 'Hover Me',
                    variant: EdenButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
