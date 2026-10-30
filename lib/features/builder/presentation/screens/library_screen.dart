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
    final c = Get.find<TemplatesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('کتابخانه‌ی من'),
        actions: [
          IconButton(
            tooltip: 'کپی همه (JSON)',
            icon: const Icon(Icons.upload),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: await c.exportJson()));
              Get.snackbar('کپی شد', 'JSON همه‌ی قالب‌ها در کلیپ‌بورد است.');
            },
          ),
          IconButton(tooltip: 'وارد کردن از کلیپ‌بورد', icon: const Icon(Icons.download), onPressed: () => _import(c)),
        ],
      ),
      body: Obx(() => c.items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('هنوز قالبی نداری.\nتوی ادیتور یک ویجت را انتخاب کن و آیکن «ذخیره به‌عنوان قالب» را بزن.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(children: [
              for (final t in c.items)
                ListTile(
                  title: Text('${t.name}  (${WidgetCatalog.of(t.node.type).label})'),
                  subtitle: templatePreview(t.node),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => c.remove(t.id)),
                ),
            ])),
    );
  }

  Future<void> _import(TemplatesController c) async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      final n = await c.importJson(d?.text ?? '');
      Get.snackbar('انجام شد', '$n قالب وارد شد.');
    } catch (_) {
      Get.snackbar('خطا', 'محتوای کلیپ‌بورد، JSON معتبر قالب نیست.');
    }
  }
}
