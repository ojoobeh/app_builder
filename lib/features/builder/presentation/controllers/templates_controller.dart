import 'package:get/get.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/usecases/template_usecases.dart';

/// وضعیت کتابخانه‌ی قالب‌های کاربر
class TemplatesController extends GetxController {
  // usecaseها (از injection.dart تزریق می‌شوند)
  final GetTemplates _getTemplates;
  final SaveTemplate _saveTemplate;
  final DeleteTemplate _deleteTemplate;
  final ExportTemplates _exportTemplates;
  final ImportTemplates _importTemplates;
  TemplatesController(
      this._getTemplates, this._saveTemplate, this._deleteTemplate, this._exportTemplates, this._importTemplates);

  /// فهرست قالب‌های کاربر (واکنشی)
  final items = <Template>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// فهرست را از ذخیره‌سازی دوباره می‌خواند
  Future<void> load() async => items.assignAll(await _getTemplates());

  /// یک ویجت را با این نام به‌عنوان قالب ذخیره می‌کند
  Future<void> saveFromNode(String name, WidgetNode node) async {
    await _saveTemplate(name, node);
    await load();
  }

  /// یک قالب را حذف می‌کند
  Future<void> remove(String id) async {
    await _deleteTemplate(id);
    await load();
  }

  /// همه‌ی قالب‌ها به‌صورت متن JSON
  Future<String> exportJson() => _exportTemplates();

  /// می‌تواند استثنا بدهد (JSON نامعتبر)
  Future<int> importJson(String json) async {
    final importedCount = await _importTemplates(json);
    await load();
    return importedCount;
  }
}
