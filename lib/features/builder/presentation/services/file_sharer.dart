import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// یک فایل را در پوشه‌ی موقت می‌نویسد و منوی اشتراک‌گذاری گوشی را باز می‌کند
/// (تلگرام، ایمیل، ذخیره در فایل‌ها و ...).
Future<void> shareBytes(String fileName, List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: fileName);
}
