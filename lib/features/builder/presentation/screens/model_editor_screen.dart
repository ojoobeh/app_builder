import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/model_def.dart';
import '../../domain/models/model_type_parser.dart';
import '../controllers/models_controller.dart';
import '../widgets/field_type_picker.dart';

/// یک فیلد در حال ویرایش؛ uid باعث می‌شود با حذف یک ردیف، متن ردیف‌های دیگر قاطی نشود
class _DraftField {
  static int _sequence = 0;
  final int uid = _sequence++;
  String key;
  FieldType type;
  bool nullable;
  _DraftField(this.key, this.type, this.nullable);
  factory _DraftField.from(ModelField field) => _DraftField(field.key, field.type, field.nullable);
}

/// ساخت یا ویرایش یک مدل: نام + فیلدها (key و نوع).
/// فیلدها را می‌شود دستی اضافه کرد یا به‌صورت متنی چسباند (key=name,type=String).
class ModelEditorScreen extends StatefulWidget {
  /// کپی مستقل مدل (با «انصراف» چیزی تغییر نمی‌کند)
  final ModelDef model;
  final bool isNew;
  const ModelEditorScreen({super.key, required this.model, required this.isNew});

  @override
  State<ModelEditorScreen> createState() => _ModelEditorScreenState();
}

class _ModelEditorScreenState extends State<ModelEditorScreen> {
  final ModelsController _controller = Get.find<ModelsController>();
  late final TextEditingController _nameController = TextEditingController(text: widget.model.name);
  late final List<_DraftField> _fields = widget.model.fields.map(_DraftField.from).toList();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// نام نمایشی خود مدل (برای مدلِ تازه که هنوز ذخیره نشده)
  String get _selfName => _nameController.text.trim().isEmpty ? 'این مدل' : _nameController.text.trim();

  /// نوع فیلد برای نمایش؛ ارجاع به خود مدل هم (حتی ذخیره‌نشده) درست نوشته می‌شود
  String _typeText(_DraftField field) => describeFieldType(
        field.type,
        (id) => id == widget.model.id ? _selfName : _controller.nameOf(id),
        nullable: false,
      );

  // ---------- ذخیره ----------
  Future<void> _save() async {
    final model = widget.model
      ..name = _nameController.text
      ..fields = [for (final f in _fields) ModelField(key: f.key, type: f.type, nullable: f.nullable)];
    final errors = await _controller.save(model);
    if (errors.isEmpty) {
      Get.back();
    } else {
      Get.defaultDialog(
        title: 'مدل ذخیره نشد',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final error in errors) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $error'))],
        ),
        textConfirm: 'باشه',
        onConfirm: Get.back,
      );
    }
  }

  // ---------- انتخاب نوع ----------
  Future<void> _pickType(_DraftField field) async {
    // مدل‌های پروژه؛ مدل تازه‌ی ذخیره‌نشده هم برای ارجاع به خودش اضافه می‌شود
    final choices = <MapEntry<String, String>>[
      for (final model in _controller.models) MapEntry(model.id, model.name),
      if (!_controller.models.any((model) => model.id == widget.model.id)) MapEntry(widget.model.id, _selfName),
    ];
    final picked = await pickFieldType(models: choices, current: field.type);
    if (picked?.type != null) setState(() => field.type = picked!.type!);
  }

  // ---------- چسباندن متنی ----------
  void _pasteSpecDialog() {
    final textController = TextEditingController();
    Get.defaultDialog(
      title: 'افزودن فیلدها با متن',
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: textController,
          autofocus: true,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'key=name,type=String\nkey=age,type=int\nkey=products,type=List<Product>\nkey=favProduct,type=Product?',
            helperText: 'هر خط یک فیلد. علامت ? یعنی اختیاری (null).',
          ),
        ),
      ),
      textConfirm: 'افزودن',
      textCancel: 'لغو',
      onConfirm: () async {
        // نام خود مدل هم قابل ارجاع است (مثلاً Category که فرزند Category دارد)
        final selfName = _nameController.text.trim();
        final result = await _controller.parseSpec(
          textController.text,
          extraNames: selfName.isEmpty ? const {} : {selfName: widget.model.id},
        );
        if (result.errors.isNotEmpty) {
          Get.snackbar('متن معتبر نیست', result.errors.join('\n'), duration: const Duration(seconds: 6));
          return;
        }
        Get.back();
        setState(() {
          for (final parsed in result.fields) {
            _fields.removeWhere((existing) => existing.key == parsed.key); // key تکراری جایگزین می‌شود
            _fields.add(_DraftField.from(parsed));
          }
        });
      },
    );
  }

  // ---------- ظاهر ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'مدل جدید' : 'ویرایش مدل'),
        actions: [IconButton(tooltip: 'ذخیره', icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'نام مدل',
              hintText: 'مثلاً User',
              helperText: 'انگلیسی و با حرف بزرگ؛ نام کلاس دارت می‌شود',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('فیلدها', style: TextStyle(fontWeight: FontWeight.bold))),
            TextButton.icon(onPressed: _pasteSpecDialog, icon: const Icon(Icons.text_snippet_outlined), label: const Text('با متن')),
            TextButton.icon(
              onPressed: () => setState(() => _fields.add(_DraftField('', const FieldType.primitive('String'), false))),
              icon: const Icon(Icons.add),
              label: const Text('فیلد'),
            ),
          ]),
          if (_fields.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('هنوز فیلدی نیست.'))),
          for (final field in _fields) _fieldCard(field),
        ],
      ),
    );
  }

  Widget _fieldCard(_DraftField field) {
    return Card(
      key: ValueKey(field.uid),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: field.key,
                decoration: const InputDecoration(labelText: 'key', isDense: true, border: OutlineInputBorder()),
                onChanged: (text) => field.key = text,
              ),
            ),
            IconButton(
              tooltip: 'حذف فیلد',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _fields.remove(field)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickType(field),
                child: Text(_typeText(field), overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('اختیاری (null)'),
              selected: field.nullable,
              onSelected: (value) => setState(() => field.nullable = value),
            ),
          ]),
        ]),
      ),
    );
  }
}
