import 'definitions/app_bar_def.dart';
import 'definitions/tab_item_def.dart';
import 'definitions/tabs_def.dart';
import 'definitions/checkbox_def.dart';
import 'definitions/radio_def.dart';
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
import 'definitions/data_list_def.dart';
import 'catalog_constants.dart';
import 'widget_def.dart';
import '../entities/widget_node.dart';

/// فهرست همه‌ی ویجت‌های قابل استفاده. برای ویجت جدید: یک فایل در definitions/ بساز و اینجا ثبتش کن.
class WidgetCatalog {
  WidgetCatalog._();

  static final List<WidgetDef> list = [appBarDef, footerDef, navItemDef, columnDef, rowDef, stackDef, containerDef, cardDef, textDef, textFieldDef, iconDef, svgDef, checkboxDef, radioDef, tabsDef, tabItemDef, buttonDef, imageDef, dataListDef];
  /// جستجوی سریع تعریف بر اساس نوع
  static final Map<String, WidgetDef> _byType = {for (final definition in list) definition.type: definition};

  /// تعریف یک نوع ویجت (مثلاً of('button'))
  static WidgetDef of(String type) => _byType[type]!;

  /// ویجت‌هایی که کاربر می‌تواند اضافه کند (اپ‌بار و فوتر ثابت‌اند)
  static List<WidgetDef> get addable => list.where((definition) => definition.type != 'appBar' && definition.type != 'footer').toList();

  /// نمونه‌های یک ویجت؛ برای آیکن، به‌ازای هر آیکن یک نمونه ساخته می‌شود
  static List<Variant> variantsOf(WidgetDef definition) => definition.type == 'icon'
      ? [for (final iconKey in kIconKeys) Variant(iconKey, iconKey, {'icon': iconKey})]
      : definition.variants;

  /// ساخت یک گره‌ی جدید با مقادیر پیش‌فرض
  static WidgetNode create(String type) {
    final node = WidgetNode(type: type, props: Map<String, dynamic>.from(of(type).defaults));
    // تب‌بندی جدید با سه تب آماده (هرکدام یک متن نمونه) ساخته می‌شود
    if (type == 'tabs') {
      for (final label in ['تب ۱', 'تب ۲', 'تب ۳']) {
        final tab = create('tabItem');
        tab.props['label'] = label;
        final sampleText = create('text');
        sampleText.props['text'] = 'محتوای $label';
        tab.children.add(sampleText);
        node.children.add(tab);
      }
    }
    // لیست داده‌ای جدید با یک قالب آماده‌ی آیتم: کارت + متن {{item.title}}
    if (type == 'dataList') {
      final card = create('card');
      final title = create('text');
      title.props['text'] = '{{item.title}}';
      card.children.add(title);
      node.children.add(card);
    }
    return node;
  }
}
