import 'package:hive_flutter/hive_flutter.dart';

/// دسترسی خام به Hive. فقط رشته‌ی JSON ذخیره می‌کند و از مدل‌ها چیزی نمی‌داند.
class HiveLocalDataSource {
  late final Box<String> _pages;
  late final Box<String> _templates;

  Future<void> init() async {
    await Hive.initFlutter();
    _pages = await Hive.openBox<String>('pages');
    _templates = await Hive.openBox<String>('templates');
  }

  List<String> allPages() => _pages.values.toList();
  Future<void> putPage(String id, String json) => _pages.put(id, json);
  Future<void> deletePage(String id) => _pages.delete(id);

  List<String> allTemplates() => _templates.values.toList();
  Future<void> putTemplate(String id, String json) => _templates.put(id, json);
  Future<void> deleteTemplate(String id) => _templates.delete(id);
}
