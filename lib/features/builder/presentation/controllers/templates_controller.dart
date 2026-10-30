import 'package:get/get.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/usecases/template_usecases.dart';

/// وضعیت کتابخانه‌ی قالب‌های کاربر
class TemplatesController extends GetxController {
  final GetTemplates _get;
  final SaveTemplate _save;
  final DeleteTemplate _delete;
  final ExportTemplates _export;
  final ImportTemplates _import;
  TemplatesController(this._get, this._save, this._delete, this._export, this._import);

  final items = <Template>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async => items.assignAll(await _get());

  Future<void> saveFromNode(String name, WidgetNode node) async {
    await _save(name, node);
    await load();
  }

  Future<void> remove(String id) async {
    await _delete(id);
    await load();
  }

  Future<String> exportJson() => _export();

  /// می‌تواند استثنا بدهد (JSON نامعتبر)
  Future<int> importJson(String json) async {
    final n = await _import(json);
    await load();
    return n;
  }
}
