import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/model_def.dart';
import '../controllers/models_controller.dart';
import 'model_editor_screen.dart';

/// فهرست مدل‌های داده‌ی پروژه‌ی باز (مثلاً User و Product)
class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ModelsController>();
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text('مدل‌های ${controller.project.value?.name ?? ''}'))),
      body: Obx(() => controller.models.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('این پروژه هنوز مدلی ندارد.\nبا دکمه‌ی + مدل بساز (مثلاً User با فیلدهای name و age).',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(children: [
              for (final model in controller.models)
                ListTile(
                  leading: const Icon(Icons.data_object),
                  title: Text(model.name),
                  subtitle: Text(_summary(controller, model), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: 'حذف مدل',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(controller, model),
                  ),
                  onTap: () => Get.to(() => ModelEditorScreen(model: model.copy(), isNew: false)),
                ),
            ])),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('مدل جدید'),
        onPressed: () => Get.to(() => ModelEditorScreen(model: controller.newDraft(), isNew: true)),
      ),
    );
  }

  /// خلاصه‌ی فیلدها: name: String، age: int، ...
  String _summary(ModelsController controller, ModelDef model) {
    if (model.fields.isEmpty) return 'بدون فیلد';
    return model.fields
        .map((field) => '${field.key}: ${controller.typeLabel(field.type, nullable: field.nullable)}')
        .join('،  ');
  }

  void _confirmDelete(ModelsController controller, ModelDef model) {
    Get.defaultDialog(
      title: 'حذف مدل',
      middleText: 'مدل «${model.name}» حذف شود؟',
      textConfirm: 'حذف',
      textCancel: 'لغو',
      onConfirm: () async {
        Get.back();
        await controller.delete(model);
      },
    );
  }
}
