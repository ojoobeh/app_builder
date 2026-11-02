/// قرارداد ساخت فایل zip از مجموعه‌ای فایل متنی (پیاده‌سازی در لایه‌ی data)
abstract class ProjectArchiver {
  /// [files]: مسیر نسبی ← محتوا. [rootFolder]: پوشه‌ی ریشه‌ی داخل zip
  Future<List<int>> zip(Map<String, String> files, {String rootFolder = ''});
}
