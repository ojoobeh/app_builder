import 'dart:convert';

/// یک ویجت در درخت صفحه: نوع + ویژگی‌ها + فرزندان.
/// مثال: WidgetNode(type: 'text', props: {'text': 'سلام'})
/// این کلاس هیچ وابستگی‌ای به Flutter یا ذخیره‌سازی ندارد.
class WidgetNode {
  static int _counter = 0; // شمارنده برای یکتا بودن شناسه‌ها
  final String id; // شناسه‌ی یکتا (برای انتخاب و جستجو)
  final String type; // نوع ویجت: 'button'، 'text'، 'row' و ...
  Map<String, dynamic> props; // ویژگی‌ها (رنگ، اندازه، متن، ...)
  List<WidgetNode> children; // فرزندان

  WidgetNode({String? id, required this.type, Map<String, dynamic>? props, List<WidgetNode>? children})
      : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
        props = props ?? {},
        children = children ?? [];

  /// کپی عمیق با شناسه‌های جدید
  WidgetNode clone() => WidgetNode(
        type: type,
        props: Map<String, dynamic>.from(jsonDecode(jsonEncode(props)) as Map),
        children: children.map((child) => child.clone()).toList(),
      );
}
