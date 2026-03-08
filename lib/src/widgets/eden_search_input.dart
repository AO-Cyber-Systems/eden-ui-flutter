import 'package:flutter/material.dart';

/// Mirrors the eden_search_input Rails component.
///
/// A text field pre-styled for search, with a search icon and optional clear button.
class EdenSearchInput extends StatelessWidget {
  const EdenSearchInput({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: onClear != null
            ? GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
