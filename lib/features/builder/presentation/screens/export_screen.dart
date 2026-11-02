import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/page_model.dart';
import '../../domain/codegen/dart_code_generator.dart';

/// صفحه‌ی خروجی: کد دارت یک صفحه را نشان می‌دهد و امکان کپی یا ارسال به‌صورت فایل می‌دهد.
class ExportScreen extends StatefulWidget {
  /// صفحه‌ای که خروجی‌اش را می‌خواهیم
  final PageModel page;
  const ExportScreen({super.key, required this.page});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  /// سرویس تولید کد دارت (از DI می‌آید)
  late final _generator = Get.find<DartCodeGenerator>();

  /// فیلد ویرایش نام کلاس؛ با نام پیشنهادی شروع می‌شود
  late final TextEditingController _classNameController =
      TextEditingController(text: _generator.suggestClassName(widget.page));

  /// نام کلاس معتبر: اگر کاربر چیز نامعتبری نوشت (فارسی، با عدد شروع‌شونده و ...) نام پیشنهادی استفاده می‌شود
  String get _className {
    final typedName = _classNameController.text.trim();
    return RegExp(r'^[A-Z][A-Za-z0-9_]*$').hasMatch(typedName)
        ? typedName
        : _generator.suggestClassName(widget.page);
  }

  /// متن کامل فایل دارت
  String get _code => _generator.page(widget.page, _className);

  /// نام فایل (مثلاً home_page.dart)
  String get _fileName => _generator.fileName(_className);

  /// پکیج‌هایی که باید در pubspec پروژه‌ی بیس اضافه شود
  List<String> get _dependencies => _generator.dependencies(widget.page);

  /// کد را در کلیپ‌بورد کپی می‌کند
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _code));
    Get.snackbar('کپی شد', 'کد در کلیپ‌بورد است. در پروژه فایل $_fileName را بساز و پیست کن.');
  }

  /// کد را در یک فایل موقت می‌نویسد و منوی اشتراک‌گذاری گوشی را باز می‌کند
  Future<void> _shareAsFile() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsString(_code);
    await Share.shareXFiles([XFile(file.path)], text: _fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('خروجی: ${widget.page.name}'),
        actions: [
          IconButton(tooltip: 'کپی', icon: const Icon(Icons.copy), onPressed: _copyToClipboard),
          IconButton(tooltip: 'ارسال فایل', icon: const Icon(Icons.share), onPressed: _shareAsFile),
        ],
      ),
      body: Column(children: [
        // ویرایش نام کلاس (نام فایل زیرش نمایش داده می‌شود)
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _classNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'نام کلاس (انگلیسی، با حرف بزرگ شروع شود)',
              helperText: 'نام فایل: $_fileName',
            ),
          ),
        ),
        // یادآوری پکیج‌های لازم (فقط اگر صفحه از کتابخانه استفاده کرده)
        if (_dependencies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SelectableText(
              'این صفحه کتابخانه لازم دارد. در pubspec پروژه‌ی بیس اضافه کن:\n${_dependencies.join('\n')}',
            ),
          ),
        // نمایش کد (قابل انتخاب و اسکرول افقی/عمودی)
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(_code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
