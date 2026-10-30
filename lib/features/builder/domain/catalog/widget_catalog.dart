import 'definitions/app_bar_def.dart';
import 'definitions/footer_def.dart';
import 'definitions/nav_item_def.dart';
import 'definitions/column_def.dart';
import 'definitions/row_def.dart';
import 'definitions/stack_def.dart';
import 'definitions/container_def.dart';
import 'definitions/card_def.dart';
import 'definitions/text_def.dart';
import 'definitions/text_field_def.dart';
import 'definitions/icon_def.dart';
import 'definitions/svg_def.dart';
import 'definitions/button_def.dart';
import 'definitions/image_def.dart';
import 'catalog_constants.dart';
import 'widget_def.dart';
import '../entities/widget_node.dart';

/// فهرست همه‌ی ویجت‌های قابل استفاده. برای ویجت جدید: یک فایل در definitions/ بساز و اینجا ثبتش کن.
class WidgetCatalog {
  WidgetCatalog._();

  static final List<WidgetDef> list = [appBarDef, footerDef, navItemDef, columnDef, rowDef, stackDef, containerDef, cardDef, textDef, textFieldDef, iconDef, svgDef, buttonDef, imageDef];
  static final Map<String, WidgetDef> _byType = {for (final d in list) d.type: d};

  static WidgetDef of(String type) => _byType[type]!;

  /// ویجت‌هایی که کاربر می‌تواند اضافه کند (اپ‌بار و فوتر ثابت‌اند)
  static List<WidgetDef> get addable => list.where((d) => d.type != 'appBar' && d.type != 'footer').toList();

  /// نمونه‌های یک ویجت؛ برای آیکن، به‌ازای هر آیکن یک نمونه ساخته می‌شود
  static List<Variant> variantsOf(WidgetDef d) =>
      d.type == 'icon' ? [for (final k in kIconKeys) Variant(k, k, {'icon': k})] : d.variants;

  /// ساخت یک گره‌ی جدید با مقادیر پیش‌فرض
  static WidgetNode create(String type) =>
      WidgetNode(type: type, props: Map<String, dynamic>.from(of(type).defaults));
}
