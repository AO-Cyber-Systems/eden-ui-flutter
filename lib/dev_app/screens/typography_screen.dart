import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class TypographyScreen extends StatelessWidget {
  const TypographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Typography')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'Display',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Large', style: tt.displayLarge),
                const SizedBox(height: 8),
                Text('Display Medium', style: tt.displayMedium),
                const SizedBox(height: 8),
                Text('Display Small', style: tt.displaySmall),
              ],
            ),
          ),
          Section(
            title: 'Headlines',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Headline Large', style: tt.headlineLarge),
                const SizedBox(height: 8),
                Text('Headline Medium', style: tt.headlineMedium),
                const SizedBox(height: 8),
                Text('Headline Small', style: tt.headlineSmall),
              ],
            ),
          ),
          Section(
            title: 'Body',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Body Large — The quick brown fox jumps over the lazy dog.', style: tt.bodyLarge),
                const SizedBox(height: 8),
                Text('Body Medium — The quick brown fox jumps over the lazy dog.', style: tt.bodyMedium),
                const SizedBox(height: 8),
                Text('Body Small — The quick brown fox jumps over the lazy dog.', style: tt.bodySmall),
              ],
            ),
          ),
          Section(
            title: 'Labels',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Label Large', style: tt.labelLarge),
                const SizedBox(height: 8),
                Text('Label Medium', style: tt.labelMedium),
                const SizedBox(height: 8),
                Text('Label Small', style: tt.labelSmall),
              ],
            ),
          ),
          Section(
            title: 'Code (JetBrains Mono)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('const x = 42;', style: EdenTypography.codeLarge(context)),
                const SizedBox(height: 8),
                Text('function hello() {}', style: EdenTypography.codeMedium(context)),
                const SizedBox(height: 8),
                Text('npm install eden-ui', style: EdenTypography.codeSmall(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
