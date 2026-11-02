import 'package:get/get.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/project_usecases.dart';

/// وضعیت صفحه‌ی اول: فهرست پروژه‌های کاربر
class ProjectsController extends GetxController {
  // usecaseها (از injection.dart تزریق می‌شوند)
  final GetProjects _getProjects;
  final CreateProject _createProject;
  final DeleteProject _deleteProject;
  ProjectsController(this._getProjects, this._createProject, this._deleteProject);

  /// فهرست پروژه‌ها (واکنشی)
  final items = <Project>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// فهرست را از ذخیره‌سازی دوباره می‌خواند
  Future<void> load() async => items.assignAll(await _getProjects());

  /// پروژه‌ی جدید می‌سازد و برمی‌گرداند
  Future<Project> create(String name) async {
    final project = await _createProject(name);
    await load();
    return project;
  }

  /// پروژه را با همه‌ی صفحه‌هایش حذف می‌کند
  Future<void> delete(String id) async {
    await _deleteProject(id);
    await load();
  }
}
