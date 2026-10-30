import 'widget_node.dart';

/// یک صفحه‌ی کاربر = سه بخش ثابت: اپ‌بار، بدنه، فوتر
class PageModel {
  final String id;
  String name;
  WidgetNode appBar;
  WidgetNode body;
  WidgetNode footer;

  PageModel({required this.id, required this.name, required this.appBar, required this.body, required this.footer});
}
