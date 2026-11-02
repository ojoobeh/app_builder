import 'dart:convert';
import '../../domain/entities/project.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

/// مهاجرت از نسخه‌ی قبلی: صفحه‌هایی که پروژه ندارند داخل یک پروژه‌ی «پروژه‌ی قبلی» گذاشته می‌شوند.
/// اگر چنین صفحه‌ای نباشد، هیچ کاری نمی‌کند.
class LegacyPagesMigration {
  final HiveLocalDataSource _dataSource;
  LegacyPagesMigration(this._dataSource);

  Future<void> run() async {
    final orphanPages = _dataSource
        .allPages()
        .map((jsonText) => pageFromJson(Map<String, dynamic>.from(jsonDecode(jsonText) as Map)))
        .where((page) => page.projectId.isEmpty)
        .toList();
    if (orphanPages.isEmpty) return;

    final project = Project(id: DateTime.now().microsecondsSinceEpoch.toString(), name: 'پروژه‌ی قبلی');
    await _dataSource.putProject(project.id, jsonEncode(projectToJson(project)));
    for (final page in orphanPages) {
      page.projectId = project.id;
      await _dataSource.putPage(page.id, jsonEncode(pageToJson(page)));
    }
  }
}
