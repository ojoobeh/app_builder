import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../controllers/templates_controller.dart';
import '../renderer/node_renderer.dart';

/// کتابخانه‌ی قالب‌های کاربر: مشاهده، حذف، کپی همه (JSON) و وارد کردن از کلیپ‌بورد
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = Get.find<TemplatesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('کتابخانه‌ی من'),
        actions: [
          IconButton(
            tooltip: 'کپی همه (JSON)',
            icon: const Icon(Icons.upload),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: await templates.exportJson()));
              Get.snackbar('کپی شد', 'JSON همه‌ی قالب‌ها در کلیپ‌بورد است.');
            },
          ),
          IconButton(tooltip: 'وارد کردن از کلیپ‌بورد', icon: const Icon(Icons.download), onPressed: () => _importFromClipboard(templates)),
        ],
      ),
      body: Obx(() => templates.items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('هنوز قالبی نداری.\nتوی ادیتور یک ویجت را انتخاب کن و آیکن «ذخیره به‌عنوان قالب» را بزن.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(children: [
              for (final template in templates.items)
                ListTile(
                  title: Text('${template.name}  (${WidgetCatalog.of(template.node.type).label})'),
                  subtitle: templatePreview(template.node), // پیش‌نمایش قالب
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => templates.remove(template.id),
                  ),
                ),
            ])),
    );
  }

  /// JSON موجود در کلیپ‌بورد را به‌عنوان قالب وارد می‌کند
  Future<void> _importFromClipboard(TemplatesController templates) async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      final importedCount = await templates.importJson(clipboard?.text ?? '');
      Get.snackbar('انجام شد', '$importedCount قالب وارد شد.');
    } catch (_) {
      Get.snackbar('خطا', 'محتوای کلیپ‌بورد، JSON معتبر قالب نیست.');
    }
  }
}
