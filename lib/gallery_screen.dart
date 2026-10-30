import 'package:flutter/material.dart';
import 'package:untitled/code_generator.dart';
import 'package:untitled/node.dart';
import 'package:untitled/registry.dart';
import 'package:untitled/renderer.dart';

/// نمایشگاه ویجت‌ها: خودکار از Registry ساخته می‌شود.
/// هر ویجت/نمونه‌ی جدیدی که در registry.dart ثبت کنی، همین‌جا دیده می‌شود.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  static WidgetNode _n(String type, [Map<String, dynamic> over = const {}, List<WidgetNode> kids = const []]) {
    final node = Registry.create(type);
    node.props.addAll(over);
    node.children.addAll(kids);
    return node;
  }

  /// ساخت یک نمونه با فرزندهای آزمایشی (برای ویجت‌های کانتینری)
  static WidgetNode sample(String type, [Variant? v]) {
    final node = Registry.create(type);
    if (v != null) {
      node.props
        ..['variant'] = v.id
        ..addAll(v.props);
    }
    switch (type) {
      case 'appBar':
        node.children.addAll([_n('icon', {'icon': 'search', 'color': 0xFFFFFFFF}), _n('icon', {'icon': 'cart', 'color': 0xFFFFFFFF})]);
        break;
      case 'footer':
        node.children.addAll([
          _n('navItem', {'icon': 'home', 'label': 'خانه'}),
          _n('navItem', {'icon': 'search', 'label': 'جستجو'}),
          _n('navItem', {'icon': 'person', 'label': 'پروفایل'}),
        ]);
        break;
      case 'column':
        node.children.addAll([_n('text', {'text': 'مورد اول'}), _n('text', {'text': 'مورد دوم'}), _n('text', {'text': 'مورد سوم'})]);
        break;
      case 'row':
        node.children.addAll([
          _n('button', {'text': 'الف', 'flex': 1.0}),
          _n('button', {'text': 'ب', 'flex': 1.0}),
          _n('button', {'text': 'ج', 'flex': 2.0}),
        ]);
        break;
      case 'stack':
        node.children.addAll([_n('container', {'width': 220.0, 'height': 80.0}), _n('text', {'text': 'روی هم'})]);
        break;
      case 'container':
      case 'card':
        node.children.add(_n('text', {'text': 'داخل کادر'}));
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'راهنمای افزودن ویجت جدید:\n'
                '۱) در registry.dart یک WidgetDef (و در صورت نیاز Variant) ثبت کن.\n'
                '۲) در renderer.dart یک case برای نمایش در ادیتور بنویس.\n'
                '۳) در code_generator.dart یک case برای خروجی دارت بنویس.\n'
                'اگر ویجت فرزند دارد، نمونه‌ی آزمایشی‌اش را در تابع sample همین فایل اضافه کن.',
              ),
            ),
          ),
          for (final d in Registry.list) _section(d),
        ],
      ),
    );
  }

  Widget _section(WidgetDef d) {
    final all = Registry.variantsOf(d);
    final variants = all.isEmpty ? <Variant?>[null] : all;
    final hasCode = d.type != 'appBar' && d.type != 'footer';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(d.icon),
            const SizedBox(width: 8),
            Expanded(child: Text('${d.label}  (${d.type})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ]),
          const SizedBox(height: 4),
          Text('ویژگی‌ها: ${d.fields.map((f) => f.key).join(', ')}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          for (final v in variants) ...[
            const Divider(height: 24),
            if (v != null) Text('${v.label}  [${v.id}]', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            if (v != null) const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: renderNode(sample(d.type, v), edit: false)),
          ],
          if (hasCode)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('کد دارت خروجی', style: TextStyle(fontSize: 13)),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(gen(sample(d.type, variants.first), 0),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ],
            ),
        ]),
      ),
    );
  }
}
