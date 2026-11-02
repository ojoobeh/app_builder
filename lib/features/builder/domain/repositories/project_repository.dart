import '../entities/project.dart';

/// قرارداد ذخیره‌ی پروژه‌ها (پیاده‌سازی در لایه‌ی data)
abstract class ProjectRepository {
  Future<List<Project>> getAll();
  Future<void> save(Project project);
  Future<void> delete(String id);
}
