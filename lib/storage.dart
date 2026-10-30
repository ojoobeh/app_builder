import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'node.dart';

/// ذخیره‌سازی با Hive به صورت JSON (بدون نیاز به TypeAdapter؛ ارتقا آسان)
class Storage {
  static late Box<String> _box;
  static late Box<String> _tbox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('pages');
    _tbox = await Hive.openBox<String>('templates');
  }

  static List<PageModel> all() => _box.values
      .map((s) => PageModel.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
      .toList();

  static Future<void> save(PageModel p) => _box.put(p.id, jsonEncode(p.toJson()));
  static Future<void> delete(String id) => _box.delete(id);

  static List<Template> allTemplates() => _tbox.values
      .map((s) => Template.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
      .toList();
  static Future<void> saveTemplate(Template t) => _tbox.put(t.id, jsonEncode(t.toJson()));
  static Future<void> deleteTemplate(String id) => _tbox.delete(id);
}
