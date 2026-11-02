import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/entities/project.dart';
import '../controllers/editor_controller.dart';
import '../controllers/models_controller.dart';
import '../controllers/project_detail_controller.dart';
import 'editor_screen.dart';
import 'export_screen.dart';
import 'models_screen.dart';

/// داخل یک پروژه: فهرست صفحه‌ها (مثلاً splash، login، main)، ساخت صفحه‌ی جدید و خروجی zip کل پروژه.
class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = Get.find<ProjectDetailController>();
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(detail.project.value?.name ?? '')),
        actions: [
          // مدل‌های داده‌ی همین پروژه (User، Product، ...)
          IconButton(
            tooltip: 'مدل‌های داده',
            icon: const Icon(Icons.data_object),
            onPressed: () {
              Get.find<ModelsController>().open(detail.project.value!);
              Get.to(() => const ModelsScreen());
            },
          ),
          // خروجی کل پروژه: در حال ساخت یک چرخان، وگرنه دکمه
          Obx(() => detail.isExporting.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  tooltip: 'خروجی کل پروژه (ZIP)',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: detail.exportZip,
                )),
        ],
      ),
      body: Obx(() => detail.pages.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('این پروژه هنوز صفحه‌ای ندارد.\nبا دکمه‌ی + صفحه اضافه کن (مثلاً splash، login، main).',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(children: [
              for (final page in detail.pages)
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(page.name),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'خروجی کد این صفحه',
                      icon: const Icon(Icons.code),
                      onPressed: () => Get.to(() => ExportScreen(page: page)),
                    ),
                    IconButton(
                      tooltip: 'حذف صفحه',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => detail.deletePage(page.id),
                    ),
                  ]),
                  onTap: () => _openEditor(page),
                ),
            ])),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('صفحه جدید'),
        onPressed: () => _newPageDialog(detail),
      ),
    );
  }

  /// صفحه را در ادیتور باز می‌کند؛ با برگشت، فهرست دوباره خوانده می‌شود
  void _openEditor(PageModel page) {
    final Project? project = Get.find<ProjectDetailController>().project.value;
    if (project != null) Get.find<ModelsController>().open(project); // برای پیشنهاد bindingها از روی مدل‌ها
    Get.find<EditorController>().open(page);
    Get.to(() => const EditorScreen())?.then((_) => Get.find<ProjectDetailController>().load());
  }

  /// دیالوگ گرفتن نام و ساخت صفحه‌ی جدید
  void _newPageDialog(ProjectDetailController detail) {
    final nameController = TextEditingController();
    Get.defaultDialog(
      title: 'نام صفحه',
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'مثلاً login',
          helperText: 'نام انگلیسی بهتر است (برای نام فایل‌ها در خروجی)',
        ),
      ),
      textConfirm: 'ساخت',
      textCancel: 'لغو',
      onConfirm: () async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;
        Get.back();
        _openEditor(await detail.createPage(name));
      },
    );
  }
}
