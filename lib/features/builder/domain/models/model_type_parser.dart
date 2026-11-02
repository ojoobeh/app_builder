import '../entities/model_def.dart';

/// نتیجه‌ی خواندن یک نوع از متن: یا type دارد یا error
class TypeParseResult {
  final FieldType? type;
  final bool nullable;
  final String? error;
  const TypeParseResult.ok(FieldType this.type, this.nullable) : error = null;
  const TypeParseResult.fail(String this.error)
      : type = null,
        nullable = false;
}

/// اسم‌های جایگزین رایج برای نوع‌های پایه (بدون حساسیت به حروف بزرگ و کوچک)
const Map<String, String> _kTypeAliases = {
  'string': 'String',
  'str': 'String',
  'int': 'int',
  'integer': 'int',
  'double': 'double',
  'float': 'double',
  'bool': 'bool',
  'boolean': 'bool',
  'num': 'num',
  'number': 'num',
  'datetime': 'DateTime',
  'date': 'DateTime',
  'dynamic': 'dynamic',
  'object': 'dynamic',
  'map': 'Map',
  'map<string,dynamic>': 'Map',
};

/// متن نوع را به FieldType تبدیل می‌کند.
/// مثال‌ها: String ، int? ، List<Product> ، Product? ، List<List<int>>
/// [idByName]: نام مدل‌های پروژه ← شناسه‌ی آن‌ها
TypeParseResult parseFieldType(String text, Map<String, String> idByName) {
  var source = text.trim();
  if (source.isEmpty) return const TypeParseResult.fail('نوع خالی است.');
  var nullable = false;
  if (source.endsWith('?')) {
    nullable = true;
    source = source.substring(0, source.length - 1).trim();
  }
  final type = _parseNonNull(source, idByName);
  if (type is String) return TypeParseResult.fail(type);
  return TypeParseResult.ok(type as FieldType, nullable);
}

/// FieldType یا (در صورت خطا) یک String پیام خطا
Object _parseNonNull(String source, Map<String, String> idByName) {
  final listMatch = RegExp(r'^list\s*<(.+)>$', caseSensitive: false).firstMatch(source);
  if (listMatch != null) {
    final inner = listMatch.group(1)!.trim();
    if (inner.endsWith('?')) return 'عضو لیست نمی‌تواند null باشد: «$source»';
    final innerType = _parseNonNull(inner, idByName);
    return innerType is FieldType ? FieldType.listOf(innerType) : innerType;
  }
  final alias = _kTypeAliases[source.replaceAll(' ', '').toLowerCase()];
  if (alias != null) return FieldType.primitive(alias);
  final exact = idByName[source];
  if (exact != null) return FieldType.model(exact);
  for (final entry in idByName.entries) {
    if (entry.key.toLowerCase() == source.toLowerCase()) return FieldType.model(entry.value);
  }
  return 'نوع «$source» پیدا نشد (نه نوع پایه است و نه مدلی با این نام در پروژه هست).';
}

/// نوع را برای نمایش می‌نویسد؛ [nameOf] نام مدل را از روی شناسه می‌دهد (null = مدل حذف شده)
String describeFieldType(FieldType type, String? Function(String modelId) nameOf, {bool nullable = false}) {
  String core(FieldType t) {
    switch (t.kind) {
      case FieldKind.primitive:
        return t.primitive == 'Map' ? 'Map<String, dynamic>' : t.primitive!;
      case FieldKind.model:
        return nameOf(t.modelId!) ?? '⚠ مدل حذف‌شده';
      case FieldKind.list:
        return 'List<${core(t.element!)}>';
    }
  }

  final text = core(type);
  return nullable && text != 'dynamic' ? '$text?' : text;
}

/// نتیجه‌ی خواندن چند خط «key=...,type=...»
class SpecParseResult {
  final List<ModelField> fields;
  final List<String> errors;
  const SpecParseResult(this.fields, this.errors);
}

/// متنی مثل
///   key=name,type=String
///   key=products,Type=List<Product>
///   key=favProduct,type=Product?
/// را به فیلد تبدیل می‌کند. (حروف key/type بزرگ و کوچک فرقی ندارد)
SpecParseResult parseFieldSpec(String text, Map<String, String> idByName) {
  final fields = <ModelField>[];
  final errors = <String>[];
  final linePattern = RegExp(r'^key\s*=\s*([^,]+?)\s*,\s*type\s*=\s*(.+)$', caseSensitive: false);
  var lineNumber = 0;
  for (final rawLine in text.split('\n')) {
    lineNumber++;
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final match = linePattern.firstMatch(line);
    if (match == null) {
      errors.add('خط $lineNumber: قالب باید key=نام,type=نوع باشد.');
      continue;
    }
    final result = parseFieldType(match.group(2)!, idByName);
    if (result.error != null) {
      errors.add('خط $lineNumber: ${result.error}');
      continue;
    }
    fields.add(ModelField(key: match.group(1)!.trim(), type: result.type!, nullable: result.nullable));
  }
  return SpecParseResult(fields, errors);
}
