import '../entities/template.dart';

/// قرارداد ذخیره‌ی قالب‌های کاربر (پیاده‌سازی در لایه‌ی data)
abstract class TemplateRepository {
  Future<List<Template>> getAll();
  Future<void> save(Template template);
  Future<void> delete(String id);

  /// همه‌ی قالب‌ها به‌صورت متن JSON (برای انتقال)
  Future<String> exportJson();

  /// وارد کردن از متن JSON؛ تعداد قالب‌های واردشده را برمی‌گرداند
  Future<int> importJson(String json);
}
