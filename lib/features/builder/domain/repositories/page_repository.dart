import '../entities/page_model.dart';

/// قرارداد ذخیره‌ی صفحه‌ها (پیاده‌سازی در لایه‌ی data)
abstract class PageRepository {
  Future<List<PageModel>> getAll();
  Future<void> save(PageModel page);
  Future<void> delete(String id);
}
