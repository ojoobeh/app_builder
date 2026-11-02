/// کلمه‌های رزروشده‌ی دارت و نام‌هایی که با اعضای کلاس تداخل دارند
const Set<String> _kReservedNames = {
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'covariant', 'default', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
  'external', 'factory', 'false', 'final', 'finally', 'for', 'get', 'hide', 'if', 'implements', 'import',
  'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'null', 'on', 'operator', 'part', 'required',
  'rethrow', 'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try',
  'typedef', 'var', 'void', 'while', 'with', 'yield',
  'hashCode', 'runtimeType', 'toString', 'toJson', 'copyWith', 'noSuchMethod',
};

/// نام کلاس‌هایی که نباید برای مدل استفاده شوند
const Set<String> kReservedModelNames = {
  'String', 'Int', 'Double', 'Bool', 'Num', 'List', 'Map', 'Set', 'Object', 'DateTime', 'Dynamic', 'Null',
  'Function', 'Future', 'Stream', 'Iterable', 'Type', 'Never', 'Duration', 'Uri', 'Symbol', 'Enum', 'Record',
  'Exception', 'Error', 'Comparable', 'Pattern', 'RegExp', 'Runes', 'StringBuffer',
};

List<String> _asciiWords(String text) =>
    text.split(RegExp(r'[^A-Za-z0-9]+')).where((word) => word.isNotEmpty).toList();

bool _isAllUpper(String word) => word == word.toUpperCase() && word != word.toLowerCase();

/// نام پراپرتی دارت از روی key؛ first_name → firstName ، ID → id ، class → classValue
/// اگر key هیچ حرف/عدد انگلیسی نداشته باشد null برمی‌گرداند.
String? fieldDartName(String key) {
  final words = _asciiWords(key);
  if (words.isEmpty) return null;
  final first = words.first;
  final head = _isAllUpper(first) ? first.toLowerCase() : first[0].toLowerCase() + first.substring(1);
  final tail = words.skip(1).map((word) {
    final rest = _isAllUpper(word) ? word.substring(1).toLowerCase() : word.substring(1);
    return word[0].toUpperCase() + rest;
  }).join();
  var name = head + tail;
  if (RegExp(r'^[0-9]').hasMatch(name)) name = 'f$name';
  if (_kReservedNames.contains(name)) name = '${name}Value';
  return name;
}

/// نام فایل از روی نام مدل: UserProfile → user_profile
String modelFileName(String modelName) => modelName
    .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (match) => '_${match.group(1)}')
    .toLowerCase();
