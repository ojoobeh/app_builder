import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/page_usecases.dart';
import '../../domain/usecases/project_usecases.dart';
import '../services/file_sharer.dart';

/// وضعیت صفحه‌ی داخل یک پروژه: صفحه‌های همان پروژه + خروجی zip
class ProjectDetailController extends GetxController {
  // usecaseها (از injection.dart تزریق می‌شوند)
  final GetProjectPages _getPages;
  final CreatePage _createPage;
  final DeletePage _deletePage;
  final ExportProjectZip _exportZip;
  ProjectDetailController(this._getPages, this._createPage, this._deletePage, this._exportZip);

  /// پروژه‌ی باز
  final project = Rxn<Project>();

  /// صفحه‌های پروژه‌ی باز (واکنشی)
  final pages = <PageModel>[].obs;

  /// در حال ساخت خروجی zip؟ (برای نمایش چرخان)
  final isExporting = false.obs;

  /// یک پروژه را باز می‌کند و صفحه‌هایش را می‌خواند
  Future<void> open(Project selectedProject) async {
    project.value = selectedProject;
    pages.clear();
    await load();
  }

  /// صفحه‌های پروژه را دوباره از ذخیره‌سازی می‌خواند
  Future<void> load() async {
    final current = project.value;
    if (current == null) return;
    pages.assignAll(await _getPages(current.id));
  }

  /// صفحه‌ی جدید در این پروژه می‌سازد و برمی‌گرداند
  Future<PageModel> createPage(String name) async {
    final page = await _createPage(project.value!.id, name);
    await load();
    return page;
  }

  /// یک صفحه را حذف می‌کند
  Future<void> deletePage(String id) async {
    await _deletePage(id);
    await load();
  }

  /// کل پروژه را به‌صورت zip (کد دارت با معماری Clean Architecture) می‌سازد و برای اشتراک باز می‌کند
  Future<void> exportZip() async {
    final current = project.value;
    if (current == null || isExporting.value) return;
    isExporting.value = true;
    try {
      final zip = await _exportZip(current);
      await shareBytes(zip.fileName, zip.bytes);
    } catch (error) {
      Get.snackbar('خطا', 'ساخت خروجی ناموفق بود: $error');
    } finally {
      isExporting.value = false;
    }
  }
}
