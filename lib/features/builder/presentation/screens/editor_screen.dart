import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../controllers/templates_controller.dart';
import '../renderer/node_renderer.dart';
import '../renderer/preview_state.dart';
import 'export_screen.dart';
import 'preview_page_screen.dart';
import '../widgets/editor_panels.dart';

/// صفحه‌ی ادیتور: بوم (اپ‌بار + بدنه + فوتر) و نوار ابزار پایین.
/// پنل‌های افزودن/ویژگی‌ها در widgets/editor_panels.dart هستند.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EditorController>();
    final panels = EditorPanels(Get.find<TemplatesController>());

    return Scaffold(
      // ---------- نوار بالا: نام صفحه + خروجی کد + پیش‌نمایش ----------
      appBar: AppBar(
        title: Text(controller.page.value!.name),
        actions: [
          // جهت صفحه: راست‌چین ⇄ چپ‌چین
          Obx(() {
            controller.tick.value;
            final isRtl = controller.page.value!.direction == 'rtl';
            return IconButton(
              tooltip: isRtl ? 'راست‌چین (برای چپ‌چین بزن)' : 'چپ‌چین (برای راست‌چین بزن)',
              icon: Icon(isRtl ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r),
              onPressed: controller.toggleDirection,
            );
          }),
          // درخواست صفحه: آدرس سرور که هنگام ورود به صفحه صدا زده می‌شود
          IconButton(
            tooltip: 'درخواست صفحه (سرور)',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () => panels.showRequestPanel(controller),
          ),
          // اجرای آزمایشی با ناوبری واقعی بین صفحه‌ها و درخواست سرور
          IconButton(
            tooltip: 'اجرای آزمایشی (ناوبری + سرور)',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _runPage(controller),
          ),
          IconButton(
            tooltip: 'خروجی کد',
            icon: const Icon(Icons.code),
            onPressed: () => Get.to(() => ExportScreen(page: controller.page.value!)),
          ),
          Obx(() => IconButton(
                tooltip: 'پیش‌نمایش',
                icon: Icon(controller.preview.value ? Icons.edit : Icons.visibility),
                onPressed: () {
                  controller.closePanel();
                  PreviewState.reset(); // پیش‌نمایش همیشه از حالت اولیه شروع می‌شود
                  controller.preview.toggle();
                  controller.select(null);
                },
              )),
        ],
      ),

      // ---------- بوم: صفحه‌ی در حال ساخت (+ پنل پایین در صورت باز بودن) ----------
      body: Obx(() {
        // خواندن این دو مقدار باعث می‌شود با هر تغییر، بوم دوباره ساخته شود
        controller.tick.value;
        controller.selectedId.value;

        final isEditing = !controller.preview.value;
        final page = controller.page.value!;
        final renderEnv = RenderEnv(
          edit: isEditing,
          selectedId: controller.selectedId.value,
          onSelect: controller.select,
        );

        return Column(children: [
          // قسمت بالا: اپ‌بار + بدنه‌ی اسکرول‌شونده + فوتر
          Expanded(
            flex: 5, // صفحه (۵ از ۸) — با باز بودن پنل جای بیشتری دارد
            // جهت صفحه (راست‌چین/چپ‌چین) روی کل بوم اعمال می‌شود
            child: Directionality(
              textDirection: page.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
              child: Column(children: [
              renderNode(page.appBar, renderEnv),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => controller.select(page.body.id), // لمس فضای خالی = انتخاب بدنه
                  child: LayoutBuilder(
                    builder: (_, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        // بدنه حداقل به اندازه‌ی صفحه است تا فضای خالی هم قابل‌لمس باشد
                        constraints: BoxConstraints(minHeight: constraints.maxHeight, minWidth: constraints.maxWidth),
                        child: renderNode(page.body, renderEnv),
                      ),
                    ),
                  ),
                ),
              ),
              renderNode(page.footer, renderEnv),
            ]),
            ),
          ),
          // قسمت پایین: پنل افزودن / ویژگی‌ها (فقط وقتی باز است)
          if (controller.panel.value != null) Expanded(flex: 3, child: panels.panelBox(controller)),
        ]);
      }),

      // ---------- نوار ابزار پایین: افزودن، ویژگی‌ها، جابه‌جایی، حذف، قالب ----------
      bottomNavigationBar: Obx(() {
        controller.tick.value;
        final hasSelection = controller.selected != null;
        final isSection = hasSelection && controller.selectedIsRoot; // اپ‌بار، بدنه یا فوتر
        final isBody = hasSelection && controller.selected!.id == controller.page.value!.body.id;

        // در پیش‌نمایش نوار ابزار نیست
        if (controller.preview.value) return const SizedBox.shrink();

        // نوار ابزار کم‌ارتفاع و بدون پدینگ تا فضای بیشتری برای دیدن صفحه باشد
        return BottomAppBar(
          height: 44,
          padding: EdgeInsets.zero,
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact, iconSize: 22),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconButton(
              tooltip: 'افزودن',
              icon: const Icon(Icons.add_circle),
              onPressed: () => panels.showAddPanel(controller),
            ),
            IconButton(
              tooltip: 'ویژگی‌ها',
              icon: const Icon(Icons.tune),
              onPressed: hasSelection ? () => panels.showPropsPanel(controller, controller.selected!) : null,
            ),
            IconButton(
              tooltip: 'بالا',
              icon: const Icon(Icons.arrow_upward),
              onPressed: hasSelection && !isSection ? () => controller.move(-1) : null,
            ),
            IconButton(
              tooltip: 'پایین',
              icon: const Icon(Icons.arrow_downward),
              onPressed: hasSelection && !isSection ? () => controller.move(1) : null,
            ),
            IconButton(
              tooltip: 'حذف', // اپ‌بار و فوتر پنهان می‌شوند؛ بدنه حذف‌شدنی نیست
              icon: const Icon(Icons.delete),
              onPressed: hasSelection && !isBody ? controller.removeSelected : null,
            ),
            IconButton(
              tooltip: 'ذخیره به‌عنوان قالب',
              icon: const Icon(Icons.bookmark_add),
              onPressed: hasSelection && !isSection ? () => panels.showSaveTemplateDialog(controller) : null,
            ),
          ]),
          ),
        );
      }),
    );
  }

  /// صفحه را مثل اپ واقعی اجرا می‌کند. اگر صفحه مقدار ورودی لازم دارد، یک مقدار آزمایشی می‌پرسد.
  void _runPage(EditorController controller) {
    controller.closePanel();
    final page = controller.page.value!;
    PreviewState.reset();
    final request = page.request;
    final needsValue = request.enabled && request.usesValue;
    if (!needsValue) {
      Get.to(() => PreviewPageScreen(page: page));
      return;
    }
    final valueController = TextEditingController();
    Get.defaultDialog(
      title: 'مقدار آزمایشی ورودی',
      content: TextField(
        controller: valueController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'همان چیزی که صفحه‌ی قبلی می‌فرستد',
          helperText: 'در bindingها {{args}} و در درخواست {value}',
        ),
      ),
      textConfirm: 'اجرا',
      textCancel: 'لغو',
      onConfirm: () {
        Get.back();
        Get.to(() => PreviewPageScreen(page: page, args: valueController.text));
      },
    );
  }
}
