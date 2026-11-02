import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/entities/page_request.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../../domain/catalog/widget_def.dart';
import '../../domain/usecases/edit_page_usecases.dart';
import '../../domain/usecases/page_usecases.dart';
import '../renderer/preview_state.dart';

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
  /// صفحه‌ای که الان در ادیتور باز است
  final page = Rxn<PageModel>();

  /// شناسه‌ی ویجت انتخاب‌شده (null = چیزی انتخاب نیست)
  final selectedId = RxnString();

  final tick = 0.obs; // با هر تغییر زیاد می‌شود تا صفحه دوباره ساخته شود

  /// حالت پیش‌نمایش (بدون قاب انتخاب و نوار ابزار)
  final preview = false.obs;

  // پنل پایین ادیتور (به‌جای bottom sheet تا صفحه همیشه دیده شود)
  final panel = Rxn<Widget>(); // محتوای پنل (null = بسته)
  final panelTitle = ''.obs; // عنوان بالای پنل
  String panelKind = ''; // نوع پنل: 'add' / 'variant' / 'props'

  /// صفحه‌ی باز (فقط وقتی ادیتور باز است صدا زده شود)
  PageModel get _currentPage => page.value!;

  // ---------- پرس‌وجو ----------
  /// گره‌ای با این شناسه
  WidgetNode? find(String id) => PageTree.find(_currentPage, id);

  /// والد گره‌ای با این شناسه
  WidgetNode? parentOf(String id) => PageTree.parentOf(_currentPage, id);

  /// ویجت انتخاب‌شده (یا null)
  WidgetNode? get selected => selectedId.value == null ? null : find(selectedId.value!);

  /// آیا انتخاب‌شده یکی از بخش‌های اصلی است؟ (اپ‌بار، بدنه، فوتر)
  bool get selectedIsRoot => selected != null && parentOf(selected!.id) == null;

  // ---------- صفحه و پنل ----------
  /// یک صفحه را در ادیتور باز می‌کند
  void open(PageModel pageToOpen) {
    page.value = pageToOpen;
    selectedId.value = null;
    closePanel();
    PreviewState.reset();
    preview.value = false;
    tick.value++;
  }

  /// پنل پایین را با این محتوا باز می‌کند
  void showPanel(String title, String kind, Widget content) {
    panelTitle.value = title;
    panelKind = kind;
    panel.value = content;
  }

  /// پنل پایین را می‌بندد
  void closePanel() {
    panelKind = '';
    panel.value = null;
  }

  /// ویجتی را انتخاب می‌کند (null = برداشتن انتخاب)
  void select(String? id) {
    selectedId.value = id;
    if (panelKind == 'props') closePanel(); // پنل ویژگی‌ها مال ویجت قبلی بود
    tick.value++;
  }

  // ---------- ویرایش ----------
  /// ویجت جدیدی از این نوع (و نمونه‌ی آماده‌ی اختیاری) اضافه می‌کند
  void add(String type, [Variant? variant]) {
    final node = WidgetCatalog.create(type);
    if (variant != null) {
      node.props
        ..['variant'] = variant.id
        ..addAll(variant.props);
    }
    _insert(node);
  }

  /// یک کپی مستقل از قالب کاربر را به صفحه اضافه می‌کند
  void addTemplate(Template template) => _insert(template.instantiate());

  /// یک گره‌ی آماده (مثلاً لیست ساخته‌شده از پاسخ سرور) را به صفحه اضافه می‌کند
  void addNode(WidgetNode node) => _insert(node);

  /// گره را در جای مناسب درخت می‌گذارد و انتخابش می‌کند
  void _insert(WidgetNode node) {
    _insertNode(_currentPage, selected, node);
    selectedId.value = node.id;
    _changed();
  }

  /// ویجت انتخاب‌شده را حذف می‌کند (اپ‌بار/فوتر پنهان می‌شوند)
  void removeSelected() {
    final selectedNode = selected;
    if (selectedNode == null || !_removeNode(_currentPage, selectedNode)) return;
    selectedId.value = null;
    if (panelKind == 'props') closePanel();
    _changed();
  }

  /// اپ‌بار یا فوتر پنهان‌شده را برمی‌گرداند
  void restoreSection(String type) {
    selectedId.value = _restoreSection(_currentPage, type).id;
    _changed();
  }

  /// ویجت انتخاب‌شده را بالا (-1) یا پایین (+1) می‌برد
  void move(int delta) {
    final selectedNode = selected;
    if (selectedNode != null && _moveNode(_currentPage, selectedNode, delta)) _changed();
  }

  /// نمونه‌ی آماده را روی یک ویجت اعمال می‌کند
  void applyVariant(WidgetNode node, Variant variant) {
    _applyVariant(node, variant);
    _changed();
  }

  /// یک ویژگی ویجت را تغییر می‌دهد
  void setProp(WidgetNode node, String key, dynamic value) {
    node.props[key] = value;
    _changed();
  }

  /// تنظیمات «درخواست صفحه» (آدرس سرور و ...) را تغییر می‌دهد
  void updateRequest(void Function(PageRequest request) change) {
    change(_currentPage.request);
    _changed();
  }

  /// جهت صفحه را بین چپ‌چین (ltr) و راست‌چین (rtl) عوض می‌کند
  void toggleDirection() {
    _currentPage.direction = _currentPage.direction == 'rtl' ? 'ltr' : 'rtl';
    _changed();
  }

  /// بعد از هر تغییر: صفحه را بازسازی می‌کند و خودکار ذخیره می‌کند
  void _changed() {
    tick.value++;
    _savePage(_currentPage); // ذخیره‌ی خودکار
  }
}
