import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/page_model.dart';
import '../controllers/editor_controller.dart';
import '../controllers/home_controller.dart';
import 'editor_screen.dart';
import 'export_screen.dart';
import 'gallery_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
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
      body: Obx(() => home.pages.isEmpty
          ? const Center(child: Text('هنوز صفحه‌ای نساختی. دکمه + را بزن.'))
          : ListView(
              children: [
                for (final p in home.pages)
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(p.name),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: 'خروجی کد',
                        icon: const Icon(Icons.code),
                        onPressed: () => Get.to(() => ExportScreen(page: p)),
                      ),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => home.delete(p.id)),
                    ]),
                    onTap: () => _openEditor(p),
                  ),
              ],
            )),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('صفحه جدید'),
        onPressed: () => _newPageDialog(home),
      ),
    );
  }

  void _openEditor(PageModel p) {
    Get.find<EditorController>().open(p);
    Get.to(() => const EditorScreen())?.then((_) => Get.find<HomeController>().load());
  }

  void _newPageDialog(HomeController home) {
    final t = TextEditingController();
    Get.defaultDialog(
      title: 'نام صفحه',
      content: TextField(
        controller: t,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'مثلاً صفحه اصلی فروشگاه'),
      ),
      textConfirm: 'ساخت',
      textCancel: 'لغو',
      onConfirm: () async {
        if (t.text.trim().isEmpty) return;
        Get.back();
        _openEditor(await home.create(t.text.trim()));
      },
    );
  }
}
