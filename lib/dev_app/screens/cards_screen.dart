import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  bool _isClickable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          InteractivePlayground(
            title: 'Interactive Explorer',
            preview: EdenCard(
              title: 'Preview Card',
              subtitle: 'Tap to interact',
              onTap: _isClickable ? () {} : null,
            ),
            controls: [
              ToggleControl(label: 'Clickable', value: _isClickable, onChanged: (v) => setState(() => _isClickable = v)),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          const Section(
            title: 'Standard Card',
            child: EdenCard(
              title: 'Card Title',
              subtitle: 'This is a standard card with a title and subtitle.',
            ),
          ),
          Section(
            title: 'Card with Content',
            child: EdenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Custom Content', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Cards can contain any widget as their child content.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  EdenButton(label: 'Action', size: EdenButtonSize.sm, onPressed: () {}),
                ],
              ),
            ),
          ),
          const Section(
            title: 'Gradient Card',
            child: EdenCard(
              gradient: true,
              title: 'Gradient Card',
              subtitle: 'A card with a primary color gradient background.',
            ),
          ),
          const Section(
            title: 'Glass Card',
            child: EdenCard(
              glass: true,
              title: 'Glass Card',
              subtitle: 'A frosted glass-style card.',
            ),
          ),
          Section(
            title: 'Tappable Card',
            child: EdenCard(
              title: 'Tap Me',
              subtitle: 'This card responds to taps.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card tapped!')),
                );
              },
            ),
          ),
          const Section(
            title: 'Interactive variant — hover lift + focus ring (Obj 010)',
            child: _InteractiveCardDemos(),
          ),
        ],
      ),
    );
  }
}

class _InteractiveCardDemos extends StatelessWidget {
  const _InteractiveCardDemos();

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Side-by-side comparison'),
        const SizedBox(height: EdenSpacing.space2),
        Row(children: [
          Expanded(child: EdenCard(
            title: 'Default',
            subtitle: 'Tap → ripple only',
            onTap: () => _snack(context, 'Default tap'),
          )),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(child: EdenCard.interactive(
            title: 'Interactive',
            subtitle: 'Hover → lift + focus ring + ripple',
            onTap: () => _snack(context, 'Interactive tap'),
          )),
        ]),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Focus traversal (tab between)'),
        const SizedBox(height: EdenSpacing.space2),
        Column(children: [
          EdenCard.interactive(title: 'First',  subtitle: 'Tab to focus', onTap: () => _snack(context, 'First')),
          const SizedBox(height: EdenSpacing.space2),
          EdenCard.interactive(title: 'Second', subtitle: 'Tab to focus', onTap: () => _snack(context, 'Second')),
          const SizedBox(height: EdenSpacing.space2),
          EdenCard.interactive(title: 'Third',  subtitle: 'Tab to focus', onTap: () => _snack(context, 'Third')),
        ]),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Long-press handler'),
        const SizedBox(height: EdenSpacing.space2),
        EdenCard.interactive(
          title: 'Long-press me',
          subtitle: 'Try a long press',
          onTap: () => _snack(context, 'Tap'),
          onLongPress: () => _snack(context, 'Long-press!'),
        ),
      ],
    );
  }
}
