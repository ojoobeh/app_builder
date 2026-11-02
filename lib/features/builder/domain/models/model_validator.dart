import '../entities/model_def.dart';
import 'dart_naming.dart';

/// مدل را قبل از ذخیره بررسی می‌کند و فهرست خطاها را برمی‌گرداند (خالی = معتبر).
/// [projectModels] همه‌ی مدل‌های ذخیره‌شده‌ی همان پروژه است (ممکن است خود [model] هم داخلش باشد).
List<String> validateModel(ModelDef model, List<ModelDef> projectModels) {
  final errors = <String>[];
  final others = projectModels.where((other) => other.id != model.id).toList();
  final name = model.name.trim();

  // ---------- نام مدل ----------
  if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(name)) {
    errors.add('نام مدل باید انگلیسی و با حرف بزرگ شروع شود (مثلاً User یا ProductItem).');
  } else if (kReservedModelNames.contains(name)) {
    errors.add('نام «$name» با یک کلاس آماده‌ی دارت تداخل دارد؛ نام دیگری بگذار.');
  } else if (others.any((other) => other.name.toLowerCase() == name.toLowerCase())) {
    errors.add('مدلی با نام «$name» در این پروژه وجود دارد.');
  }

  // ---------- فیلدها ----------
  final knownIds = {...others.map((other) => other.id), model.id};
  final usedDartNames = <String, String>{}; // نام دارت ← key
  for (final field in model.fields) {
    final key = field.key.trim();
    if (key.isEmpty) {
      errors.add('یکی از فیلدها key ندارد.');
      continue;
    }
    final dartName = fieldDartName(key);
    if (dartName == null) {
      errors.add('key «$key» باید حداقل یک حرف یا عدد انگلیسی داشته باشد.');
    } else if (usedDartNames.containsKey(dartName)) {
      errors.add('key «$key» با «${usedDartNames[dartName]}» نام یکسانی در دارت می‌سازد ($dartName).');
    } else {
      usedDartNames[dartName] = key;
    }
    for (final id in field.type.referencedModelIds()) {
      if (!knownIds.contains(id)) errors.add('نوع فیلد «$key» به مدلی اشاره می‌کند که دیگر وجود ندارد.');
    }
  }

  // ---------- ارجاع حلقه‌ای غیرمجاز ----------
  // اگر A یک B غیر-null داشته باشد و B یک A غیر-null، ساختن هیچ‌کدام ممکن نیست.
  // (حلقه از راه فیلد nullable یا List مشکلی ندارد.)
  final cyclePath = _findRequiredCycle(model, [...others, model]);
  if (cyclePath != null) {
    errors.add('ارجاع حلقه‌ای غیرمجاز: ${cyclePath.join(' ← ')}. '
        'یکی از فیلدهای این مسیر را «اختیاری (null)» یا List کن.');
  }
  return errors;
}

/// مسیر حلقه‌ای که از [start] شروع و به آن برمی‌گردد و فقط از فیلدهای غیر-null مستقیم می‌گذرد
List<String>? _findRequiredCycle(ModelDef start, List<ModelDef> all) {
  final byId = {for (final model in all) model.id: model};
  List<String>? search(ModelDef current, List<String> path, Set<String> visited) {
    for (final field in current.fields) {
      if (field.nullable || field.type.kind != FieldKind.model) continue;
      final next = byId[field.type.modelId];
      if (next == null) continue;
      if (next.id == start.id) return [...path, next.name];
      if (!visited.add(next.id)) continue;
      final found = search(next, [...path, next.name], visited);
      if (found != null) return found;
    }
    return null;
  }

  return search(start, [start.name], {start.id});
}
