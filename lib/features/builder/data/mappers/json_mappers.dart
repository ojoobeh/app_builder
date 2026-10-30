import '../../domain/entities/page_model.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/widget_node.dart';

/// تبدیل موجودیت‌ها به JSON و برعکس (قالب JSON با نسخه‌های قبلی برنامه سازگار است)
Map<String, dynamic> nodeToJson(WidgetNode n) => {
      'id': n.id,
      'type': n.type,
      'props': n.props,
      'children': n.children.map(nodeToJson).toList(),
    };

WidgetNode nodeFromJson(Map<String, dynamic> j) => WidgetNode(
      id: j['id'] as String,
      type: j['type'] as String,
      props: Map<String, dynamic>.from(j['props'] as Map),
      children: (j['children'] as List)
          .map((e) => nodeFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );

Map<String, dynamic> pageToJson(PageModel p) => {
      'id': p.id,
      'name': p.name,
      'appBar': nodeToJson(p.appBar),
      'body': nodeToJson(p.body),
      'footer': nodeToJson(p.footer),
    };

PageModel pageFromJson(Map<String, dynamic> j) => PageModel(
      id: j['id'] as String,
      name: j['name'] as String,
      appBar: nodeFromJson(Map<String, dynamic>.from(j['appBar'] as Map)),
      body: nodeFromJson(Map<String, dynamic>.from(j['body'] as Map)),
      footer: nodeFromJson(Map<String, dynamic>.from(j['footer'] as Map)),
    );

Map<String, dynamic> templateToJson(Template t) => {'id': t.id, 'name': t.name, 'node': nodeToJson(t.node)};

Template templateFromJson(Map<String, dynamic> j) => Template(
      id: j['id'] as String,
      name: j['name'] as String,
      node: nodeFromJson(Map<String, dynamic>.from(j['node'] as Map)),
    );
