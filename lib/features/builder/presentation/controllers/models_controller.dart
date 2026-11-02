import 'package:get/get.dart';
import '../../domain/entities/model_def.dart';
import '../../domain/entities/project.dart';
import '../../domain/models/model_type_parser.dart';
import '../../domain/usecases/model_usecases.dart';

/// وضعیت بخش «مدل‌های داده» برای پروژه‌ی باز
class ModelsController extends GetxController {
  // usecaseها (از injection.dart تزریق می‌شوند)
  final GetProjectModels _getModels;
  final SaveModel _saveModel;
  final DeleteModel _deleteModel;
  final ParseFieldSpec _parseSpec;
  ModelsController(this._getModels, this._saveModel, this._deleteModel, this._parseSpec);

  /// پروژه‌ی باز
  final project = Rxn<Project>();

  /// مدل‌های پروژه‌ی باز (واکنشی)
  final models = <ModelDef>[].obs;

  /// یک پروژه را باز می‌کند و مدل‌هایش را می‌خواند
  Future<void> open(Project selectedProject) async {
    if (project.value?.id != selectedProject.id) models.clear(); // همان پروژه: فهرست قبلی تا بارگذاری می‌ماند
    project.value = selectedProject;
    await load();
  }

  Future<void> load() async {
    final current = project.value;
    if (current == null) return;
    models.assignAll(await _getModels(current.id));
  }

  /// مدل خالی و ذخیره‌نشده برای ساخت مدل جدید
  ModelDef newDraft() => ModelDef(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        projectId: project.value!.id,
        name: '',
      );

  /// مدل را ذخیره می‌کند؛ فهرست خطاها را برمی‌گرداند (خالی = ذخیره شد)
  Future<List<String>> save(ModelDef model) async {
    final errors = await _saveModel(model);
    if (errors.isEmpty) await load();
    return errors;
  }

  /// مدل را حذف می‌کند؛ اگر مدل دیگری از آن استفاده کند حذف نمی‌شود
  Future<void> delete(ModelDef model) async {
    try {
      await _deleteModel(model);
      await load();
    } on ModelInUseException catch (error) {
      Get.snackbar('قابل حذف نیست', 'این مدل در مدل‌های «${error.usedBy.join('، ')}» استفاده شده است.');
    }
  }

  /// نام مدل از روی شناسه (null = مدل حذف شده)
  String? nameOf(String id) {
    for (final model in models) {
      if (model.id == id) return model.name;
    }
    return null;
  }

  /// نوع را برای نمایش می‌نویسد (مثلاً List<Product>?)
  String typeLabel(FieldType type, {bool nullable = false}) => describeFieldType(type, nameOf, nullable: nullable);

  /// متن «key=...,type=...» را به فیلد تبدیل می‌کند
  Future<SpecParseResult> parseSpec(String text, {Map<String, String> extraNames = const {}}) =>
      _parseSpec(project.value!.id, text, extraNames: extraNames);
}
