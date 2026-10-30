import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/catalog_constants.dart';
import '../../domain/catalog/prop_field.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../../domain/catalog/widget_def.dart';
import '../controllers/editor_controller.dart';
import '../controllers/templates_controller.dart';
import '../renderer/node_renderer.dart';
import '../theme/icon_registry.dart';

/// پنل‌های پایین ادیتور: افزودن ویجت، انتخاب نمونه، ویژگی‌ها و ذخیره‌ی قالب.
class EditorPanels {
  final TemplatesController templates;
  const EditorPanels(this.templates);

  void showSaveTemplateDialog(EditorController c) {
    final t = TextEditingController();
    Get.defaultDialog(
      title: 'نام قالب',
      content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'مثلاً دکمه سبز بولد')),
      textConfirm: 'ذخیره',
      textCancel: 'لغو',
      onConfirm: () async {
        final name = t.text.trim();
        if (name.isEmpty) return;
        Get.back();
        final sel = c.selected;
        if (sel != null) await templates.saveFromNode(name, sel);
        Get.snackbar('ذخیره شد', 'در لیست افزودن، بخش «قالب‌های من» است.');
      },
    );
  }

  /// پنل چسبیده به پایین؛ صفحه‌ی بالا همچنان دیده می‌شود و قابل لمس است
  Widget panelBox(EditorController c) => Material(
        elevation: 12,
        color: Get.theme.colorScheme.surface,
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(c.panelTitle.value, style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            IconButton(tooltip: 'بستن', visualDensity: VisualDensity.compact, iconSize: 20, icon: const Icon(Icons.close), onPressed: c.closePanel),
          ]),
          const Divider(height: 1),
          Expanded(child: c.panel.value!),
        ]),
      );

  Widget _templateTile(EditorController c, Template t) => ListTile(
        title: Text(t.name),
        subtitle: templatePreview(t.node),
        onTap: () {
          c.closePanel();
          c.addTemplate(t);
        },
      );

  void showAddPanel(EditorController c) {
    final pg = c.page.value!;
    final hidden = [
      if (pg.appBar.props['hidden'] == true) 'appBar',
      if (pg.footer.props['hidden'] == true) 'footer',
    ];
    c.showPanel(
      'افزودن ویجت',
      'add',
      ListView(padding: const EdgeInsets.all(12), children: [
        for (final k in hidden)
          ListTile(
            dense: true,
            leading: Icon(iconForType(k)),
            title: Text('بازگرداندن ${WidgetCatalog.of(k).label}'),
            onTap: () {
              c.closePanel();
              c.restoreSection(k);
            },
          ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            for (final d in WidgetCatalog.addable)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (WidgetCatalog.variantsOf(d).length > 1 || templates.items.any((t) => t.node.type == d.type)) {
                    _variantSheet(c, d);
                  } else {
                    c.closePanel();
                    c.add(d.type);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(iconForType(d.type), size: 24),
                    const SizedBox(height: 4),
                    Text(d.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5)),
                  ]),
                ),
              ),
          ],
        ),
        if (templates.items.isNotEmpty) ...[
          const Divider(),
          Text('قالب‌های من', style: Get.textTheme.titleSmall),
          for (final t in templates.items) _templateTile(c, t),
        ],
      ]),
    );
  }

  /// نمونه‌های آماده‌ی داخلی + قالب‌های ذخیره‌شده‌ی خود کاربر از همین نوع
  void _variantSheet(EditorController c, WidgetDef d) {
    final mine = templates.items.where((t) => t.node.type == d.type).toList();
    c.showPanel(
      'نمونه‌ی ${d.label}',
      'variant',
      ListView(padding: const EdgeInsets.all(12), children: [
        if (WidgetCatalog.variantsOf(d).isEmpty)
          ListTile(
            title: const Text('پیش‌فرض'),
            subtitle: templatePreview(WidgetCatalog.create(d.type)),
            onTap: () {
              c.closePanel();
              c.add(d.type);
            },
          ),
        for (final v in WidgetCatalog.variantsOf(d))
          ListTile(
            title: Text(v.label),
            subtitle: templatePreview(WidgetNode(type: d.type, props: {...d.defaults, 'variant': v.id, ...v.props})),
            onTap: () {
              c.closePanel();
              c.add(d.type, v);
            },
          ),
        if (mine.isNotEmpty) ...[
          const Divider(),
          Text('قالب‌های من', style: Get.textTheme.titleSmall),
          for (final t in mine) _templateTile(c, t),
        ],
      ]),
    );
  }

  void showPropsPanel(EditorController c, WidgetNode n) {
    final def = WidgetCatalog.of(n.type);
    final par = c.parentOf(n.id);
    final flexOk = par != null &&
        (par.type == 'row' ||
            (par.type == 'footer' && (par.props['variant'] ?? 'bar') == 'bar') ||
            (par.type == 'appBar' && par.props['variant'] == 'custom'));
    final fields = [...def.fields, if (flexOk) kFlexField];
    List<PropField> of(PropType t) => fields.where((f) => f.type == t).toList();

    c.showPanel(
      'ویژگی‌های ${def.label}',
      'props',
      StatefulBuilder(builder: (ctx, set) {
        final third = (Get.width - 32 - 16) / 3; // عددی‌ها: سه ستون
        final half = (Get.width - 32 - 8) / 2; // گزینه‌ای‌ها: دو ستون
        final nums = of(PropType.number), opts = of(PropType.option), bools = of(PropType.boolean);
        final sections = <Widget>[
          // نمونه‌های آماده: چیپ‌های فشرده
          if (def.variants.length > 1)
            Wrap(spacing: 6, children: [
              for (final v in def.variants)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: const TextStyle(fontSize: 12),
                  label: Text(v.label),
                  selected: n.props['variant'] == v.id,
                  onSelected: (_) {
                    c.applyVariant(n, v);
                    set(() {});
                  },
                ),
            ]),
          for (final f in of(PropType.icon)) _iconPicker(c, n, f, set),
          for (final f in of(PropType.text)) _textBox(c, n, f),
          for (final f in of(PropType.color)) _colorRow(c, n, f, set),
          if (nums.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in nums) SizedBox(width: third, child: _numBox(c, n, f)),
            ]),
          if (opts.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in opts) SizedBox(width: half, child: _optBox(c, n, f)),
            ]),
          if (bools.isNotEmpty)
            Wrap(spacing: 6, children: [
              for (final f in bools)
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: const TextStyle(fontSize: 12),
                  label: Text(_short(f.label)),
                  selected: n.props[f.key] == true,
                  onSelected: (b) {
                    c.setProp(n, f.key, b);
                    set(() {});
                  },
                ),
            ]),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [for (final w in sections) Padding(padding: const EdgeInsets.only(bottom: 12), child: w)],
        );
      }),
    );
  }

  static const _border = OutlineInputBorder();
  static const _lbl = TextStyle(fontSize: 12);

  ValueKey<String> _key(WidgetNode n, PropField f) => ValueKey('${n.id}${f.key}${n.props['variant']}');

  Widget _textBox(EditorController c, WidgetNode n, PropField f) => TextFormField(
        key: _key(n, f),
        initialValue: '${n.props[f.key] ?? ''}',
        maxLines: f.key == 'svg' ? 4 : 1,
        decoration: InputDecoration(labelText: f.label, labelStyle: _lbl, isDense: true, border: _border),
        onChanged: (s) => c.setProp(n, f.key, s),
      );

  Widget _numBox(EditorController c, WidgetNode n, PropField f) => Tooltip(
        message: f.label,
        child: TextFormField(
          key: _key(n, f),
          initialValue: _fmt(n.props[f.key]),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: _short(f.label), labelStyle: _lbl, isDense: true, border: _border),
          onChanged: (s) => c.setProp(n, f.key, double.tryParse(s) ?? 0.0),
        ),
      );

  Widget _optBox(EditorController c, WidgetNode n, PropField f) => DropdownButtonFormField<String>(
        key: ValueKey('${n.id}${f.key}${n.props[f.key]}'),
        value: f.options.contains(n.props[f.key]) ? n.props[f.key] as String : null,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(labelText: _short(f.label), labelStyle: _lbl, isDense: true, border: _border),
        items: [
          for (final o in f.options) DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))),
        ],
        onChanged: (v) {
          if (v != null) c.setProp(n, f.key, v);
        },
      );

  Widget _colorRow(EditorController c, WidgetNode n, PropField f, StateSetter set) {
    final v = n.props[f.key];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_short(f.label), style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final col in kPalette)
          GestureDetector(
            onTap: () {
              c.setProp(n, f.key, col);
              set(() {});
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(col),
                shape: BoxShape.circle,
                border: Border.all(color: v == col ? Colors.blue : Colors.grey.shade400, width: v == col ? 3 : 1),
              ),
              child: col == 0x00000000 ? const Icon(Icons.block, size: 14, color: Colors.grey) : null,
            ),
          ),
      ]),
    ]);
  }

  Widget _iconPicker(EditorController c, WidgetNode n, PropField f, StateSetter set) {
    final v = n.props[f.key];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_short(f.label), style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (final e in kIconData.entries)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              c.setProp(n, f.key, e.key);
              set(() {});
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: v == e.key ? Get.theme.colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(e.value, size: 20),
            ),
          ),
      ]),
    ]);
  }
}

/// «عرض (۰ = خودکار)» → «عرض»؛ متن کامل در Tooltip (نگه‌داشتن انگشت) دیده می‌شود
String _short(String s) => s.split('(').first.trim();

/// ۸.۰ → ۸  (عددهای صحیح بدون اعشار)
String _fmt(dynamic v) {
  if (v is! num) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
