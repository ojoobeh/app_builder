import '../entities/template.dart';
import '../entities/widget_node.dart';
import '../repositories/template_repository.dart';

class GetTemplates {
  final TemplateRepository _repo;
  const GetTemplates(this._repo);
  Future<List<Template>> call() => _repo.getAll();
}

/// ذخیره‌ی یک ویجت (با فرزندانش) به‌عنوان قالب؛ از گره یک کپی مستقل می‌گیرد
class SaveTemplate {
  final TemplateRepository _repo;
  const SaveTemplate(this._repo);

  Future<void> call(String name, WidgetNode node) => _repo.save(
      Template(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, node: node.clone()));
}

class DeleteTemplate {
  final TemplateRepository _repo;
  const DeleteTemplate(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}

class ExportTemplates {
  final TemplateRepository _repo;
  const ExportTemplates(this._repo);
  Future<String> call() => _repo.exportJson();
}

class ImportTemplates {
  final TemplateRepository _repo;
  const ImportTemplates(this._repo);
  Future<int> call(String json) => _repo.importJson(json);
}
