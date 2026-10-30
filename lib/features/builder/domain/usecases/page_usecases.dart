import '../entities/page_model.dart';
import '../catalog/widget_catalog.dart';
import '../repositories/page_repository.dart';

class GetPages {
  final PageRepository _repo;
  const GetPages(this._repo);
  Future<List<PageModel>> call() => _repo.getAll();
}

/// ساخت صفحه‌ی جدید با اپ‌بار، بدنه (Column) و فوتر پیش‌فرض
class CreatePage {
  final PageRepository _repo;
  const CreatePage(this._repo);

  Future<PageModel> call(String name) async {
    final page = PageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
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
