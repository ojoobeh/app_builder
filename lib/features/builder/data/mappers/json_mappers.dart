import '../../domain/entities/model_def.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/entities/page_request.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';

// تبدیل موجودیت‌ها به JSON و برعکس.
// قالب JSON با نسخه‌های قبلی برنامه سازگار است (صفحه‌های قدیمی لود می‌شوند).

/// یک گره (با همه‌ی فرزندانش) → JSON
Map<String, dynamic> nodeToJson(WidgetNode node) => {
      'id': node.id,
      'type': node.type,
      'props': node.props,
      'children': node.children.map(nodeToJson).toList(),
    };

/// JSON → یک گره (با همه‌ی فرزندانش)
WidgetNode nodeFromJson(Map<String, dynamic> json) => WidgetNode(
      id: json['id'] as String,
      type: json['type'] as String,
      props: Map<String, dynamic>.from(json['props'] as Map),
      children: (json['children'] as List)
          .map((childJson) => nodeFromJson(Map<String, dynamic>.from(childJson as Map)))
          .toList(),
    );

Map<String, String> _pairToJson(RequestParam pair) => {'key': pair.key, 'value': pair.value};

List<RequestParam> _pairsFromJson(dynamic json) => [
      for (final raw in (json is List ? json : const []))
        if (raw is Map) RequestParam(key: '${raw['key'] ?? ''}', value: '${raw['value'] ?? ''}'),
    ];

/// درخواست صفحه → JSON
Map<String, dynamic> requestToJson(PageRequest request) => {
      'enabled': request.enabled,
      'url': request.url,
      'method': request.method,
      'params': request.params.map(_pairToJson).toList(),
      'paramsIn': request.paramsIn,
      'headers': request.headers.map(_pairToJson).toList(),
      'responseType': request.responseType == null ? null : fieldTypeToJson(request.responseType!),
      'dataPath': request.dataPath,
    };

/// JSON → درخواست صفحه.
/// نسخه‌های قبلی: «paramName» یک پارامتر با مقدار {value} می‌شود و «listPath» همان dataPath است.
PageRequest requestFromJson(dynamic json) {
  if (json is! Map) return PageRequest();
  final method = '${json['method'] ?? 'GET'}'.toUpperCase();
  final params = _pairsFromJson(json['params']);
  final legacyParam = '${json['paramName'] ?? ''}'.trim();
  if (json['params'] == null && legacyParam.isNotEmpty) {
    params.add(RequestParam(key: legacyParam, value: '{value}'));
  }
  final paramsIn = '${json['paramsIn'] ?? 'auto'}';
  return PageRequest(
    enabled: json['enabled'] == true,
    url: '${json['url'] ?? ''}',
    method: kRequestMethods.contains(method) ? method : 'GET',
    params: params,
    paramsIn: const ['auto', 'query', 'body'].contains(paramsIn) ? paramsIn : 'auto',
    headers: _pairsFromJson(json['headers']),
    responseType: json['responseType'] == null ? null : fieldTypeFromJson(json['responseType']),
    dataPath: '${json['dataPath'] ?? json['listPath'] ?? ''}',
  );
}

/// یک صفحه → JSON
Map<String, dynamic> pageToJson(PageModel page) => {
      'id': page.id,
      'name': page.name,
      'appBar': nodeToJson(page.appBar),
      'body': nodeToJson(page.body),
      'footer': nodeToJson(page.footer),
      'direction': page.direction,
      'projectId': page.projectId,
      'request': requestToJson(page.request),
    };

/// JSON → یک صفحه
PageModel pageFromJson(Map<String, dynamic> json) => PageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      appBar: nodeFromJson(Map<String, dynamic>.from(json['appBar'] as Map)),
      body: nodeFromJson(Map<String, dynamic>.from(json['body'] as Map)),
      footer: nodeFromJson(Map<String, dynamic>.from(json['footer'] as Map)),
      direction: json['direction'] as String? ?? 'ltr', // صفحه‌های قدیمی جهت ندارند
      projectId: json['projectId'] as String? ?? '', // صفحه‌های قدیمی پروژه ندارند (مهاجرت می‌شوند)
      request: requestFromJson(json['request']),
    );

/// یک قالب → JSON
Map<String, dynamic> templateToJson(Template template) =>
    {'id': template.id, 'name': template.name, 'node': nodeToJson(template.node)};

/// JSON → یک قالب
Template templateFromJson(Map<String, dynamic> json) => Template(
      id: json['id'] as String,
      name: json['name'] as String,
      node: nodeFromJson(Map<String, dynamic>.from(json['node'] as Map)),
    );

/// یک پروژه → JSON
Map<String, dynamic> projectToJson(Project project) => {'id': project.id, 'name': project.name};

/// JSON → یک پروژه
Project projectFromJson(Map<String, dynamic> json) =>
    Project(id: json['id'] as String, name: json['name'] as String);

// ---------- مدل‌های داده ----------

/// نوع فیلد → JSON  ({'k': 'primitive', 'name': 'String'} / {'k': 'model', 'id': ...} / {'k': 'list', 'of': {...}})
Map<String, dynamic> fieldTypeToJson(FieldType type) {
  switch (type.kind) {
    case FieldKind.primitive:
      return {'k': 'primitive', 'name': type.primitive};
    case FieldKind.model:
      return {'k': 'model', 'id': type.modelId};
    case FieldKind.list:
      return {'k': 'list', 'of': fieldTypeToJson(type.element!)};
  }
}

/// JSON → نوع فیلد (مقدار ناشناخته dynamic می‌شود تا خواندن هیچ‌وقت خراب نشود)
FieldType fieldTypeFromJson(dynamic json) {
  if (json is! Map) return const FieldType.primitive('dynamic');
  switch (json['k']) {
    case 'model':
      return FieldType.model('${json['id']}');
    case 'list':
      return FieldType.listOf(fieldTypeFromJson(json['of']));
    default:
      final name = '${json['name']}';
      return FieldType.primitive(kPrimitiveTypes.contains(name) ? name : 'dynamic');
  }
}

Map<String, dynamic> modelToJson(ModelDef model) => {
      'id': model.id,
      'projectId': model.projectId,
      'name': model.name,
      'fields': [
        for (final field in model.fields)
          {'key': field.key, 'type': fieldTypeToJson(field.type), 'nullable': field.nullable},
      ],
    };

ModelDef modelFromJson(Map<String, dynamic> json) => ModelDef(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      fields: [
        for (final raw in (json['fields'] as List? ?? const []))
          ModelField(
            key: '${raw['key']}',
            type: fieldTypeFromJson(raw['type']),
            nullable: raw['nullable'] == true,
          ),
      ],
    );
