import '../catalog/widget_catalog.dart';
import '../entities/model_def.dart';
import '../entities/page_request.dart';
import '../entities/widget_node.dart';

// ساخت پیشنهادهای binding و ویجت‌های آماده از روی «نوع پاسخ» درخواست صفحه.
// دارت خالص است؛ bindingها با کلید JSON فیلد (key مدل) نوشته می‌شوند چون {{item.xxx}}
// روی داده‌ی خام JSON کار می‌کند، نه روی اسم پراپرتی دارت.

/// یک پیشنهاد binding (مثل item.name) برای درج در متن ویجت
class BindingSuggestion {
  /// عبارت داخل {{ }}
  final String expression;
  const BindingSuggestion(this.expression);
  String get token => '{{$expression}}';
}

final RegExp _kSafeKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// پیشوند دسترسی به خود پاسخ: «data» یا «data.<dataPath>»
String _dataPrefix(PageRequest request) {
  final path = request.dataPath.trim();
  return path.isEmpty ? 'data' : 'data.$path';
}

/// مدلِ عضو لیست (برای List<Model>) یا خود مدل (برای Model)؛ null اگر نوع پاسخ مدل نیست
ModelDef? _modelOf(FieldType type, List<ModelDef> models) {
  if (type.kind != FieldKind.model) return null;
  for (final model in models) {
    if (model.id == type.modelId) return model;
  }
  return null;
}

/// مسیرهای قابل نمایش (فیلدهای ساده + یک سطح فیلدهای مدل تو در تو) با پیشوند [prefix]
List<String> _fieldPaths(ModelDef model, String prefix, List<ModelDef> models, {int depth = 0}) {
  final paths = <String>[];
  for (final field in model.fields) {
    if (!_kSafeKey.hasMatch(field.key)) continue;
    final path = '$prefix.${field.key}';
    final type = field.type;
    if (type.kind == FieldKind.primitive) {
      if (type.primitive != 'Map') paths.add(path);
    } else if (type.kind == FieldKind.model && depth < 1) {
      final nested = _modelOf(type, models);
      if (nested != null) paths.addAll(_fieldPaths(nested, path, models, depth: depth + 1));
    }
  }
  return paths;
}

/// پیشنهادهای binding برای یک متن.
///  • داخل «لیست داده‌ای» و پاسخ List<Model> → item.<field>
///  • بیرون لیست و پاسخ Model → data.<مسیر>.<field>
List<BindingSuggestion> bindingSuggestions(PageRequest request, List<ModelDef> models, {required bool insideList}) {
  final type = request.responseType;
  if (!request.enabled || type == null) return const [];
  if (insideList) {
    if (type.kind != FieldKind.list || type.element!.kind == FieldKind.list) return const [];
    final element = type.element!;
    if (element.kind == FieldKind.primitive) return const [BindingSuggestion('item')];
    final model = _modelOf(element, models);
    return model == null ? const [] : [for (final path in _fieldPaths(model, 'item', models)) BindingSuggestion(path)];
  }
  final model = _modelOf(type, models);
  if (model == null) return const [];
  return [for (final path in _fieldPaths(model, _dataPrefix(request), models)) BindingSuggestion(path)];
}

WidgetNode _text(String text, {bool title = false}) {
  final node = WidgetCatalog.create('text');
  node.props['text'] = text;
  if (title) {
    node.props['size'] = 18.0;
    node.props['bold'] = true;
  }
  return node;
}

/// ویجت آماده برای نمایش پاسخ، با bindingهای وصل‌شده:
///  • List<Model> → «لیست داده‌ای» با یک کارت برای هر ردیف
///  • Model       → یک ستون با متن هر فیلد
/// اگر نوع پاسخ چیز دیگری باشد (یا درخواست خاموش باشد) null برمی‌گرداند.
WidgetNode? buildResponseWidgets(PageRequest request, List<ModelDef> models) {
  final type = request.responseType;
  if (!request.enabled || type == null) return null;
  final isList = type.kind == FieldKind.list && type.element!.kind == FieldKind.model;
  final model = _modelOf(isList ? type.element! : type, models);
  if (model == null) return null;

  final prefix = isList ? 'item' : _dataPrefix(request);
  final fields = model.fields
      .where((field) => _kSafeKey.hasMatch(field.key) && field.type.kind == FieldKind.primitive && field.type.primitive != 'Map')
      .take(6)
      .toList();
  if (fields.isEmpty) return null;

  final column = WidgetCatalog.create('column');
  for (var i = 0; i < fields.length; i++) {
    final key = fields[i].key;
    column.children.add(i == 0 ? _text('{{$prefix.$key}}', title: true) : _text('$key: {{$prefix.$key}}'));
  }
  if (!isList) return column;

  final card = WidgetCatalog.create('card')..children.add(column);
  return WidgetCatalog.create('dataList')..children.add(card);
}
