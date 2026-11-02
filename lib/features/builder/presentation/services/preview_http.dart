import 'dart:convert';
import 'dart:io';
import '../../domain/entities/page_request.dart';

/// درخواست صفحه را برای «اجرای آزمایشی» داخل خود برنامه می‌فرستد و پاسخ JSON را برمی‌گرداند.
/// (کد خروجی پروژه از پکیج http و repository استفاده می‌کند؛ این فقط برای تست داخل سازنده است.)
///
/// [value] همان مقداری است که صفحه‌ی قبلی فرستاده؛ جای {value} در آدرس، پارامترها و هدرها می‌نشیند.
/// پارامترها بسته به [PageRequest.paramsInBody] در کوئری یا بدنه‌ی JSON فرستاده می‌شوند.
Future<dynamic> sendPageRequest(PageRequest request, String? value) async {
  final raw = value ?? '';
  String fill(String text) => text.replaceAll('{value}', raw);

  var uri = Uri.parse(request.url.trim().replaceAll('{value}', Uri.encodeComponent(raw)));
  final params = {
    for (final pair in request.params)
      if (pair.key.trim().isNotEmpty) pair.key.trim(): fill(pair.value),
  };
  final inBody = request.paramsInBody;
  if (!inBody && params.isNotEmpty) {
    uri = uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final httpRequest = await client.openUrl(request.method, uri);
    httpRequest.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (inBody && params.isNotEmpty) httpRequest.headers.contentType = ContentType.json;
    for (final pair in request.headers) {
      if (pair.key.trim().isNotEmpty) httpRequest.headers.set(pair.key.trim(), fill(pair.value));
    }
    if (inBody && params.isNotEmpty) httpRequest.add(utf8.encode(jsonEncode(params)));
    final response = await httpRequest.close().timeout(const Duration(seconds: 20));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    return body.trim().isEmpty ? null : jsonDecode(body);
  } finally {
    client.close();
  }
}
