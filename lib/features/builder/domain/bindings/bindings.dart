// موتور «اتصال داده» (Binding): متن‌هایی مثل  {{item.title}}  یا  {{args}}  یا  {{data.name}}
// این فایل فقط دارت خالص است (بدون Flutter) و هم در پیش‌نمایش و هم در تولید کد استفاده می‌شود.
//
// دامنه‌های قابل استفاده در متن:
//   {{item.xxx}}   یک ردیف از لیست داده‌ای (فقط داخل ویجت «لیست داده‌ای»)
//   {{data.xxx}}   کل پاسخ سرور برای همین صفحه
//   {{args}}       مقداری که صفحه‌ی قبلی با دکمه فرستاده است (args.xxx اگر Map باشد)
//   {{field.name}} متن واردشده در فیلد متنی‌ای که «نام متغیر»ش name است

/// الگوی یک binding
final RegExp kBindingPattern = RegExp(r'\{\{\s*([A-Za-z_][A-Za-z0-9_.]*)\s*\}\}');

/// آیا متن binding دارد؟
bool hasBinding(dynamic text) => text is String && kBindingPattern.hasMatch(text);

/// مسیر «a.b.0.c» را داخل Map/List دنبال می‌کند؛ اگر نبود null.
/// مسیر خالی یعنی خود ریشه.
dynamic jsonPath(dynamic root, String path) {
  if (path.isEmpty) return root;
  dynamic current = root;
  for (final part in path.split('.')) {
    if (current is Map) {
      current = current[part];
    } else if (current is List) {
      final index = int.tryParse(part);
      current = (index != null && index >= 0 && index < current.length) ? current[index] : null;
    } else {
      return null;
    }
  }
  return current;
}

/// bindingهای متن را با مقدارهای [scope] جایگزین می‌کند (مقدار پیدا نشد = رشته‌ی خالی).
/// [scope] مثلاً {'item': {...}, 'data': {...}, 'args': '5', 'field': {'q': 'متن'}}
String resolveBindings(String text, Map<String, dynamic> scope) =>
    text.replaceAllMapped(kBindingPattern, (match) {
      final value = jsonPath(scope, match.group(1)!);
      return value == null ? '' : '$value';
    });

/// اسم فیلد متنی (props.name) به‌صورت شناسه‌ی camelCase انگلیسی؛ در پیش‌نمایش و کنترلر یکسان است.
String fieldKeyOf(dynamic rawName) {
  final words = '${rawName ?? ''}'.split(RegExp(r'[^A-Za-z0-9]+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return 'field';
  final camel = words.first[0].toLowerCase() +
      words.first.substring(1) +
      words.skip(1).map((word) => word[0].toUpperCase() + word.substring(1)).join();
  return RegExp(r'^[a-z]').hasMatch(camel) ? camel : 'field';
}

/// متنی که در فایل json_path.dart پروژه‌ی خروجی نوشته می‌شود (همان jsonPath بالا)
const String kJsonPathFileSource = '''/// مسیر «a.b.0.c» را داخل Map/List دنبال می‌کند؛ اگر نبود null (مسیر خالی = خود ریشه).
dynamic jsonPath(dynamic root, String path) {
  if (path.isEmpty) return root;
  dynamic current = root;
  for (final part in path.split('.')) {
    if (current is Map) {
      current = current[part];
    } else if (current is List) {
      final index = int.tryParse(part);
      current = (index != null && index >= 0 && index < current.length) ? current[index] : null;
    } else {
      return null;
    }
  }
  return current;
}
''';
