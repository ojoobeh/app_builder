import 'package:flutter/material.dart';
import '../../domain/bindings/response_bindings.dart';

/// فیلد متنی با چیپ‌های binding: با لمس هر چیپ، {{item.name}} در محل مکان‌نما درج می‌شود.
class BindingTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final int maxLines;
  final List<BindingSuggestion> suggestions;
  final ValueChanged<String> onChanged;

  const BindingTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    this.suggestions = const [],
  });

  @override
  State<BindingTextField> createState() => _BindingTextFieldState();
}

class _BindingTextFieldState extends State<BindingTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(BindingSuggestion suggestion) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final newText = text.replaceRange(start, end, suggestion.token);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + suggestion.token.length),
    );
    widget.onChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
      if (widget.suggestions.isNotEmpty) ...[
        const SizedBox(height: 4),
        const Text('اتصال به داده‌ی پاسخ (لمس کن تا درج شود):', style: TextStyle(fontSize: 11, color: Colors.grey)),
        Wrap(spacing: 6, runSpacing: 0, children: [
          for (final suggestion in widget.suggestions)
            ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: const TextStyle(fontSize: 12),
              label: Text(suggestion.expression),
              onPressed: () => _insert(suggestion),
            ),
        ]),
      ],
    ]);
  }
}
