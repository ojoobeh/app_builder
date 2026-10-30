import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/code_generator.dart';
import 'package:untitled/node.dart';

class ExportScreen extends StatefulWidget {
  final PageModel page;
  const ExportScreen({super.key, required this.page});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late final TextEditingController _cls = TextEditingController(text: defaultClassName(widget.page));

  String get _className {
    final t = _cls.text.trim();
    return RegExp(r'^[A-Z][A-Za-z0-9_]*$').hasMatch(t) ? t : defaultClassName(widget.page);
  }

  String get _code => generatePage(widget.page, _className);
  String get _file => fileNameOf(_className);
  List<String> get _deps => requiredDeps(widget.page);

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code));
    Get.snackbar('کپی شد', 'کد در کلیپ‌بورد است. در پروژه فایل $_file را بساز و پیست کن.');
  }

  Future<void> _share() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$_file');
    await f.writeAsString(_code);
    await Share.shareXFiles([XFile(f.path)], text: _file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('خروجی: ${widget.page.name}'),
        actions: [
          IconButton(tooltip: 'کپی', icon: const Icon(Icons.copy), onPressed: _copy),
          IconButton(tooltip: 'ارسال فایل', icon: const Icon(Icons.share), onPressed: _share),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _cls,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'نام کلاس (انگلیسی، با حرف بزرگ شروع شود)',
              helperText: 'نام فایل: $_file',
            ),
          ),
        ),
        if (_deps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SelectableText('این صفحه کتابخانه لازم دارد. در pubspec پروژه‌ی بیس اضافه کن:\n${_deps.join('\n')}'),
          ),
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
