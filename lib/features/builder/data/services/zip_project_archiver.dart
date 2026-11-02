import 'dart:convert';
import 'package:archive/archive.dart';
import '../../domain/services/project_archiver.dart';

/// ساخت zip با پکیج archive
class ZipProjectArchiver implements ProjectArchiver {
  @override
  Future<List<int>> zip(Map<String, String> files, {String rootFolder = ''}) async {
    final archive = Archive();
    files.forEach((path, content) {
      final bytes = utf8.encode(content);
      final name = rootFolder.isEmpty ? path : '$rootFolder/$path';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw StateError('ساخت فایل zip ناموفق بود.');
    return encoded;
  }
}
