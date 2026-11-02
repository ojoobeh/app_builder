import '../entities/page_model.dart';

/// قرارداد ذخیره‌ی صفحه‌ها (پیاده‌سازی در لایه‌ی data)
abstract class PageRepository {
  /// صفحه‌های یک پروژه به ترتیب ساخته‌شدن
  Future<List<PageModel>> getByProject(String projectId);
  Future<void> save(PageModel page);
  Future<void> delete(String id);

  /// همه‌ی صفحه‌های یک پروژه را حذف می‌کند
  Future<void> deleteByProject(String projectId);
}
