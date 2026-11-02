import '../entities/page_model.dart';
import '../entities/widget_node.dart';
import '../catalog/widget_catalog.dart';
import '../catalog/widget_def.dart';

// کارهای ویرایشِ درخت ویجت‌های یک صفحه. همه خالص‌اند (بدون Flutter و بدون ذخیره‌سازی)؛
// ذخیره و به‌روزرسانی UI کار EditorController است.

/// جستجو در درخت ویجت‌های یک صفحه (توابع خالص)
class PageTree {
  PageTree._();

  /// خود گره و همه‌ی نوه‌هایش را یکی‌یکی برمی‌گرداند
  static Iterable<WidgetNode> _walk(WidgetNode node) sync* {
    yield node;
    for (final child in node.children) {
      yield* _walk(child);
    }
  }

  /// همه‌ی گره‌های صفحه (اپ‌بار + بدنه + فوتر و زیرمجموعه‌هایشان)
  static Iterable<WidgetNode> all(PageModel page) => [page.appBar, page.body, page.footer].expand(_walk);

  /// گره‌ای با این شناسه (یا null)
  static WidgetNode? find(PageModel page, String id) => all(page).where((node) => node.id == id).firstOrNull;

  /// والد گره‌ای با این شناسه (برای اپ‌بار/بدنه/فوتر که والد ندارند null)
  static WidgetNode? parentOf(PageModel page, String id) =>
      all(page).where((node) => node.children.any((child) => child.id == id)).firstOrNull;

  /// نزدیک‌ترین پدر (یا خود گره) از این نوع؛ اگر نبود null
  static WidgetNode? ancestorOfType(PageModel page, WidgetNode node, String type) {
    var current = node;
    while (true) {
      if (current.type == type) return current;
      final parent = parentOf(page, current.id);
      if (parent == null) return null;
      current = parent;
    }
  }
}

/// افزودن گره: اگر کانتینر انتخاب باشد داخلش، وگرنه کنار ویجت انتخابی، وگرنه داخل body
class InsertNode {
  const InsertNode();

  void call(PageModel page, WidgetNode? selectedNode, WidgetNode newNode) {
    var targetParent = page.body; // پیش‌فرض: انتهای بدنه
    int? insertIndex; // null = انتهای فرزندان

    if (selectedNode != null) {
      // تب جدید همیشه کنار تب‌های همان تب‌بندی می‌رود
      if (newNode.type == 'tabItem') {
        final tabsNode = PageTree.ancestorOfType(page, selectedNode, 'tabs');
        if (tabsNode != null) {
          tabsNode.children.add(newNode);
          return;
        }
      }
      // ویجت جدید روی خود تب‌بندی: داخل اولین تب
      if (selectedNode.type == 'tabs' && newNode.type != 'tabItem' && selectedNode.children.isNotEmpty) {
        selectedNode.children.first.children.add(newNode);
        return;
      }
      if (WidgetCatalog.of(selectedNode.type).container) {
        targetParent = selectedNode; // داخل کانتینر انتخاب‌شده
      } else {
        final parent = PageTree.parentOf(page, selectedNode.id);
        if (parent != null) {
          targetParent = parent; // کنار ویجت انتخاب‌شده، درست بعد از آن
          insertIndex = parent.children.indexOf(selectedNode) + 1;
        }
      }
    }

    if (insertIndex == null) {
      targetParent.children.add(newNode);
    } else {
      targetParent.children.insert(insertIndex, newNode);
    }
  }
}

/// ویجت عادی حذف می‌شود؛ اپ‌بار و فوتر «پنهان» می‌شوند؛ بدنه حذف‌شدنی نیست.
/// خروجی: آیا تغییری رخ داد؟
class RemoveNode {
  const RemoveNode();

  bool call(PageModel page, WidgetNode node) {
    // اپ‌بار و فوتر فقط پنهان می‌شوند (محتوایشان می‌ماند تا بشود برگرداند)
    if (node.id == page.appBar.id || node.id == page.footer.id) {
      node.props['hidden'] = true;
      return true;
    }
    final parent = PageTree.parentOf(page, node.id);
    if (parent == null) return false; // بدنه
    parent.children.remove(node);
    return true;
  }
}

/// برگرداندن اپ‌بار یا فوتر پنهان‌شده
class RestoreSection {
  const RestoreSection();

  /// [sectionType] یا 'appBar' است یا 'footer'
  WidgetNode call(PageModel page, String sectionType) {
    final section = sectionType == 'appBar' ? page.appBar : page.footer;
    section.props['hidden'] = false;
    return section;
  }
}

/// جابه‌جایی یک گره بین هم‌نیاهایش. [delta] = ‎-1 بالا / ‎+1 پایین. خروجی: آیا جابه‌جا شد؟
class MoveNode {
  const MoveNode();

  bool call(PageModel page, WidgetNode node, int delta) {
    final siblings = PageTree.parentOf(page, node.id)?.children;
    if (siblings == null) return false;
    final currentIndex = siblings.indexOf(node);
    final newIndex = currentIndex + delta;
    if (newIndex < 0 || newIndex >= siblings.length) return false; // از لبه بیرون نمی‌رود
    siblings.removeAt(currentIndex);
    siblings.insert(newIndex, node);
    return true;
  }
}

/// اعمال نمونه‌ی آماده روی یک گره.
/// برای فوتر ناوبری و اپ‌بار آزاد، اگر فرزندی نباشد آیتم‌های اولیه هم می‌سازد.
class ApplyVariant {
  const ApplyVariant();

  void call(WidgetNode node, Variant variant) {
    // ویژگی‌های نمونه روی گره نوشته می‌شود (و شناسه‌ی نمونه ثبت می‌شود)
    node.props
      ..['variant'] = variant.id
      ..addAll(variant.props);

    // فوتر ناوبری: اگر آیتمی نیست، سه آیتم پیش‌فرض می‌سازیم
    if (node.type == 'footer' && variant.id != 'bar' && !node.children.any((child) => child.type == 'navItem')) {
      const defaultItems = [('home', 'خانه'), ('search', 'جستجو'), ('person', 'پروفایل')];
      for (final (iconKey, label) in defaultItems) {
        final item = WidgetCatalog.create('navItem');
        item.props['icon'] = iconKey;
        item.props['label'] = label;
        node.children.add(item);
      }
    }

    // اپ‌بار آزاد: یک متن (عنوان) و یک آیکن جستجو می‌گذاریم تا Row خالی نباشد
    if (node.type == 'appBar' && variant.id == 'custom' && node.children.isEmpty) {
      final titleText = WidgetCatalog.create('text');
      titleText.props['text'] = '${node.props['title'] ?? 'عنوان'}';
      titleText.props['color'] = 0xFFFFFFFF;
      titleText.props['bold'] = true;
      titleText.props['size'] = 20.0;
      titleText.props['flex'] = 1.0; // بقیه‌ی فضا را می‌گیرد و آیکن را به انتها می‌راند

      final searchIcon = WidgetCatalog.create('icon');
      searchIcon.props['icon'] = 'search';
      searchIcon.props['color'] = 0xFFFFFFFF;

      node.children.addAll([titleText, searchIcon]);
    }
  }
}
