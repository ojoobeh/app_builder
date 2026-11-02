/// نوع‌های پایه‌ای که برای هر فیلد می‌شود انتخاب کرد.
/// 'Map' در کد خروجی به Map<String, dynamic> تبدیل می‌شود.
const List<String> kPrimitiveTypes = ['String', 'int', 'double', 'bool', 'num', 'DateTime', 'dynamic', 'Map'];

/// نوع کلی یک فیلد: پایه (String, int, ...)، ارجاع به یک مدل دیگر، یا لیست از یک نوع
enum FieldKind { primitive, model, list }

/// نوع یک فیلد. ارجاع به مدل‌ها با «شناسه» است نه «نام»، پس عوض کردن نام یک مدل
/// ارجاع‌های موجود را خراب نمی‌کند.
///
///  String            → FieldType.primitive('String')
///  Product           → FieldType.model(productId)
///  List<Product>     → FieldType.listOf(FieldType.model(productId))
///  List<List<int>>   → FieldType.listOf(FieldType.listOf(FieldType.primitive('int')))
class FieldType {
  final FieldKind kind;
  final String? primitive;
  final String? modelId;
  final FieldType? element;

  const FieldType._(this.kind, {this.primitive, this.modelId, this.element});
  const FieldType.primitive(String name) : this._(FieldKind.primitive, primitive: name);
  const FieldType.model(String id) : this._(FieldKind.model, modelId: id);
  const FieldType.listOf(FieldType inner) : this._(FieldKind.list, element: inner);

  /// عمیق‌ترین نوع (برای List<List<int>> می‌شود int)
  FieldType get base => kind == FieldKind.list ? element!.base : this;

  /// تعداد لایه‌های لیست (۰ = لیست نیست)
  int get listDepth => kind == FieldKind.list ? 1 + element!.listDepth : 0;

  /// شناسه‌ی همه‌ی مدل‌هایی که این نوع به آن‌ها اشاره دارد
  Set<String> referencedModelIds() {
    final base = this.base;
    return base.kind == FieldKind.model ? {base.modelId!} : <String>{};
  }

  /// نوع را با این عمق لیست دوباره می‌سازد (برای انتخابگر نوع در UI)
  static FieldType wrapInLists(FieldType base, int depth) {
    var result = base;
    for (var i = 0; i < depth; i++) {
      result = FieldType.listOf(result);
    }
    return result;
  }
}

/// یک فیلد مدل: key همان کلید JSON است (مثلاً first_name)؛ نام پراپرتی دارت
/// خودکار از آن ساخته می‌شود (firstName).
class ModelField {
  String key;
  FieldType type;

  /// اگر true باشد نوع در دارت با ? می‌آید (مثلاً String?) و مقدار ممکن است null باشد
  bool nullable;

  ModelField({required this.key, required this.type, this.nullable = false});

  ModelField copy() => ModelField(key: key, type: type, nullable: nullable);
}

/// یک مدل داده (مثل User یا Product) که به یک پروژه تعلق دارد.
/// هر پروژه مدل‌های مخصوص خودش را دارد (پروژه‌ی A و B جدا هستند).
class ModelDef {
  final String id;

  /// شناسه‌ی پروژه‌ای که این مدل به آن تعلق دارد
  final String projectId;

  /// نام کلاس (PascalCase، انگلیسی)
  String name;
  List<ModelField> fields;

  ModelDef({required this.id, required this.projectId, required this.name, List<ModelField>? fields})
      : fields = fields ?? [];

  /// کپی عمیق (ادیتور روی کپی کار می‌کند تا با «انصراف» چیزی تغییر نکند)
  ModelDef copy() => ModelDef(
        id: id,
        projectId: projectId,
        name: name,
        fields: fields.map((field) => field.copy()).toList(),
      );
}
