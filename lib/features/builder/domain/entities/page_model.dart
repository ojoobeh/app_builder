import 'page_request.dart';
import 'widget_node.dart';

/// یک صفحه‌ی کاربر = سه بخش ثابت: اپ‌بار، بدنه، فوتر
class PageModel {
  final String id;
  String name;

  /// شناسه‌ی پروژه‌ای که این صفحه به آن تعلق دارد
  String projectId;
  WidgetNode appBar;
  WidgetNode body;
  WidgetNode footer;

  /// جهت صفحه: 'ltr' (چپ‌چین) یا 'rtl' (راست‌چین)
  String direction;

  /// درخواست خودکار به سرور هنگام ورود به صفحه (اختیاری)
  PageRequest request;

  PageModel({
    required this.id,
    required this.name,
    required this.projectId,
    required this.appBar,
    required this.body,
    required this.footer,
    this.direction = 'ltr',
    PageRequest? request,
  }) : request = request ?? PageRequest();
}
