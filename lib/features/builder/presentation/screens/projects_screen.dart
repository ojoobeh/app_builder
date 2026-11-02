import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/project.dart';
import '../controllers/project_detail_controller.dart';
import '../controllers/projects_controller.dart';
import 'gallery_screen.dart';
import 'library_screen.dart';
import 'project_screen.dart';

/// صفحه‌ی اول برنامه: فهرست پروژه‌ها. لمس هر پروژه، صفحه‌های آن را باز می‌کند.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = Get.find<ProjectsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروژه‌های من'),
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
      body: Obx(() => projects.items.isEmpty
          ? const Center(child: Text('هنوز پروژه‌ای نساختی. دکمه‌ی + را بزن.'))
          : ListView(children: [
              for (final project in projects.items)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(project.name),
                  trailing: IconButton(
                    tooltip: 'حذف پروژه',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(projects, project),
                  ),
                  onTap: () => _openProject(project),
                ),
            ])),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('پروژه جدید'),
        onPressed: () => _newProjectDialog(projects),
      ),
    );
  }

  /// پروژه را باز می‌کند و به صفحه‌ی صفحه‌هایش می‌رود
  void _openProject(Project project) {
    Get.find<ProjectDetailController>().open(project);
    Get.to(() => const ProjectScreen());
  }

  /// دیالوگ گرفتن نام و ساخت پروژه‌ی جدید
  void _newProjectDialog(ProjectsController projects) {
    final nameController = TextEditingController();
    Get.defaultDialog(
      title: 'نام پروژه',
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'مثلاً فروشگاه'),
      ),
      textConfirm: 'ساخت',
      textCancel: 'لغو',
      onConfirm: () async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;
        Get.back();
        _openProject(await projects.create(name));
      },
    );
  }

  /// حذف پروژه همه‌ی صفحه‌هایش را هم پاک می‌کند، پس تأیید می‌گیریم
  void _confirmDelete(ProjectsController projects, Project project) {
    Get.defaultDialog(
      title: 'حذف پروژه',
      middleText: 'پروژه‌ی «${project.name}» و همه‌ی صفحه‌هایش حذف می‌شود. مطمئنی؟',
      textConfirm: 'حذف',
      textCancel: 'لغو',
      onConfirm: () async {
        Get.back();
        await projects.delete(project.id);
      },
    );
  }
}
