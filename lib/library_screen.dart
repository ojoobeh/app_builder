import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled/builder_controller.dart';
import 'package:untitled/registry.dart';
import 'package:untitled/renderer.dart';

/// کتابخانه‌ی قالب‌های کاربر: مشاهده، حذف، کپی همه (JSON) و وارد کردن از کلیپ‌بورد
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BuilderController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('کتابخانه‌ی من'),
        actions: [
          IconButton(
            tooltip: 'کپی همه (JSON)',
            icon: const Icon(Icons.upload),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: c.exportTemplatesJson()));
              Get.snackbar('کپی شد', 'JSON همه‌ی قالب‌ها در کلیپ‌بورد است.');
            },
          ),
          IconButton(tooltip: 'وارد کردن از کلیپ‌بورد', icon: const Icon(Icons.download), onPressed: c.importTemplates),
        ],
      ),
      body: Obx(() => c.templates.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('هنوز قالبی نداری.\nتوی ادیتور یک ویجت را انتخاب کن و آیکن «ذخیره به‌عنوان قالب» را بزن.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(children: [
              for (final t in c.templates)
                ListTile(
                  title: Text('${t.name}  (${Registry.of(t.node.type).label})'),
                  subtitle: templatePreview(t.node),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => c.deleteTemplate(t.id)),
                ),
            ])),
    );
  }
}
