import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
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
          Section(
            title: 'Gradient Card',
            child: EdenCard(
              gradient: true,
              title: 'Gradient Card',
              subtitle: 'A card with a primary color gradient background.',
            ),
          ),
          Section(
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
        ],
      ),
    );
  }
}
