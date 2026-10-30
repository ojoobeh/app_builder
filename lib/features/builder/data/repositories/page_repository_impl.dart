import 'dart:convert';
import '../../domain/entities/page_model.dart';
import '../../domain/repositories/page_repository.dart';
import '../datasources/hive_local_datasource.dart';
import '../mappers/json_mappers.dart';

class PageRepositoryImpl implements PageRepository {
  final HiveLocalDataSource _ds;
  PageRepositoryImpl(this._ds);

  @override
  Future<List<PageModel>> getAll() async => _ds
      .allPages()
      .map((s) => pageFromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
      .toList();

  @override
  Future<void> save(PageModel page) => _ds.putPage(page.id, jsonEncode(pageToJson(page)));

  @override
  Future<void> delete(String id) => _ds.deletePage(id);
}
