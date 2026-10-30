import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/builder_controller.dart';
import 'node.dart';
import 'registry.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

double _d(dynamic v, [double def = 0]) => v is num ? v.toDouble() : def;
double? _o(dynamic v) => _d(v) <= 0 ? null : _d(v);
Color _c(dynamic v, [Color def = Colors.black]) => v is int ? Color(v) : def;
MainAxisAlignment _main(dynamic s) =>
    MainAxisAlignment.values.firstWhere((e) => e.name == s, orElse: () => MainAxisAlignment.start);
CrossAxisAlignment _cross(dynamic s) =>
    CrossAxisAlignment.values.firstWhere((e) => e.name == s, orElse: () => CrossAxisAlignment.start);
Alignment _align(dynamic s) =>
    const {
      'topLeft': Alignment.topLeft, 'topCenter': Alignment.topCenter, 'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft, 'center': Alignment.center, 'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft, 'bottomCenter': Alignment.bottomCenter, 'bottomRight': Alignment.bottomRight,
    }[s] ??
    Alignment.center;

Widget _hint(String label) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );

Widget _selectable(WidgetNode n, Widget w) {
  final c = Get.find<BuilderController>();
  final sel = c.selectedId.value == n.id;
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => c.select(n.id),
    child: Container(
      foregroundDecoration: BoxDecoration(border: sel ? Border.all(color: Colors.blue, width: 2) : null),
      child: w,
    ),
  );
}

/// تبدیل Node به ویجت واقعی فلاتر. edit=true یعنی حالت ویرایش (قابل انتخاب).
Widget renderNode(WidgetNode n, {bool edit = true, bool flexOk = false}) {
  final p = n.props;
  if (p['hidden'] == true) return const SizedBox.shrink(); // اپ‌بار/فوتر حذف‌شده
  final def = Registry.of(n.type);
  final kids = n.children.map((k) => renderNode(k, edit: edit, flexOk: n.type == 'row' || n.type == 'footer' || (n.type == 'appBar' && p['variant'] == 'custom'))).toList();
  final shown = (kids.isEmpty && edit) ? [_hint(def.label)] : kids;
  Widget w;

  switch (n.type) {
    case 'appBar':
      final custom = p['variant'] == 'custom';
      final bh = _d(p['height'], 56);
      w = SizedBox(
        height: bh,
        child: AppBar(
          primary: false,
          automaticallyImplyLeading: false,
          toolbarHeight: bh,
          centerTitle: false,
          titleSpacing: custom ? 12 : null,
          backgroundColor: _c(p['bg']),
          foregroundColor: _c(p['fg']),
          title: custom ? Row(mainAxisAlignment: _main(p['main']), children: shown) : Text(p['title'] ?? ''),
          actions: custom ? null : kids,
        ),
      );
      break;
    case 'footer':
      w = _footer(n, shown, edit);
      break;
    case 'navItem':
      w = Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(kIcons[p['icon']] ?? Icons.circle),
        Text('${p['label'] ?? ''}', style: const TextStyle(fontSize: 12)),
      ]);
      break;
    case 'column':
      w = Padding(
        padding: EdgeInsets.all(_d(p['padding'])),
        child: Column(
          mainAxisAlignment: _main(p['main']),
          crossAxisAlignment: _cross(p['cross']),
          spacing: _d(p['spacing']),
          children: shown,
        ),
      );
      break;
    case 'row':
      w = Padding(
        padding: EdgeInsets.all(_d(p['padding'])),
        child: Row(
          mainAxisAlignment: _main(p['main']),
          crossAxisAlignment: _cross(p['cross']),
          spacing: _d(p['spacing']),
          children: shown,
        ),
      );
      break;
    case 'stack':
      w = Padding(
        padding: EdgeInsets.all(_d(p['padding'])),
        child: Stack(alignment: _align(p['align']), children: shown),
      );
      break;
    case 'container':
      w = Container(
        width: _o(p['width']),
        height: _o(p['height']),
        padding: EdgeInsets.all(_d(p['padding'])),
        decoration: BoxDecoration(color: _c(p['bg']), borderRadius: BorderRadius.circular(_d(p['radius']))),
        child: shown.length == 1 ? shown.first : Column(mainAxisSize: MainAxisSize.min, children: shown),
      );
      break;
    case 'card':
      final ce = _d(p['elevation']);
      final cbw = _d(p['borderWidth']);
      w = Container(
        margin: EdgeInsets.all(_d(p['margin'])),
        width: _o(p['width']),
        height: _o(p['height']),
        padding: EdgeInsets.all(_d(p['padding'])),
        clipBehavior: p['clip'] == false ? Clip.none : Clip.antiAlias,
        decoration: BoxDecoration(
          color: _c(p['bg'], Colors.white),
          borderRadius: BorderRadius.circular(_d(p['radius'])),
          border: cbw > 0 ? Border.all(color: _c(p['borderColor'], Colors.grey), width: cbw) : null,
          boxShadow: ce > 0
              ? [BoxShadow(color: _c(p['shadowColor'], Colors.black26), blurRadius: ce * 2, offset: Offset(0, ce / 2))]
              : null,
        ),
        child: shown.length == 1 ? shown.first : Column(mainAxisSize: MainAxisSize.min, children: shown),
      );
      break;
    case 'text':
      w = Text(p['text'] ?? '',
          style: TextStyle(
              fontSize: _d(p['size'], 16),
              color: _c(p['color']),
              fontWeight: p['bold'] == true ? FontWeight.bold : FontWeight.normal));
      break;
    case 'textField':
      final tr = BorderRadius.circular(_d(p['radius'], 8));
      final tbc = _c(p['borderColor'], Colors.transparent);
      OutlineInputBorder tob() => OutlineInputBorder(borderRadius: tr, borderSide: BorderSide(color: tbc));
      final field = TextField(
        style: TextStyle(color: _c(p['fg'])),
        decoration: InputDecoration(
          hintText: p['hint'],
          hintStyle: TextStyle(color: _c(p['fg']).withValues(alpha: 0.5)),
          filled: true,
          fillColor: _c(p['bg'], Colors.white),
          isDense: true,
          border: tob(),
          enabledBorder: tob(),
          focusedBorder: tob(),
        ),
      );
      w = LayoutBuilder(builder: (_, cs) => cs.maxWidth.isFinite ? field : SizedBox(width: 200, child: field));
      if (edit) w = IgnorePointer(child: w);
      break;
    case 'svg':
      w = SvgPicture.string('${p['svg'] ?? ''}',
          width: _d(p['size'], 28),
          height: _d(p['size'], 28),
          colorFilter: ColorFilter.mode(_c(p['color']), BlendMode.srcIn));
      break;
    case 'icon':
      w = Icon(kIcons[p['icon']] ?? Icons.help_outline, size: _d(p['size'], 24), color: _c(p['color']));
      break;
    case 'button':
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_d(p['radius'], 8)));
      final fg = _c(p['fg'], Colors.white);
      final label = Text(p['text'] ?? '',
          style: TextStyle(fontWeight: p['bold'] == true ? FontWeight.bold : FontWeight.normal));
      switch (p['kind']) {
        case 'outlined':
          w = OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: fg, shape: shape, side: BorderSide(color: fg, width: 1.5)),
              child: label);
          break;
        case 'text':
          w = TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: fg, shape: shape), child: label);
          break;
        default:
          w = ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: _c(p['bg'], Colors.indigo),
                  foregroundColor: fg,
                  elevation: _d(p['elevation'], 2),
                  shape: shape),
              child: label);
      }
      if (edit) w = IgnorePointer(child: w); // تا کلیک دکمه جلوی انتخاب را نگیرد
      break;
    case 'image':
      final rad = BorderRadius.only(
        topLeft: Radius.circular(_corner(p, 'rTL')),
        topRight: Radius.circular(_corner(p, 'rTR')),
        bottomLeft: Radius.circular(_corner(p, 'rBL')),
        bottomRight: Radius.circular(_corner(p, 'rBR')),
      );
      Widget img(double? iw, double? ih) => Image.network(p['url'] ?? '',
          width: iw,
          height: ih,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              width: iw, height: ih ?? 100, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)));
      final ratio = _o(p['ratio']) ?? 1.78;
      w = ClipRRect(
        borderRadius: rad,
        child: p['mode'] == 'banner'
            ? LayoutBuilder(
                builder: (_, cs) => cs.maxWidth.isFinite
                    ? AspectRatio(aspectRatio: ratio, child: img(double.infinity, double.infinity))
                    : SizedBox(width: 240, height: 240 / ratio, child: img(240, 240 / ratio)))
            : img(_o(p['width']), _o(p['height']) ?? 150),
      );
      break;
    default:
      w = const SizedBox.shrink();
  }
  final out = edit ? _selectable(n, w) : w;
  final fx = p['flex'];
  // Expanded فقط وقتی والد Row/فوتر است (در Column داخل اسکرول خطا می‌دهد)
  return (flexOk && fx is num && fx > 0) ? Expanded(flex: fx.toInt(), child: out) : out;
}

Widget _bar(WidgetNode n, List<Widget> shown) => Container(
      height: _d(n.props['height'], 56),
      color: _c(n.props['bg']),
      child: Row(mainAxisAlignment: _main(n.props['main']), children: shown),
    );

/// فوتر بر اساس variant: نوار ساده یا یکی از مدل‌های ناوبری (آیتم‌ها = فرزندهای navItem)
Widget _footer(WidgetNode n, List<Widget> shown, bool edit) {
  final p = n.props;
  final v = '${p['variant'] ?? 'bar'}';
  final items = n.children.where((k) => k.type == 'navItem').toList();
  if (v == 'bar' || items.length < 2) return _bar(n, shown);

  final c = Get.find<BuilderController>();
  void tap(int i) {
    if (edit) c.select(items[i].id);
  }

  var idx = items.indexWhere((e) => e.id == c.selectedId.value);
  if (idx < 0) idx = 0;
  final sel = _c(p['sel'], Colors.indigo);
  final bg = _c(p['bg'], Colors.white);
  IconData ic(WidgetNode i) => kIcons[i.props['icon']] ?? Icons.circle;
  String lb(WidgetNode i) => '${i.props['label'] ?? ''}';

  switch (v) {
    case 'nav_classic':
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: bg,
        selectedItemColor: sel,
        unselectedItemColor: Colors.grey,
        currentIndex: idx,
        onTap: tap,
        items: [for (final i in items) BottomNavigationBarItem(icon: Icon(ic(i)), label: lb(i))],
      );
    case 'nav_m3':
      return NavigationBar(
        backgroundColor: bg,
        indicatorColor: sel.withValues(alpha: 0.2),
        selectedIndex: idx,
        onDestinationSelected: tap,
        destinations: [for (final i in items) NavigationDestination(icon: Icon(ic(i)), label: lb(i))],
      );
    case 'nav_text':
      return Container(
        height: _d(p['height'], 56),
        color: bg,
        child: Row(children: [
          for (var k = 0; k < items.length; k++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => tap(k),
                child: Center(
                  child: Text(lb(items[k]),
                      style: TextStyle(
                          color: idx == k ? sel : Colors.grey,
                          fontWeight: idx == k ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            ),
        ]),
      );
    case 'lib_curved':
      return CurvedNavigationBar(
        index: idx,
        height: 60,
        backgroundColor: Colors.transparent,
        color: bg,
        buttonBackgroundColor: sel,
        animationDuration: const Duration(milliseconds: 300),
        items: [for (final i in items) Icon(ic(i))],
        onTap: tap,
      );
    case 'lib_gnav':
      return Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GNav(
          gap: 8,
          color: Colors.grey,
          activeColor: sel,
          tabBackgroundColor: sel.withValues(alpha: 0.15),
          padding: const EdgeInsets.all(12),
          selectedIndex: idx,
          onTabChange: tap,
          tabs: [for (final i in items) GButton(icon: ic(i), text: lb(i))],
        ),
      );
    default:
      return _bar(n, shown);
  }
}

double _corner(Map<String, dynamic> p, String k) => _d(p[k] ?? p['radius']);

/// پیش‌نمایش کوچک و غیرقابل لمس یک ویجت (برای لیست قالب‌ها)
Widget templatePreview(WidgetNode n) => Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 140),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: IgnorePointer(child: renderNode(n, edit: false)),
        ),
      ),
    );
