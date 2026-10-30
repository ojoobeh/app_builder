import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/usecases/page_usecases.dart';

/// وضعیت صفحه‌ی اول: فهرست صفحه‌های کاربر
class HomeController extends GetxController {
  final GetPages _getPages;
  final CreatePage _createPage;
  final DeletePage _deletePage;
  HomeController(this._getPages, this._createPage, this._deletePage);

  final pages = <PageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async => pages.assignAll(await _getPages());

  Future<PageModel> create(String name) async {
    final page = await _createPage(name);
    await load();
    return page;
  }

  Future<void> delete(String id) async {
    await _deletePage(id);
    await load();
  }
}
