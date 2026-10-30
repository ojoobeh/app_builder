import 'dart:convert';
import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final HiveLocalDataSource _ds;
  TemplateRepositoryImpl(this._ds);

  @override
  Future<List<Template>> getAll() async => _ds
      .allTemplates()
      .map((s) => templateFromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
      .toList();

  @override
  Future<void> save(Template t) => _ds.putTemplate(t.id, jsonEncode(templateToJson(t)));

  @override
  Future<void> delete(String id) => _ds.deleteTemplate(id);

  @override
  Future<String> exportJson() async => jsonEncode((await getAll()).map(templateToJson).toList());

  @override
  Future<int> importJson(String json) async {
    final list = jsonDecode(json) as List; // اگر JSON نامعتبر باشد استثنا می‌دهد
    for (final e in list) {
      await save(templateFromJson(Map<String, dynamic>.from(e as Map)));
    }
    return list.length;
  }
}
