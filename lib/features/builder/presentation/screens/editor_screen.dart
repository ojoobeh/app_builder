import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../controllers/templates_controller.dart';
import '../renderer/node_renderer.dart';
import 'export_screen.dart';
import '../widgets/editor_panels.dart';

/// صفحه‌ی ادیتور: بوم (اپ‌بار + بدنه + فوتر) و نوار ابزار پایین.
/// پنل‌های افزودن/ویژگی‌ها در widgets/editor_panels.dart هستند.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EditorController>();
    final panels = EditorPanels(Get.find<TemplatesController>());
    return Scaffold(
      appBar: AppBar(
        title: Text(c.page.value!.name),
        actions: [
          IconButton(tooltip: 'خروجی کد', icon: const Icon(Icons.code), onPressed: () => Get.to(() => ExportScreen(page: c.page.value!))),
          Obx(() => IconButton(
                tooltip: 'پیش‌نمایش',
                icon: Icon(c.preview.value ? Icons.edit : Icons.visibility),
                onPressed: () {
                  c.closePanel();
                  c.preview.toggle();
                  c.select(null);
                },
              )),
        ],
      ),
      body: Obx(() {
        c.tick.value; // وابستگی برای بازسازی
        c.selectedId.value;
        final edit = !c.preview.value;
        final p = c.page.value!;
        final env = RenderEnv(edit: edit, selectedId: c.selectedId.value, onSelect: c.select);
        return Column(children: [
          Expanded(
            flex: 3,
            child: Column(children: [
              renderNode(p.appBar, env),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => c.select(p.body.id),
                  child: LayoutBuilder(
                    builder: (_, cs) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: cs.maxHeight, minWidth: cs.maxWidth),
                        child: renderNode(p.body, env),
                      ),
                    ),
                  ),
                ),
              ),
              renderNode(p.footer, env),
            ]),
          ),
          if (c.panel.value != null) Expanded(flex: 2, child: panels.panelBox(c)),
        ]);
      }),
      bottomNavigationBar: Obx(() {
        c.tick.value;
        final has = c.selected != null;
        final root = has && c.selectedIsRoot;
        final isBody = has && c.selected!.id == c.page.value!.body.id;
        return c.preview.value
            ? const SizedBox.shrink()
            : BottomAppBar(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  IconButton(tooltip: 'افزودن', icon: const Icon(Icons.add_circle), onPressed: () => panels.showAddPanel(c)),
                  IconButton(tooltip: 'ویژگی‌ها', icon: const Icon(Icons.tune), onPressed: has ? () => panels.showPropsPanel(c, c.selected!) : null),
                  IconButton(tooltip: 'بالا', icon: const Icon(Icons.arrow_upward), onPressed: has && !root ? () => c.move(-1) : null),
                  IconButton(tooltip: 'پایین', icon: const Icon(Icons.arrow_downward), onPressed: has && !root ? () => c.move(1) : null),
                  IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete), onPressed: has && !isBody ? c.removeSelected : null),
                  IconButton(tooltip: 'ذخیره به‌عنوان قالب', icon: const Icon(Icons.bookmark_add), onPressed: has && !root ? () => panels.showSaveTemplateDialog(c) : null),
                ]),
              );
      }),
    );
  }
}
