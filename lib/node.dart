import 'dart:convert';

/// مدل داده: هر ویجت یک Node است (type + props + children).
/// همه چیز JSON-پذیر است تا ذخیره، خروجی کد و آپدیت‌های بعدی ساده باشد.
class WidgetNode {
  static int _counter = 0;
  final String id;
  final String type;
  Map<String, dynamic> props;
  List<WidgetNode> children;

  WidgetNode({String? id, required this.type, Map<String, dynamic>? props, List<WidgetNode>? children})
      : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
        props = props ?? {},
        children = children ?? [];

  /// کپی عمیق با شناسه‌های جدید
  WidgetNode clone() => WidgetNode(
        type: type,
        props: Map<String, dynamic>.from(jsonDecode(jsonEncode(props)) as Map),
        children: children.map((c) => c.clone()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'props': props,
        'children': children.map((e) => e.toJson()).toList(),
      };

  factory WidgetNode.fromJson(Map<String, dynamic> j) => WidgetNode(
        id: j['id'] as String,
        type: j['type'] as String,
        props: Map<String, dynamic>.from(j['props'] as Map),
        children: (j['children'] as List)
            .map((e) => WidgetNode.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// یک صفحه = سه بخش ثابت: اپ‌بار، بدنه، فوتر
class PageModel {
  final String id;
  String name;
  WidgetNode appBar;
  WidgetNode body;
  WidgetNode footer;

  PageModel({required this.id, required this.name, required this.appBar, required this.body, required this.footer});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'appBar': appBar.toJson(),
        'body': body.toJson(),
        'footer': footer.toJson(),
      };

  factory PageModel.fromJson(Map<String, dynamic> j) => PageModel(
        id: j['id'] as String,
        name: j['name'] as String,
        appBar: WidgetNode.fromJson(Map<String, dynamic>.from(j['appBar'] as Map)),
        body: WidgetNode.fromJson(Map<String, dynamic>.from(j['body'] as Map)),
        footer: WidgetNode.fromJson(Map<String, dynamic>.from(j['footer'] as Map)),
      );
}

/// قالب کاربر: یک ویجت (با همه‌ی فرزندانش) که با نام ذخیره شده است
class Template {
  final String id;
  String name;
  final WidgetNode node;
  Template({required this.id, required this.name, required this.node});

  WidgetNode instantiate() => node.clone();

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'node': node.toJson()};

  factory Template.fromJson(Map<String, dynamic> j) => Template(
        id: j['id'] as String,
        name: j['name'] as String,
        node: WidgetNode.fromJson(Map<String, dynamic>.from(j['node'] as Map)),
      );
}
