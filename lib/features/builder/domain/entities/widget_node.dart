import 'dart:convert';

/// یک ویجت در درخت صفحه: نوع + ویژگی‌ها + فرزندان.
/// این کلاس هیچ وابستگی‌ای به Flutter یا ذخیره‌سازی ندارد.
class WidgetNode {
  static int _counter = 0;
  final String id;
  final String type;
  Map<String, dynamic> props;
  List<WidgetNode> children;

  WidgetNode({String? id, required this.type, Map<String, dynamic>? props, List<WidgetNode>? children})
      : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
        props = props ?? {},
        children = children ?? [];

  /// کپی عمیق با شناسه‌های جدید
  WidgetNode clone() => WidgetNode(
        type: type,
        props: Map<String, dynamic>.from(jsonDecode(jsonEncode(props)) as Map),
        children: children.map((c) => c.clone()).toList(),
      );
}
