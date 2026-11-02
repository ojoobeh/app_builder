import 'dart:convert';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  /// منبع داده‌ی محلی (Hive)
  final HiveLocalDataSource _dataSource;
  ProjectRepositoryImpl(this._dataSource);

  @override
  Future<List<Project>> getAll() async {
    final projects = _dataSource
        .allProjects()
        .map((jsonText) => projectFromJson(Map<String, dynamic>.from(jsonDecode(jsonText) as Map)))
        .toList();
    projects.sort((a, b) => a.id.compareTo(b.id)); // ترتیب ساخت
    return projects;
  }

  @override
  Future<void> save(Project project) => _dataSource.putProject(project.id, jsonEncode(projectToJson(project)));

  @override
  Future<void> delete(String id) => _dataSource.deleteProject(id);
}
