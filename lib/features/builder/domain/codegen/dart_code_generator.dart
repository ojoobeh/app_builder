import '../entities/widget_node.dart';
import '../entities/page_model.dart';
import '../catalog/widget_def.dart';
import '../catalog/widget_catalog.dart';

/// تبدیل درخت Node به کد دارت مستقل (فقط وابسته به material، بدون get/hive).
String _ind(int i) => '  ' * i;
String _n(dynamic v) => (v is num ? v.toDouble() : 0.0).toString();
String? _opt(dynamic v) => (v is num && v > 0) ? v.toDouble().toString() : null;
String _col(dynamic v) =>
    v is int ? 'Color(0x${v.toRadixString(16).padLeft(8, '0').toUpperCase()})' : 'Colors.black';
String _s(dynamic v) {
  final t = '${v ?? ''}'
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n');
  return "'$t'";
}

const _iconNames = {
  'cart': 'shopping_cart', 'arrow_down': 'keyboard_arrow_down', 'location': 'location_on',
  'camera': 'camera_alt', 'play': 'play_arrow', 'filter': 'filter_list', 'calendar': 'calendar_today',
  'more': 'more_vert', 'wallet': 'account_balance_wallet', 'tag': 'local_offer',
};
String _icon(dynamic k) => _iconNames['$k'] ?? '$k';

/// Name(\n  key: value,\n) — مقدار هر آرگومان باید در سطح i+1 تولید شده باشد
String _call(String name, int i, Map<String, String> args) {
  final b = StringBuffer('$name(\n');
  args.forEach((k, v) => b.write('${_ind(i + 1)}$k: $v,\n'));
  b.write('${_ind(i)})');
  return b.toString();
}

String _child(WidgetNode k, int i, bool flexOk) {
  final f = (flexOk && k.props['flex'] is num) ? (k.props['flex'] as num).toInt() : 0;
  if (f <= 0) {
    final c = gen(k, i);
    // TextField در Row بدون Expanded عرض نامحدود می‌گیرد و خطا می‌دهد
    return (flexOk && k.type == 'textField') ? 'SizedBox(width: 200.0, child: $c)' : c;
  }
  return _call('Expanded', i, {'flex': '$f', 'child': gen(k, i + 1)});
}

String _list(List<WidgetNode> ks, int i, {bool flex = false}) {
  if (ks.isEmpty) return '[]';
  final b = StringBuffer('[\n');
  for (final k in ks) {
    b.write('${_ind(i + 1)}${_child(k, i + 1, flex)},\n');
  }
  b.write('${_ind(i)}]');
  return b.toString();
}

String gen(WidgetNode n, int i) {
  final p = n.props;
  switch (n.type) {
    case 'column':
    case 'row':
      return _call('Padding', i, {
        'padding': 'EdgeInsets.all(${_n(p['padding'])})',
        'child': _call(n.type == 'column' ? 'Column' : 'Row', i + 1, {
          'mainAxisAlignment': 'MainAxisAlignment.${p['main']}',
          'crossAxisAlignment': 'CrossAxisAlignment.${p['cross']}',
          'spacing': _n(p['spacing']),
          'children': _list(n.children, i + 2, flex: n.type == 'row'),
        }),
      });
    case 'stack':
      return _call('Padding', i, {
        'padding': 'EdgeInsets.all(${_n(p['padding'])})',
        'child': _call('Stack', i + 1, {
          'alignment': 'Alignment.${p['align']}',
          'children': _list(n.children, i + 2),
        }),
      });
    case 'container':
      final w = _opt(p['width']), h = _opt(p['height']);
      final k = n.children;
      return _call('Container', i, {
        if (w != null) 'width': w,
        if (h != null) 'height': h,
        'padding': 'EdgeInsets.all(${_n(p['padding'])})',
        'decoration':
            'BoxDecoration(color: ${_col(p['bg'])}, borderRadius: BorderRadius.circular(${_n(p['radius'])}))',
        if (k.length == 1) 'child': gen(k.first, i + 1),
        if (k.length > 1)
          'child': _call('Column', i + 1, {
            'mainAxisSize': 'MainAxisSize.min',
            'children': _list(k, i + 2),
          }),
      });
    case 'card':
      final ce = (p['elevation'] is num) ? (p['elevation'] as num).toDouble() : 0.0;
      final cbw = _opt(p['borderWidth']);
      final cw = _opt(p['width']), ch = _opt(p['height']), cm = _opt(p['margin']);
      final ck = n.children;
      final deco =
          'BoxDecoration(color: ${_col(p['bg'])}, borderRadius: BorderRadius.circular(${_n(p['radius'])})${cbw != null ? ', border: Border.all(color: ${_col(p['borderColor'])}, width: $cbw)' : ''}${ce > 0 ? ', boxShadow: [BoxShadow(color: ${_col(p['shadowColor'])}, blurRadius: ${ce * 2}, offset: Offset(0.0, ${ce / 2}))]' : ''})';
      return _call('Container', i, {
        if (cm != null) 'margin': 'EdgeInsets.all($cm)',
        if (cw != null) 'width': cw,
        if (ch != null) 'height': ch,
        'padding': 'EdgeInsets.all(${_n(p['padding'])})',
        if (p['clip'] != false) 'clipBehavior': 'Clip.antiAlias',
        'decoration': deco,
        if (ck.length == 1) 'child': gen(ck.first, i + 1),
        if (ck.length > 1)
          'child': _call('Column', i + 1, {'mainAxisSize': 'MainAxisSize.min', 'children': _list(ck, i + 2)}),
      });
    case 'text':
      final bold = p['bold'] == true ? ', fontWeight: FontWeight.bold' : '';
      return 'Text(${_s(p['text'])}, style: TextStyle(fontSize: ${_n(p['size'])}, color: ${_col(p['color'])}$bold))';
    case 'textField':
      final tbc = _col(p['borderColor'] ?? 0);
      final tob = 'OutlineInputBorder(borderRadius: BorderRadius.circular(${_n(p['radius'] ?? 8.0)}), borderSide: BorderSide(color: $tbc))';
      return _call('TextField', i, {
        'style': 'TextStyle(color: ${_col(p['fg'])})',
        'decoration':
            'InputDecoration(hintText: ${_s(p['hint'])}, hintStyle: TextStyle(color: ${_col(p['fg'])}.withValues(alpha: 0.5)), filled: true, fillColor: ${_col(p['bg'] ?? 0xFFFFFFFF)}, isDense: true, border: $tob, enabledBorder: $tob, focusedBorder: $tob)',
      });
    case 'svg':
      return 'SvgPicture.string(${_s(p['svg'])}, width: ${_n(p['size'])}, height: ${_n(p['size'])}, colorFilter: ColorFilter.mode(${_col(p['color'])}, BlendMode.srcIn))';
    case 'icon':
      return 'Icon(Icons.${_icon(p['icon'])}, size: ${_n(p['size'])}, color: ${_col(p['color'])})';
    case 'button':
      final shape = 'RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_n(p['radius'] ?? 8.0)}))';
      final fg = _col(p['fg'] ?? 0xFFFFFFFF);
      final bold = p['bold'] == true ? ', style: TextStyle(fontWeight: FontWeight.bold)' : '';
      final kind = p['kind'] ?? 'filled';
      final cls = kind == 'outlined' ? 'OutlinedButton' : (kind == 'text' ? 'TextButton' : 'ElevatedButton');
      final style = kind == 'outlined'
          ? '$cls.styleFrom(foregroundColor: $fg, shape: $shape, side: BorderSide(color: $fg, width: 1.5))'
          : (kind == 'text'
              ? '$cls.styleFrom(foregroundColor: $fg, shape: $shape)'
              : '$cls.styleFrom(backgroundColor: ${_col(p['bg'])}, foregroundColor: $fg, elevation: ${_n(p['elevation'] ?? 2.0)}, shape: $shape)');
      return _call(cls, i, {
        'onPressed': '() {}',
        'style': style,
        'child': 'Text(${_s(p['text'])}$bold)',
      });
    case 'navItem':
      return 'Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.${_icon(p['icon'])}), Text(${_s(p['label'])})])';
    case 'image':
      String cr(String k) => _n(p[k] ?? p['radius']);
      final rad =
          'BorderRadius.only(topLeft: Radius.circular(${cr('rTL')}), topRight: Radius.circular(${cr('rTR')}), bottomLeft: Radius.circular(${cr('rBL')}), bottomRight: Radius.circular(${cr('rBR')}))';
      final String child;
      if (p['mode'] == 'banner') {
        child =
            'AspectRatio(aspectRatio: ${_opt(p['ratio']) ?? '1.78'}, child: Image.network(${_s(p['url'])}, width: double.infinity, height: double.infinity, fit: BoxFit.cover))';
      } else {
        final iw = _opt(p['width']), ih = _opt(p['height']) ?? '150.0';
        child = 'Image.network(${_s(p['url'])}${iw != null ? ', width: $iw' : ''}, height: $ih, fit: BoxFit.cover)';
      }
      return _call('ClipRRect', i, {'borderRadius': rad, 'child': child});
    default:
      return 'const SizedBox.shrink()';
  }
}

/// نام کلاس پیش‌فرض: از اسم انگلیسی صفحه، وگرنه Page + چند رقم آخر id
String defaultClassName(PageModel p) {
  final ascii = p.name.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ').trim();
  if (ascii.isEmpty || RegExp(r'^[0-9]').hasMatch(ascii)) {
    return 'Page${p.id.substring(p.id.length - 4)}';
  }
  final words = ascii.split(RegExp(r'\s+')).map((w) => w[0].toUpperCase() + w.substring(1));
  return '${words.join()}Page';
}

String fileNameOf(String cls) =>
    '${cls.replaceAllMapped(RegExp(r'(?<=[a-z0-9])[A-Z]'), (m) => '_${m[0]}').toLowerCase()}.dart';

String _raw(List<String> xs, int i) {
  final b = StringBuffer('[\n');
  for (final x in xs) {
    b.write('${_ind(i + 1)}$x,\n');
  }
  b.write('${_ind(i)}]');
  return b.toString();
}

List<WidgetNode> _navItems(PageModel p) => p.footer.children.where((k) => k.type == 'navItem').toList();
bool _isNav(PageModel p) =>
    p.footer.props['hidden'] != true && '${p.footer.props['variant'] ?? 'bar'}' != 'bar' && _navItems(p).length >= 2;

Variant? _variantOf(PageModel p) {
  if (!_isNav(p)) return null;
  final id = p.footer.props['variant'];
  return WidgetCatalog.of('footer').variants.where((v) => v.id == id).firstOrNull;
}

/// خطوط pubspec که این صفحه نیاز دارد (برای کتابخانه‌ها)
List<String> requiredDeps(PageModel p) {
  final d = _variantOf(p)?.depLine;
  return [if (d != null) d, if (_hasSvg(p)) 'flutter_svg: ^2.0.10+1'];
}

String? _footerCode(PageModel p) {
  final f = p.footer.props;
  final v = '${f['variant'] ?? 'bar'}';
  if (f['hidden'] == true) return null;
  final bg = _col(f['bg']), sel = _col(f['sel'] ?? 0xFF3F51B5);
  if (!_isNav(p)) {
    if (p.footer.children.isEmpty) return null;
    return _call('Container', 3, {
      'height': _n(f['height']),
      'color': bg,
      'child': _call('Row', 4, {
        'mainAxisAlignment': 'MainAxisAlignment.${f['main']}',
        'children': _list(p.footer.children, 5, flex: true),
      }),
    });
  }
  const set = '(i) => setState(() => _index = i)';
  final items = _navItems(p);
  String ic(WidgetNode n) => 'Icons.${_icon(n.props['icon'])}';
  String lb(WidgetNode n) => _s(n.props['label']);
  switch (v) {
    case 'nav_classic':
      return _call('BottomNavigationBar', 3, {
        'type': 'BottomNavigationBarType.fixed',
        'backgroundColor': bg,
        'selectedItemColor': sel,
        'unselectedItemColor': 'Colors.grey',
        'currentIndex': '_index',
        'onTap': set,
        'items': _raw([for (final n in items) 'BottomNavigationBarItem(icon: Icon(${ic(n)}), label: ${lb(n)})'], 4),
      });
    case 'nav_m3':
      return _call('NavigationBar', 3, {
        'backgroundColor': bg,
        'indicatorColor': '$sel.withValues(alpha: 0.2)',
        'selectedIndex': '_index',
        'onDestinationSelected': set,
        'destinations': _raw([for (final n in items) 'NavigationDestination(icon: Icon(${ic(n)}), label: ${lb(n)})'], 4),
      });
    case 'nav_text':
      return _call('Container', 3, {
        'height': _n(f['height']),
        'color': bg,
        'child': _call('Row', 4, {
          'children': _raw([
            for (var k = 0; k < items.length; k++)
              'Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _index = $k), child: Center(child: Text(${lb(items[k])}, style: TextStyle(color: _index == $k ? $sel : Colors.grey, fontWeight: _index == $k ? FontWeight.bold : FontWeight.normal)))))'
          ], 5),
        }),
      });
    case 'lib_curved':
      return _call('CurvedNavigationBar', 3, {
        'index': '_index',
        'height': '60.0',
        'backgroundColor': 'Colors.transparent',
        'color': bg,
        'buttonBackgroundColor': sel,
        'animationDuration': 'const Duration(milliseconds: 300)',
        'items': _raw([for (final n in items) 'Icon(${ic(n)})'], 4),
        'onTap': set,
      });
    case 'lib_gnav':
      return _call('Container', 3, {
        'color': bg,
        'padding': 'const EdgeInsets.symmetric(horizontal: 12, vertical: 8)',
        'child': _call('GNav', 4, {
          'gap': '8.0',
          'color': 'Colors.grey',
          'activeColor': sel,
          'tabBackgroundColor': '$sel.withValues(alpha: 0.15)',
          'padding': 'const EdgeInsets.all(12)',
          'selectedIndex': '_index',
          'onTabChange': set,
          'tabs': _raw([for (final n in items) 'GButton(icon: ${ic(n)}, text: ${lb(n)})'], 5),
        }),
      });
  }
  return null;
}

String _appBarCode(PageModel p) {
  final a = p.appBar.props;
  final h = _n(a['height'] ?? 56.0);
  if (a['variant'] == 'custom') {
    return _call('AppBar', 3, {
      'automaticallyImplyLeading': 'false',
      'toolbarHeight': h,
      'titleSpacing': '12.0',
      'backgroundColor': _col(a['bg']),
      'foregroundColor': _col(a['fg']),
      'title': _call('Row', 4, {
        'mainAxisAlignment': 'MainAxisAlignment.${a['main'] ?? 'spaceBetween'}',
        'children': _list(p.appBar.children, 5, flex: true),
      }),
    });
  }
  return _call('AppBar', 3, {
    'toolbarHeight': h,
    'title': 'Text(${_s(a['title'])})',
    'backgroundColor': _col(a['bg']),
    'foregroundColor': _col(a['fg']),
    'actions': _list(p.appBar.children, 4),
  });
}

bool _has(WidgetNode n, String t) => n.type == t || n.children.any((c) => _has(c, t));
bool _hasSvg(PageModel p) => [p.appBar, p.body, p.footer].any((r) => _has(r, 'svg'));

String generatePage(PageModel p, String cls) {
  final a = p.appBar.props;
  final footer = _footerCode(p);
  final nav = _isNav(p);
  final imp = _variantOf(p)?.importLine;
  final scaffold = _call('Scaffold', 2, {
    if (a['hidden'] != true) 'appBar': _appBarCode(p),
    'body': _call('SafeArea', 3, {
      'child': _call('SingleChildScrollView', 4, {
        'child': _call('SizedBox', 5, {
          'width': 'double.infinity',
          'child': gen(p.body, 6),
        }),
      }),
    }),
    if (footer != null) 'bottomNavigationBar': footer,
  });

  final imps = [
    if (imp != null) imp,
    if (_hasSvg(p)) "import 'package:flutter_svg/flutter_svg.dart';",
  ];
  final head = "import 'package:flutter/material.dart';${imps.map((e) => '\n$e').join()}\n\n/// Generated by Page Builder\n";
  if (!nav) {
    return '''${head}class $cls extends StatelessWidget {
  const $cls({super.key});

  @override
  Widget build(BuildContext context) {
    return $scaffold;
  }
}
''';
  }
  return '''${head}class $cls extends StatefulWidget {
  const $cls({super.key});

  @override
  State<$cls> createState() => _${cls}State();
}

class _${cls}State extends State<$cls> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return $scaffold;
  }
}
''';
}

/// نمای عمومی تولید کد؛ لایه‌های بالاتر فقط از همین کلاس استفاده می‌کنند.
class DartCodeGenerator {
  const DartCodeGenerator();

  /// کد کامل یک صفحه (فایل .dart)
  String page(PageModel p, String className) => generatePage(p, className);

  /// کد یک ویجت تکی (برای نمایشگاه ویجت‌ها)
  String snippet(WidgetNode n) => gen(n, 0);

  String suggestClassName(PageModel p) => defaultClassName(p);
  String fileName(String className) => fileNameOf(className);

  /// خطوط pubspec که این صفحه نیاز دارد
  List<String> dependencies(PageModel p) => requiredDeps(p);
}
