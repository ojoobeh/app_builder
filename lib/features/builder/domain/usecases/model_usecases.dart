import '../entities/model_def.dart';
import '../models/model_type_parser.dart';
import '../models/model_validator.dart';
import '../repositories/model_repository.dart';

/// مدل‌های یک پروژه (هر جای همان پروژه که مدل لازم بود، از همین استفاده کن)
class GetProjectModels {
  final ModelRepository _repo;
  const GetProjectModels(this._repo);
  Future<List<ModelDef>> call(String projectId) => _repo.getByProject(projectId);
}

/// ذخیره‌ی مدل (جدید یا ویرایش‌شده) بعد از اعتبارسنجی.
/// خروجی: فهرست خطاها؛ اگر خالی بود ذخیره شده است.
class SaveModel {
  final ModelRepository _repo;
  const SaveModel(this._repo);

  Future<List<String>> call(ModelDef model) async {
    model.name = model.name.trim();
    for (final field in model.fields) {
      field.key = field.key.trim();
    }
    final errors = validateModel(model, await _repo.getByProject(model.projectId));
    if (errors.isNotEmpty) return errors;
    await _repo.save(model);
    return const [];
  }
}

/// وقتی مدلی هنوز در مدل‌های دیگر استفاده شده و نمی‌شود حذفش کرد
class ModelInUseException implements Exception {
  /// نام مدل‌هایی که از آن استفاده می‌کنند
  final List<String> usedBy;
  const ModelInUseException(this.usedBy);
}

/// حذف مدل؛ اگر مدل دیگری به آن اشاره کند [ModelInUseException] می‌دهد (تا ارجاعی بی‌صاحب نماند)
class DeleteModel {
  final ModelRepository _repo;
  const DeleteModel(this._repo);

  Future<void> call(ModelDef model) async {
    final all = await _repo.getByProject(model.projectId);
    final users = all
        .where((other) =>
            other.id != model.id && other.fields.any((field) => field.type.referencedModelIds().contains(model.id)))
        .map((other) => other.name)
        .toList();
    if (users.isNotEmpty) throw ModelInUseException(users);
    await _repo.delete(model.id);
  }
}

/// تبدیل متن «key=name,type=String» به فیلدها (نام مدل‌ها از روی مدل‌های همان پروژه پیدا می‌شود).
/// [extraNames]: مدل‌هایی که هنوز ذخیره نشده‌اند (مثلاً خود مدلِ در حال ساخت برای ارجاع به خودش).
class ParseFieldSpec {
  final ModelRepository _repo;
  const ParseFieldSpec(this._repo);

  Future<SpecParseResult> call(String projectId, String text, {Map<String, String> extraNames = const {}}) async {
    final models = await _repo.getByProject(projectId);
    final idByName = {for (final model in models) model.name: model.id, ...extraNames};
    return parseFieldSpec(text, idByName);
  }
}
