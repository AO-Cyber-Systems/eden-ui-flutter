import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class AvatarsScreen extends StatelessWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatars')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'Sizes',
            child: Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenAvatarSize.values.map((s) => EdenAvatar(
                initials: 'JD',
                size: s,
              )).toList(),
            ),
          ),
          Section(
            title: 'With Status',
            child: Wrap(
              spacing: 16,
              children: EdenAvatarStatus.values.map((s) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EdenAvatar(
                    initials: s.name[0].toUpperCase() + s.name[1],
                    size: EdenAvatarSize.lg,
                    status: s,
                  ),
                  const SizedBox(height: 4),
                  Text(s.name, style: Theme.of(context).textTheme.labelSmall),
                ],
              )).toList(),
            ),
          ),
          Section(
            title: 'Initials Variants',
            child: Wrap(
              spacing: 12,
              children: [
                EdenAvatar(initials: 'AB', backgroundColor: EdenColors.blue[100]),
                EdenAvatar(initials: 'CD', backgroundColor: EdenColors.emerald[100]),
                EdenAvatar(initials: 'EF', backgroundColor: EdenColors.purple[100]),
                EdenAvatar(initials: 'GH', backgroundColor: EdenColors.red[100]),
                const EdenAvatar(initials: '?'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
