import 'package:hive_flutter/hive_flutter.dart';

/// دسترسی خام به Hive. فقط رشته‌ی JSON ذخیره می‌کند و از مدل‌ها چیزی نمی‌داند.
class HiveLocalDataSource {
  late final Box<String> _projects;
  late final Box<String> _pages;
  late final Box<String> _templates;
  late final Box<String> _models;

  Future<void> init() async {
    await Hive.initFlutter();
    _projects = await Hive.openBox<String>('projects');
    _pages = await Hive.openBox<String>('pages');
    _templates = await Hive.openBox<String>('templates');
    _models = await Hive.openBox<String>('models');
  }

  List<String> allProjects() => _projects.values.toList();
  Future<void> putProject(String id, String json) => _projects.put(id, json);
  Future<void> deleteProject(String id) => _projects.delete(id);

  List<String> allPages() => _pages.values.toList();
  Future<void> putPage(String id, String json) => _pages.put(id, json);
  Future<void> deletePage(String id) => _pages.delete(id);

  List<String> allTemplates() => _templates.values.toList();
  Future<void> putTemplate(String id, String json) => _templates.put(id, json);
  Future<void> deleteTemplate(String id) => _templates.delete(id);

  List<String> allModels() => _models.values.toList();
  Future<void> putModel(String id, String json) => _models.put(id, json);
  Future<void> deleteModel(String id) => _models.delete(id);
}
