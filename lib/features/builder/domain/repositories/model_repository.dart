import '../entities/model_def.dart';

/// قرارداد ذخیره‌ی مدل‌های داده (پیاده‌سازی در لایه‌ی data).
/// هر پروژه مدل‌های مخصوص خودش را دارد.
abstract class ModelRepository {
  /// مدل‌های یک پروژه به ترتیب ساخته‌شدن
  Future<List<ModelDef>> getByProject(String projectId);
  Future<void> save(ModelDef model);
  Future<void> delete(String id);

  /// همه‌ی مدل‌های یک پروژه را حذف می‌کند
  Future<void> deleteByProject(String projectId);
}
