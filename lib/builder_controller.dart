import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:untitled/node.dart';
import 'package:untitled/registry.dart';
import 'package:untitled/storage.dart';

class BuilderController extends GetxController {
  final pages = <PageModel>[].obs;
  final templates = <Template>[].obs;
  final page = Rxn<PageModel>();
  final selectedId = RxnString();
  final tick = 0.obs; // با هر تغییر زیاد می‌شود تا Canvas دوباره بسازد
  final preview = false.obs;

  // پنل پایین ادیتور (به‌جای bottom sheet تا صفحه همیشه دیده شود)
  final panel = Rxn<Widget>();
  final panelTitle = ''.obs;
  String panelKind = '';

  void showPanel(String title, String kind, Widget w) {
    panelTitle.value = title;
    panelKind = kind;
    panel.value = w;
  }

  void closePanel() {
    panelKind = '';
    panel.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    loadPages();
    loadTemplates();
  }

  void loadPages() => pages.assignAll(Storage.all());
  void loadTemplates() => templates.assignAll(Storage.allTemplates());

  /// ویجت انتخاب‌شده (با فرزندانش) را به‌عنوان قالب ذخیره می‌کند
  Future<void> saveSelectedAsTemplate(String name) async {
    final sel = selected;
    if (sel == null || selectedIsRoot) return;
    await Storage.saveTemplate(
        Template(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, node: sel.clone()));
    loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await Storage.deleteTemplate(id);
    loadTemplates();
  }

  Future<void> importTemplates() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      final list = jsonDecode(d?.text ?? '') as List;
      for (final e in list) {
        await Storage.saveTemplate(Template.fromJson(Map<String, dynamic>.from(e as Map)));
      }
      loadTemplates();
      Get.snackbar('انجام شد', '${list.length} قالب وارد شد.');
    } catch (_) {
      Get.snackbar('خطا', 'محتوای کلیپ‌بورد، JSON معتبر قالب نیست.');
    }
  }

  String exportTemplatesJson() => jsonEncode(templates.map((t) => t.toJson()).toList());

  Future<void> createPage(String name) async {
    final p = PageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      appBar: Registry.create('appBar')..props['title'] = name,
      body: Registry.create('column'),
      footer: Registry.create('footer'),
    );
    await Storage.save(p);
    loadPages();
    open(p);
  }

  Future<void> deletePage(String id) async {
    await Storage.delete(id);
    loadPages();
  }

  void open(PageModel p) {
    page.value = p;
    selectedId.value = null;
    closePanel();
    preview.value = false;
    tick.value++;
  }

  // ---------- جستجو در درخت ----------
  Iterable<WidgetNode> _walk(WidgetNode n) sync* {
    yield n;
    for (final c in n.children) {
      yield* _walk(c);
    }
  }

  Iterable<WidgetNode> get _all {
    final p = page.value!;
    return [p.appBar, p.body, p.footer].expand(_walk);
  }

  WidgetNode? find(String id) => _all.where((n) => n.id == id).firstOrNull;
  WidgetNode? parentOf(String id) => _all.where((n) => n.children.any((c) => c.id == id)).firstOrNull;
  WidgetNode? get selected => selectedId.value == null ? null : find(selectedId.value!);
  bool get selectedIsRoot => selected != null && parentOf(selected!.id) == null;

  // ---------- عملیات ----------
  void select(String? id) {
    selectedId.value = id;
    if (panelKind == 'props') closePanel(); // پنل ویژگی‌ها مال ویجت قبلی بود
    tick.value++;
  }

  void add(String type, [Variant? variant]) {
    final node = Registry.create(type);
    if (variant != null) {
      node.props
        ..['variant'] = variant.id
        ..addAll(variant.props);
    }
    _insert(node);
  }

  void addTemplate(Template t) => _insert(t.instantiate());

  /// اگر یک Container انتخاب باشد داخلش، وگرنه کنار ویجت انتخابی، وگرنه داخل body
  void _insert(WidgetNode node) {
    WidgetNode target = page.value!.body;
    int? index;
    final sel = selected;
    if (sel != null) {
      if (Registry.of(sel.type).container) {
        target = sel;
      } else {
        final par = parentOf(sel.id);
        if (par != null) {
          target = par;
          index = par.children.indexOf(sel) + 1;
        }
      }
    }
    index == null ? target.children.add(node) : target.children.insert(index, node);
    selectedId.value = node.id;
    _changed();
  }

  /// اعمال نمونه‌ی آماده؛ برای فوتر ناوبری، اگر آیتمی نیست ۳ آیتم پیش‌فرض می‌سازد
  void applyVariant(WidgetNode n, Variant v) {
    n.props
      ..['variant'] = v.id
      ..addAll(v.props);
    if (n.type == 'footer' && v.id != 'bar' && !n.children.any((k) => k.type == 'navItem')) {
      for (final e in const [('home', 'خانه'), ('search', 'جستجو'), ('person', 'پروفایل')]) {
        final it = Registry.create('navItem');
        it.props['icon'] = e.$1;
        it.props['label'] = e.$2;
        n.children.add(it);
      }
    }
    // اپ‌بار آزاد: چند آیتم اولیه می‌گذاریم تا Row خالی نباشد
    if (n.type == 'appBar' && v.id == 'custom' && n.children.isEmpty) {
      final t = Registry.create('text');
      t.props['text'] = '${n.props['title'] ?? 'عنوان'}';
      t.props['color'] = 0xFFFFFFFF;
      t.props['bold'] = true;
      t.props['size'] = 20.0;
      t.props['flex'] = 1.0;
      final ic = Registry.create('icon');
      ic.props['icon'] = 'search';
      ic.props['color'] = 0xFFFFFFFF;
      n.children.addAll([t, ic]);
    }
    _changed();
  }

  /// ویجت عادی حذف می‌شود؛ اپ‌بار و فوتر «پنهان» می‌شوند (با افزودن، برمی‌گردند)؛ بدنه حذف‌شدنی نیست
  void removeSelected() {
    final sel = selected;
    if (sel == null) return;
    final p = page.value!;
    if (sel.id == p.appBar.id || sel.id == p.footer.id) {
      sel.props['hidden'] = true;
    } else if (selectedIsRoot) {
      return;
    } else {
      parentOf(sel.id)!.children.remove(sel);
    }
    selectedId.value = null;
    if (panelKind == 'props') closePanel();
    _changed();
  }

  void restoreSection(String type) {
    final p = page.value!;
    final n = type == 'appBar' ? p.appBar : p.footer;
    n.props['hidden'] = false;
    selectedId.value = n.id;
    _changed();
  }

  void move(int delta) {
    final sel = selected;
    if (sel == null) return;
    final list = parentOf(sel.id)?.children;
    if (list == null) return;
    final i = list.indexOf(sel);
    final j = i + delta;
    if (j < 0 || j >= list.length) return;
    list.removeAt(i);
    list.insert(j, sel);
    _changed();
  }

  void setProp(WidgetNode n, String key, dynamic value) {
    n.props[key] = value;
    _changed();
  }

  void _changed() {
    tick.value++;
    Storage.save(page.value!);
  }
}
