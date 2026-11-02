import 'dart:convert';
import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  /// منبع داده‌ی محلی (Hive)
  final HiveLocalDataSource _dataSource;
  TemplateRepositoryImpl(this._dataSource);

  @override
  Future<List<Template>> getAll() async => _dataSource
      .allTemplates()
      .map((jsonText) => templateFromJson(Map<String, dynamic>.from(jsonDecode(jsonText) as Map)))
      .toList();

  @override
  Future<void> save(Template template) =>
      _dataSource.putTemplate(template.id, jsonEncode(templateToJson(template)));

  @override
  Future<void> delete(String id) => _dataSource.deleteTemplate(id);

  @override
  Future<String> exportJson() async => jsonEncode((await getAll()).map(templateToJson).toList());

  @override
  Future<int> importJson(String json) async {
    final entries = jsonDecode(json) as List; // اگر JSON نامعتبر باشد استثنا می‌دهد
    for (final entry in entries) {
      await save(templateFromJson(Map<String, dynamic>.from(entry as Map)));
    }
    return entries.length;
  }
}
