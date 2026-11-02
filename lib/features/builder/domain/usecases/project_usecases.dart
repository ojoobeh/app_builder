import '../entities/project.dart';
import '../codegen/project_code_generator.dart';
import '../repositories/model_repository.dart';
import '../repositories/page_repository.dart';
import '../repositories/project_repository.dart';
import '../services/project_archiver.dart';

class GetProjects {
  final ProjectRepository _repo;
  const GetProjects(this._repo);
  Future<List<Project>> call() => _repo.getAll();
}

class CreateProject {
  final ProjectRepository _repo;
  const CreateProject(this._repo);

  Future<Project> call(String name) async {
    final project = Project(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    await _repo.save(project);
    return project;
  }
}

/// حذف پروژه همراه با همه‌ی صفحه‌ها و مدل‌هایش
class DeleteProject {
  final ProjectRepository _projects;
  final PageRepository _pages;
  final ModelRepository _models;
  const DeleteProject(this._projects, this._pages, this._models);

  Future<void> call(String id) async {
    await _pages.deleteByProject(id);
    await _models.deleteByProject(id);
    await _projects.delete(id);
  }
}

/// نتیجه‌ی خروجی گرفتن: نام فایل zip و محتوای آن
class ProjectZip {
  final String fileName;
  final List<int> bytes;
  const ProjectZip({required this.fileName, required this.bytes});
}

/// خروجی کامل پروژه به‌صورت zip (کد دارت با معماری Clean Architecture)
class ExportProjectZip {
  final PageRepository _pages;
  final ProjectCodeGenerator _generator;
  final ProjectArchiver _archiver;
  final ModelRepository _models;
  const ExportProjectZip(this._pages, this._generator, this._archiver, this._models);

  Future<ProjectZip> call(Project project) async {
    final pages = await _pages.getByProject(project.id);
    final models = await _models.getByProject(project.id);
    final files = _generator.generate(project, pages, models: models);
    final folder = _generator.folderName(project);
    final bytes = await _archiver.zip(files, rootFolder: folder);
    return ProjectZip(fileName: '$folder.zip', bytes: bytes);
  }
}
