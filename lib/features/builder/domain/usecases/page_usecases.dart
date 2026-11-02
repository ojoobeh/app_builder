import '../entities/page_model.dart';
import '../catalog/widget_catalog.dart';
import '../repositories/page_repository.dart';

/// صفحه‌های یک پروژه
class GetProjectPages {
  final PageRepository _repo;
  const GetProjectPages(this._repo);
  Future<List<PageModel>> call(String projectId) => _repo.getByProject(projectId);
}

/// ساخت صفحه‌ی جدید در یک پروژه با اپ‌بار، بدنه (Column) و فوتر پیش‌فرض
class CreatePage {
  final PageRepository _repo;
  const CreatePage(this._repo);

  Future<PageModel> call(String projectId, String name) async {
    final page = PageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      projectId: projectId,
      appBar: WidgetCatalog.create('appBar')..props['title'] = name,
      body: WidgetCatalog.create('column'),
      footer: WidgetCatalog.create('footer'),
    );
    await _repo.save(page);
    return page;
  }
}

class SavePage {
  final PageRepository _repo;
  const SavePage(this._repo);
  Future<void> call(PageModel page) => _repo.save(page);
}

class DeletePage {
  final PageRepository _repo;
  const DeletePage(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}
