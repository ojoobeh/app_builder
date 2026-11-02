import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../../domain/catalog/widget_def.dart';
import '../../domain/codegen/dart_code_generator.dart';
import '../renderer/node_renderer.dart';
import '../theme/icon_registry.dart';

/// نمایشگاه ویجت‌ها: خودکار از WidgetCatalog ساخته می‌شود.
/// هر ویجت یا نمونه‌ی جدیدی که در کاتالوگ ثبت کنی، همین‌جا دیده می‌شود.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  /// یک گره‌ی آزمایشی می‌سازد: نوع + مقادیر دلخواه (روی پیش‌فرض‌ها) + فرزندان.
  /// مثال: _sampleNode('text', props: {'text': 'سلام'})
  static WidgetNode _sampleNode(
    String type, {
    Map<String, dynamic> props = const {},
    List<WidgetNode> children = const [],
  }) {
    final node = WidgetCatalog.create(type);
    node.props.addAll(props);
    node.children.addAll(children);
    return node;
  }

  /// یک نمونه‌ی نمایشی از ویجت [type] با نمونه‌ی آماده‌ی [variant].
  /// ویجت‌های کانتینری با فرزندان آزمایشی پر می‌شوند تا شکلشان دیده شود.
  static WidgetNode sample(String type, [Variant? variant]) {
    final node = WidgetCatalog.create(type);
    if (variant != null) {
      node.props
        ..['variant'] = variant.id
        ..addAll(variant.props);
    }
    switch (type) {
      case 'appBar': // دو آیکن سفید
        node.children.addAll([
          _sampleNode('icon', props: {'icon': 'search', 'color': 0xFFFFFFFF}),
          _sampleNode('icon', props: {'icon': 'cart', 'color': 0xFFFFFFFF}),
        ]);
        break;
      case 'footer': // سه آیتم ناوبری
        node.children.addAll([
          _sampleNode('navItem', props: {'icon': 'home', 'label': 'خانه'}),
          _sampleNode('navItem', props: {'icon': 'search', 'label': 'جستجو'}),
          _sampleNode('navItem', props: {'icon': 'person', 'label': 'پروفایل'}),
        ]);
        break;
      case 'column': // سه متن زیر هم
        node.children.addAll([
          _sampleNode('text', props: {'text': 'مورد اول'}),
          _sampleNode('text', props: {'text': 'مورد دوم'}),
          _sampleNode('text', props: {'text': 'مورد سوم'}),
        ]);
        break;
      case 'row': // سه دکمه با نسبت فضای ۱ : ۱ : ۲ (برای نمایش Expanded)
        node.children.addAll([
          _sampleNode('button', props: {'text': 'الف', 'flex': 1.0}),
          _sampleNode('button', props: {'text': 'ب', 'flex': 1.0}),
          _sampleNode('button', props: {'text': 'ج', 'flex': 2.0}),
        ]);
        break;
      case 'stack': // یک کادر و یک متن روی آن
        node.children.addAll([
          _sampleNode('container', props: {'width': 220.0, 'height': 80.0}),
          _sampleNode('text', props: {'text': 'روی هم'}),
        ]);
        break;
      case 'container':
      case 'card': // یک متن داخل کادر
        node.children.add(_sampleNode('text', props: {'text': 'داخل کادر'}));
        break;
    }
    return node;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نمایشگاه ویجت‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // کارت راهنمای افزودن ویجت جدید
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'راهنمای افزودن ویجت جدید:\n'
                '۱) domain/catalog/definitions/ یک فایل تعریف بساز و در widget_catalog.dart ثبتش کن.\n'
                '۲) presentation/renderer/node_renderer.dart یک case برای نمایش در ادیتور بنویس.\n'
                '۳) domain/codegen/dart_code_generator.dart یک case برای خروجی دارت بنویس.\n'
                '۴) آیکن نمایشی‌اش را در presentation/theme/icon_registry.dart (kTypeIcons) اضافه کن.\n'
                'اگر ویجت فرزند دارد، نمونه‌ی آزمایشی‌اش را در تابع sample همین فایل اضافه کن.',
              ),
            ),
          ),
          // یک بخش برای هر ویجت کاتالوگ
          for (final definition in WidgetCatalog.list) _widgetSection(definition),
        ],
      ),
    );
  }

  /// بخش یک ویجت: اسم، لیست ویژگی‌ها، همه‌ی نمونه‌ها و کد دارت خروجی
  Widget _widgetSection(WidgetDef definition) {
    final allVariants = WidgetCatalog.variantsOf(definition);
    // ویجتی که نمونه‌ی آماده ندارد یک بار با مقادیر پیش‌فرض نشان داده می‌شود (null = پیش‌فرض)
    final variantsToShow = allVariants.isEmpty ? <Variant?>[null] : allVariants;
    // اپ‌بار و فوتر کدشان جدا و در سطح صفحه ساخته می‌شود، پس تکه‌کد ندارند
    final hasCodeSnippet = definition.type != 'appBar' && definition.type != 'footer';

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // عنوان: آیکن + اسم + نوع
          Row(children: [
            Icon(iconForType(definition.type)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${definition.label}  (${definition.type})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          // کلید ویژگی‌های قابل تنظیم
          Text(
            'ویژگی‌ها: ${definition.fields.map((field) => field.key).join(', ')}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          // نمایش هر نمونه
          for (final variant in variantsToShow) ...[
            const Divider(height: 24),
            if (variant != null) ...[
              Text('${variant.label}  [${variant.id}]', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 6),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: renderNode(sample(definition.type, variant), RenderEnv.preview),
            ),
          ],
          // کد دارت خروجی (قابل باز و بسته شدن)
          if (hasCodeSnippet)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('کد دارت خروجی', style: TextStyle(fontSize: 13)),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    Get.find<DartCodeGenerator>().snippet(sample(definition.type, variantsToShow.first)),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
        ]),
      ),
    );
  }
}
