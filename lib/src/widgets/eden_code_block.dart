import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_code_block Rails component.
///
/// Displays code in a dark block with optional language label and copy button.
class EdenCodeBlock extends StatelessWidget {
  const EdenCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.lineNumbers = false,
    this.copyable = true,
  });

  final String code;
  final String? language;
  final bool lineNumbers;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EdenColors.neutral[900],
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null || copyable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4, vertical: EdenSpacing.space2),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: EdenColors.neutral[700]!)),
              ),
              child: Row(
                children: [
                  if (language != null)
                    Text(
                      language!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EdenColors.neutral[400]),
                    ),
                  const Spacer(),
                  if (copyable)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 14, color: EdenColors.neutral[400]),
                          const SizedBox(width: 4),
                          Text('Copy', style: TextStyle(fontSize: 12, color: EdenColors.neutral[400])),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: lineNumbers
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines.asMap().entries.map((entry) => Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: EdenColors.neutral[600]),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          entry.value,
                          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: EdenColors.neutral[100]),
                        ),
                      ],
                    )).toList(),
                  )
                : Text(
                    code,
                    style: GoogleFonts.jetBrainsMono(fontSize: 13, color: EdenColors.neutral[100]),
                  ),
          ),
        ],
      ),
    );
  }
}
