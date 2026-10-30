import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/builder_controller.dart';
import 'editor_screen.dart';
import 'export_screen.dart';
import 'gallery_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BuilderController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحه‌های من'),
        actions: [
          IconButton(
            tooltip: 'کتابخانه‌ی من',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => Get.to(() => const LibraryScreen()),
          ),
          IconButton(
            tooltip: 'نمایشگاه ویجت‌ها',
            icon: const Icon(Icons.widgets_outlined),
            onPressed: () => Get.to(() => const GalleryScreen()),
          ),
        ],
      ),
      body: Obx(() => c.pages.isEmpty
          ? const Center(child: Text('هنوز صفحه‌ای نساختی. دکمه + را بزن.'))
          : ListView(
              children: [
                for (final p in c.pages)
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(p.name),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'خروجی کد', icon: const Icon(Icons.code), onPressed: () => Get.to(() => ExportScreen(page: p))),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => c.deletePage(p.id)),
                    ]),
                    onTap: () {
                      c.open(p);
                      Get.to(() => const EditorScreen())?.then((_) => c.loadPages());
                    },
                  ),
              ],
            )),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('صفحه جدید'),
        onPressed: () => _newPageDialog(c),
      ),
    );
  }

  void _newPageDialog(BuilderController c) {
    final t = TextEditingController();
    Get.defaultDialog(
      title: 'نام صفحه',
      content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'مثلاً صفحه اصلی فروشگاه')),
      textConfirm: 'ساخت',
      textCancel: 'لغو',
      onConfirm: () async {
        if (t.text.trim().isEmpty) return;
        Get.back();
        await c.createPage(t.text.trim());
        Get.to(() => const EditorScreen())?.then((_) => c.loadPages());
      },
    );
  }
}
