import '../entities/model_def.dart';
import '../models/dart_naming.dart';

// تبدیل مدل‌های یک پروژه به کلاس‌های دارت (fromJson / toJson / copyWith).
// خروجی فقط یک Map از «مسیر فایل ← متن» است و به Flutter وابسته نیست.

String _escape(String text) => text.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$');

/// اعضای کنترلر برای نگه‌داشتن پاسخ سرور با نوع مشخص (مثلاً User یا List<User>)
class TypedResponse {
  /// خط تعریف فیلد کنترلر (مثلاً `final Rxn<User> response = Rxn<User>();`)
  final String field;

  /// دستوری که از متغیر `payload` (داده‌ی خام پاسخ) مقدار typed می‌سازد و در `response` می‌گذارد
  final String assign;

  /// import مدل‌ها (خالی = لازم نیست)
  final String importLine;
  const TypedResponse({required this.field, required this.assign, required this.importLine});
}

class ModelCodeGenerator {
  const ModelCodeGenerator();

  /// پوشه‌ی مدل‌ها در پروژه‌ی خروجی
  static const String folder = 'lib/app/models';

  /// همه‌ی فایل‌های مدل + یک فایل models.dart که همه را export می‌کند
  Map<String, String> generate(List<ModelDef> models) {
    final files = <String, String>{};
    if (models.isEmpty) return files;
    final byId = {for (final model in models) model.id: model};
    for (final model in models) {
      files['$folder/${modelFileName(model.name)}.dart'] = _modelSource(model, byId);
    }
    final exports = models.map((model) => "export '${modelFileName(model.name)}.dart';").toList()..sort();
    files['$folder/models.dart'] = '${exports.join('\n')}\n';
    return files;
  }

  // --------------------------------------------------------------------------

  /// ارجاع به مدلِ حذف‌شده را به dynamic تبدیل می‌کند تا کد خروجی همیشه کامپایل شود
  FieldType _resolve(FieldType type, Map<String, ModelDef> byId) {
    switch (type.kind) {
      case FieldKind.primitive:
        return type;
      case FieldKind.model:
        return byId.containsKey(type.modelId) ? type : const FieldType.primitive('dynamic');
      case FieldKind.list:
        return FieldType.listOf(_resolve(type.element!, byId));
    }
  }

  String _typeCode(FieldType type, Map<String, ModelDef> byId) {
    if (type.kind == FieldKind.list) return 'List<${_typeCode(type.element!, byId)}>';
    if (type.kind == FieldKind.model) return byId[type.modelId]!.name;
    return type.primitive == 'Map' ? 'Map<String, dynamic>' : type.primitive!;
  }

  /// نوع دارت با ? در صورت nullable بودن (dynamic خودش null می‌پذیرد)
  String _declared(FieldType type, bool nullable, Map<String, ModelDef> byId) {
    final code = _typeCode(type, byId);
    return nullable && code != 'dynamic' ? '$code?' : code;
  }

  /// عبارتی که مقدار [src] (از JSON) را به نوع دارت تبدیل می‌کند
  String _fromExpr(FieldType type, String src, bool nullable, Map<String, ModelDef> byId, [int depth = 0]) {
    if (type.kind == FieldKind.list) {
      final variable = 'e$depth';
      final element = _fromExpr(type.element!, variable, false, byId, depth + 1);
      return nullable
          ? '$src == null ? null : ($src as List).map(($variable) => $element).toList()'
          : '(($src as List?) ?? const []).map(($variable) => $element).toList()';
    }
    if (type.kind == FieldKind.model) {
      final name = byId[type.modelId]!.name;
      return nullable
          ? '$src is Map ? $name.fromJson(Map<String, dynamic>.from($src)) : null'
          : '$name.fromJson(Map<String, dynamic>.from($src as Map))';
    }
    switch (type.primitive) {
      case 'String':
        return nullable ? '$src?.toString()' : "$src?.toString() ?? ''";
      case 'int':
        return nullable ? '($src as num?)?.toInt()' : '($src as num?)?.toInt() ?? 0';
      case 'double':
        return nullable ? '($src as num?)?.toDouble()' : '($src as num?)?.toDouble() ?? 0.0';
      case 'num':
        return nullable ? '$src as num?' : '($src as num?) ?? 0';
      case 'bool':
        return nullable ? '$src as bool?' : '($src as bool?) ?? false';
      case 'DateTime':
        return nullable
            ? 'DateTime.tryParse($src.toString())'
            : 'DateTime.tryParse($src.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0)';
      case 'Map':
        return nullable
            ? '$src is Map ? Map<String, dynamic>.from($src) : null'
            : '$src is Map ? Map<String, dynamic>.from($src) : <String, dynamic>{}';
      default:
        return src; // dynamic
    }
  }

  /// آیا این نوع برای تبدیل به JSON کار اضافه می‌خواهد؟ (DateTime یا مدل، مستقیم یا داخل لیست)
  bool _needsToJson(FieldType type) {
    final base = type.base;
    return base.kind == FieldKind.model || base.primitive == 'DateTime';
  }

  /// عبارتی که مقدار دارت [value] را برای JSON آماده می‌کند
  String _toExpr(FieldType type, String value, bool nullable, [int depth = 0]) {
    if (!_needsToJson(type)) return value;
    final dot = nullable ? '?.' : '.';
    if (type.kind == FieldKind.list) {
      final variable = 'e$depth';
      return '$value${dot}map(($variable) => ${_toExpr(type.element!, variable, false, depth + 1)}).toList()';
    }
    if (type.kind == FieldKind.model) return '$value${dot}toJson()';
    return '$value${dot}toIso8601String()'; // DateTime
  }

  /// فیلد و دستور تبدیل برای ذخیره‌ی پاسخ سرور در کنترلر با نوع [type]؛ null = بدون نوع.
  /// مسیر import از کنترلر هر صفحه (lib/features/<صفحه>/presentation/controllers) به lib/app/models است.
  TypedResponse? typedResponse(FieldType? type, List<ModelDef> models) {
    if (type == null) return null;
    final byId = {for (final model in models) model.id: model};
    final resolved = _resolve(type, byId);
    final code = _typeCode(resolved, byId);
    final usesModel = resolved.base.kind == FieldKind.model;
    final importLine = usesModel ? "import '../../../../app/models/models.dart';" : '';
    // لیست ساده → RxList ؛ بقیه (تک‌مقدار یا لیست تو در تو) → Rxn
    if (resolved.kind == FieldKind.list && resolved.element!.kind != FieldKind.list) {
      final element = _typeCode(resolved.element!, byId);
      return TypedResponse(
        field: 'final RxList<$element> response = <$element>[].obs; // پاسخ سرور با نوع $code',
        assign: 'response.assignAll(${_fromExpr(resolved, 'payload', false, byId)});',
        importLine: importLine,
      );
    }
    return TypedResponse(
      field: 'final Rxn<$code> response = Rxn<$code>(); // پاسخ سرور با نوع $code',
      assign: 'response.value = ${_fromExpr(resolved, 'payload', true, byId)};',
      importLine: importLine,
    );
  }

  String _modelSource(ModelDef model, Map<String, ModelDef> byId) {
    final fields = [
      for (final field in model.fields)
        if (fieldDartName(field.key) != null)
          (
            json: field.key,
            name: fieldDartName(field.key)!,
            type: _resolve(field.type, byId),
            nullable: field.nullable,
          ),
    ];

    // importهای مدل‌های دیگر (بدون خودش)
    final imports = <String>{};
    for (final field in fields) {
      for (final id in field.type.referencedModelIds()) {
        if (id != model.id) imports.add("import '${modelFileName(byId[id]!.name)}.dart';");
      }
    }

    final out = StringBuffer();
    if (imports.isNotEmpty) {
      out.writeln((imports.toList()..sort()).join('\n'));
      out.writeln();
    }
    out.writeln('/// مدل ${model.name} (تولیدشده با Page Builder)');
    out.writeln('class ${model.name} {');
    for (final field in fields) {
      out.writeln('  final ${_declared(field.type, field.nullable, byId)} ${field.name};');
    }
    if (fields.isNotEmpty) out.writeln();

    // سازنده
    if (fields.isEmpty) {
      out.writeln('  const ${model.name}();');
    } else {
      out.writeln('  const ${model.name}({');
      for (final field in fields) {
        final needsRequired = !field.nullable && field.type.primitive != 'dynamic';
        out.writeln('    ${needsRequired ? 'required ' : ''}this.${field.name},');
      }
      out.writeln('  });');
    }
    out.writeln();

    // fromJson
    out.writeln('  factory ${model.name}.fromJson(Map<String, dynamic> json) {');
    out.writeln('    return ${model.name}(');
    for (final field in fields) {
      final src = "json['${_escape(field.json)}']";
      out.writeln('      ${field.name}: ${_fromExpr(field.type, src, field.nullable, byId)},');
    }
    out.writeln('    );');
    out.writeln('  }');
    out.writeln();

    // toJson
    if (fields.isEmpty) {
      out.writeln('  Map<String, dynamic> toJson() => <String, dynamic>{};');
    } else {
      out.writeln('  Map<String, dynamic> toJson() => {');
      for (final field in fields) {
        out.writeln("        '${_escape(field.json)}': ${_toExpr(field.type, field.name, field.nullable)},");
      }
      out.writeln('      };');
    }

    // copyWith
    if (fields.isNotEmpty) {
      out.writeln();
      out.writeln('  ${model.name} copyWith({');
      for (final field in fields) {
        final code = _typeCode(field.type, byId);
        out.writeln('    ${code == 'dynamic' ? 'dynamic' : '$code?'} ${field.name},');
      }
      out.writeln('  }) {');
      out.writeln('    return ${model.name}(');
      for (final field in fields) {
        out.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
      }
      out.writeln('    );');
      out.writeln('  }');
    }
    out.writeln('}');
    return out.toString();
  }
}
