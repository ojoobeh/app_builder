import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/model_def.dart';

/// نتیجه‌ی انتخابگر نوع. type = null یعنی «بدون نوع» انتخاب شده (فقط وقتی allowNone باشد).
class TypePick {
  final FieldType? type;
  const TypePick(this.type);
}

/// دیالوگ انتخاب نوع: نوع پایه یا یکی از مدل‌های پروژه + عمق لیست (List<...>).
/// [models]: مدل‌های قابل انتخاب (شناسه ← نام). خروجی null = انصراف.
Future<TypePick?> pickFieldType({
  required List<MapEntry<String, String>> models,
  FieldType? current,
  bool allowNone = false,
}) {
  String valueOf(FieldType? type) {
    if (type == null) return allowNone ? 'n' : 'p:String';
    final base = type.base;
    if (base.kind == FieldKind.model && models.any((model) => model.key == base.modelId)) return 'm:${base.modelId}';
    return 'p:${base.kind == FieldKind.primitive ? base.primitive : 'dynamic'}';
  }

  var selected = valueOf(current);
  var depth = current?.listDepth ?? 0;

  return Get.dialog<TypePick>(
    StatefulBuilder(builder: (context, refresh) {
      final none = selected == 'n';
      return AlertDialog(
        title: const Text('نوع'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'نوع', isDense: true, border: OutlineInputBorder()),
            items: [
              if (allowNone) const DropdownMenuItem(value: 'n', child: Text('بدون نوع (فقط داده‌ی خام)')),
              for (final name in kPrimitiveTypes)
                DropdownMenuItem(value: 'p:$name', child: Text(name == 'Map' ? 'Map<String, dynamic>' : name)),
              for (final model in models) DropdownMenuItem(value: 'm:${model.key}', child: Text('مدل: ${model.value}')),
            ],
            onChanged: (value) => refresh(() => selected = value ?? selected),
          ),
          if (models.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('این پروژه هنوز مدلی ندارد؛ از آیکن «مدل‌های داده» در صفحه‌ی پروژه مدل بساز.',
                  style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: none ? 0 : depth,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'لیست؟', isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 0, child: Text('خیر (تک‌مقدار)')),
              DropdownMenuItem(value: 1, child: Text('List<...>')),
              DropdownMenuItem(value: 2, child: Text('List<List<...>>')),
            ],
            onChanged: none ? null : (value) => refresh(() => depth = value ?? depth),
          ),
        ]),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('لغو')),
          TextButton(
            onPressed: () {
              if (selected == 'n') {
                Get.back(result: const TypePick(null));
                return;
              }
              final base = selected.startsWith('m:')
                  ? FieldType.model(selected.substring(2))
                  : FieldType.primitive(selected.substring(2));
              Get.back(result: TypePick(FieldType.wrapInLists(base, depth)));
            },
            child: const Text('تأیید'),
          ),
        ],
      );
    }),
  );
}
