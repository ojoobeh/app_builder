import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../../domain/catalog/widget_def.dart';
import '../../domain/usecases/edit_page_usecases.dart';
import '../../domain/usecases/page_usecases.dart';

/// وضعیت ادیتور: صفحه‌ی باز، ویجت انتخابی، حالت پیش‌نمایش و پنل پایین.
/// منطق ویرایش درخت در usecaseها (domain) است؛ اینجا فقط هماهنگی و وضعیت UI.
class EditorController extends GetxController {
  final SavePage _savePage;
  final InsertNode _insertNode;
  final RemoveNode _removeNode;
  final MoveNode _moveNode;
  final ApplyVariant _applyVariant;
  final RestoreSection _restoreSection;

  EditorController({
    required SavePage savePage,
    InsertNode insertNode = const InsertNode(),
    RemoveNode removeNode = const RemoveNode(),
    MoveNode moveNode = const MoveNode(),
    ApplyVariant applyVariant = const ApplyVariant(),
    RestoreSection restoreSection = const RestoreSection(),
  })  : _savePage = savePage,
        _insertNode = insertNode,
        _removeNode = removeNode,
        _moveNode = moveNode,
        _applyVariant = applyVariant,
        _restoreSection = restoreSection;

  // ---------- وضعیت ----------
  final page = Rxn<PageModel>();
  final selectedId = RxnString();
  final tick = 0.obs; // با هر تغییر زیاد می‌شود تا صفحه دوباره ساخته شود
  final preview = false.obs;

  // پنل پایین ادیتور (به‌جای bottom sheet تا صفحه همیشه دیده شود)
  final panel = Rxn<Widget>();
  final panelTitle = ''.obs;
  String panelKind = '';

  PageModel get _p => page.value!;

  // ---------- پرس‌وجو ----------
  WidgetNode? find(String id) => PageTree.find(_p, id);
  WidgetNode? parentOf(String id) => PageTree.parentOf(_p, id);
  WidgetNode? get selected => selectedId.value == null ? null : find(selectedId.value!);
  bool get selectedIsRoot => selected != null && parentOf(selected!.id) == null;

  // ---------- صفحه و پنل ----------
  void open(PageModel p) {
    page.value = p;
    selectedId.value = null;
    closePanel();
    preview.value = false;
    tick.value++;
  }

  void showPanel(String title, String kind, Widget w) {
    panelTitle.value = title;
    panelKind = kind;
    panel.value = w;
  }

  void closePanel() {
    panelKind = '';
    panel.value = null;
  }

  void select(String? id) {
    selectedId.value = id;
    if (panelKind == 'props') closePanel(); // پنل ویژگی‌ها مال ویجت قبلی بود
    tick.value++;
  }

  // ---------- ویرایش ----------
  void add(String type, [Variant? variant]) {
    final node = WidgetCatalog.create(type);
    if (variant != null) {
      node.props
        ..['variant'] = variant.id
        ..addAll(variant.props);
    }
    _insert(node);
  }

  void addTemplate(Template t) => _insert(t.instantiate());

  void _insert(WidgetNode node) {
    _insertNode(_p, selected, node);
    selectedId.value = node.id;
    _changed();
  }

  void removeSelected() {
    final sel = selected;
    if (sel == null || !_removeNode(_p, sel)) return;
    selectedId.value = null;
    if (panelKind == 'props') closePanel();
    _changed();
  }

  void restoreSection(String type) {
    selectedId.value = _restoreSection(_p, type).id;
    _changed();
  }

  void move(int delta) {
    final sel = selected;
    if (sel != null && _moveNode(_p, sel, delta)) _changed();
  }

  void applyVariant(WidgetNode n, Variant v) {
    _applyVariant(n, v);
    _changed();
  }

  void setProp(WidgetNode n, String key, dynamic value) {
    n.props[key] = value;
    _changed();
  }

  void _changed() {
    tick.value++;
    _savePage(_p); // ذخیره‌ی خودکار
  }
}
