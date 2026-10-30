import '../entities/page_model.dart';
import '../entities/widget_node.dart';
import '../catalog/widget_catalog.dart';
import '../catalog/widget_def.dart';

/// جستجو در درخت ویجت‌های یک صفحه (توابع خالص)
class PageTree {
  PageTree._();

  static Iterable<WidgetNode> _walk(WidgetNode n) sync* {
    yield n;
    for (final c in n.children) {
      yield* _walk(c);
    }
  }

  static Iterable<WidgetNode> all(PageModel p) => [p.appBar, p.body, p.footer].expand(_walk);
  static WidgetNode? find(PageModel p, String id) => all(p).where((n) => n.id == id).firstOrNull;
  static WidgetNode? parentOf(PageModel p, String id) =>
      all(p).where((n) => n.children.any((c) => c.id == id)).firstOrNull;
}

/// افزودن گره: اگر کانتینر انتخاب باشد داخلش، وگرنه کنار ویجت انتخابی، وگرنه داخل body
class InsertNode {
  const InsertNode();

  void call(PageModel p, WidgetNode? selected, WidgetNode node) {
    var target = p.body;
    int? index;
    if (selected != null) {
      if (WidgetCatalog.of(selected.type).container) {
        target = selected;
      } else {
        final parent = PageTree.parentOf(p, selected.id);
        if (parent != null) {
          target = parent;
          index = parent.children.indexOf(selected) + 1;
        }
      }
    }
    if (index == null) {
      target.children.add(node);
    } else {
      target.children.insert(index, node);
    }
  }
}

/// ویجت عادی حذف می‌شود؛ اپ‌بار و فوتر «پنهان» می‌شوند؛ بدنه حذف‌شدنی نیست.
/// خروجی: آیا تغییری رخ داد؟
class RemoveNode {
  const RemoveNode();

  bool call(PageModel p, WidgetNode node) {
    if (node.id == p.appBar.id || node.id == p.footer.id) {
      node.props['hidden'] = true;
      return true;
    }
    final parent = PageTree.parentOf(p, node.id);
    if (parent == null) return false;
    parent.children.remove(node);
    return true;
  }
}

class RestoreSection {
  const RestoreSection();

  WidgetNode call(PageModel p, String type) {
    final n = type == 'appBar' ? p.appBar : p.footer;
    n.props['hidden'] = false;
    return n;
  }
}

class MoveNode {
  const MoveNode();

  bool call(PageModel p, WidgetNode node, int delta) {
    final list = PageTree.parentOf(p, node.id)?.children;
    if (list == null) return false;
    final i = list.indexOf(node);
    final j = i + delta;
    if (j < 0 || j >= list.length) return false;
    list.removeAt(i);
    list.insert(j, node);
    return true;
  }
}

/// اعمال نمونه‌ی آماده؛ برای فوتر ناوبری و اپ‌بار آزاد، آیتم‌های اولیه می‌سازد
class ApplyVariant {
  const ApplyVariant();

  void call(WidgetNode n, Variant v) {
    n.props
      ..['variant'] = v.id
      ..addAll(v.props);

    if (n.type == 'footer' && v.id != 'bar' && !n.children.any((k) => k.type == 'navItem')) {
      for (final e in const [('home', 'خانه'), ('search', 'جستجو'), ('person', 'پروفایل')]) {
        final it = WidgetCatalog.create('navItem');
        it.props['icon'] = e.$1;
        it.props['label'] = e.$2;
        n.children.add(it);
      }
    }
    if (n.type == 'appBar' && v.id == 'custom' && n.children.isEmpty) {
      final t = WidgetCatalog.create('text');
      t.props['text'] = '${n.props['title'] ?? 'عنوان'}';
      t.props['color'] = 0xFFFFFFFF;
      t.props['bold'] = true;
      t.props['size'] = 20.0;
      t.props['flex'] = 1.0;
      final ic = WidgetCatalog.create('icon');
      ic.props['icon'] = 'search';
      ic.props['color'] = 0xFFFFFFFF;
      n.children.addAll([t, ic]);
    }
  }
}
