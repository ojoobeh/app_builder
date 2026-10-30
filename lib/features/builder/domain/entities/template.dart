import 'widget_node.dart';

/// قالب کاربر: یک ویجت (با همه‌ی فرزندانش) که با نام ذخیره شده است
class Template {
  final String id;
  String name;
  final WidgetNode node;
  Template({required this.id, required this.name, required this.node});

  /// یک کپی مستقل برای افزودن به صفحه
  WidgetNode instantiate() => node.clone();
}
