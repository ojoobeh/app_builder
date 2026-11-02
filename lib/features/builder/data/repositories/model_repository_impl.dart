import 'dart:convert';
import '../../domain/entities/model_def.dart';
import '../../domain/repositories/model_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class ModelRepositoryImpl implements ModelRepository {
  /// منبع داده‌ی محلی (Hive)
  final HiveLocalDataSource _dataSource;
  ModelRepositoryImpl(this._dataSource);

  List<ModelDef> _all() => _dataSource
      .allModels()
      .map((jsonText) => modelFromJson(Map<String, dynamic>.from(jsonDecode(jsonText) as Map)))
      .toList();

  @override
  Future<List<ModelDef>> getByProject(String projectId) async {
    final models = _all().where((model) => model.projectId == projectId).toList();
    models.sort((a, b) => a.id.compareTo(b.id)); // شناسه زمان ساخت است؛ ترتیب ساخت
    return models;
  }

  @override
  Future<void> save(ModelDef model) => _dataSource.putModel(model.id, jsonEncode(modelToJson(model)));

  @override
  Future<void> delete(String id) => _dataSource.deleteModel(id);

  @override
  Future<void> deleteByProject(String projectId) async {
    for (final model in _all().where((model) => model.projectId == projectId)) {
      await _dataSource.deleteModel(model.id);
    }
  }
}
