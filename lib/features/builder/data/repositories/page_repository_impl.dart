import 'dart:convert';
import '../../domain/entities/page_model.dart';
import '../../domain/repositories/page_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class PageRepositoryImpl implements PageRepository {
  /// منبع داده‌ی محلی (Hive)
  final HiveLocalDataSource _dataSource;
  PageRepositoryImpl(this._dataSource);

  /// همه‌ی صفحه‌های ذخیره‌شده (از همه‌ی پروژه‌ها)
  List<PageModel> _all() => _dataSource
      .allPages()
      .map((jsonText) => pageFromJson(Map<String, dynamic>.from(jsonDecode(jsonText) as Map)))
      .toList();

  @override
  Future<List<PageModel>> getByProject(String projectId) async {
    final pages = _all().where((page) => page.projectId == projectId).toList();
    pages.sort((a, b) => a.id.compareTo(b.id)); // شناسه زمان ساخت است؛ ترتیب ساخت
    return pages;
  }

  @override
  Future<void> save(PageModel page) => _dataSource.putPage(page.id, jsonEncode(pageToJson(page)));

  @override
  Future<void> delete(String id) => _dataSource.deletePage(id);

  @override
  Future<void> deleteByProject(String projectId) async {
    for (final page in _all().where((page) => page.projectId == projectId)) {
      await _dataSource.deletePage(page.id);
    }
  }
}
