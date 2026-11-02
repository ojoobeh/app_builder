import 'package:get/get.dart';

/// وضعیت موقت ویجت‌های تعاملی داخل خود ادیتور (در پیش‌نمایش با لمس عوض می‌شوند).
/// ذخیره نمی‌شود و با باز کردن صفحه یا رفتن به پیش‌نمایش صفر می‌شود.
class PreviewState {
  PreviewState._();

  /// شناسه‌ی چک‌باکس ← تیک‌خورده؟
  static final checks = <String, bool>{}.obs;

  /// نام گروه رادیو ← مقدار انتخاب‌شده
  static final radios = <String, String>{}.obs;

  /// شناسه‌ی ویجت تب‌ها ← شماره‌ی تب فعال
  static final tabs = <String, int>{}.obs;

  /// نام فیلد متنی (props.name) ← متنی که کاربر نوشته است (برای {{field.name}} و ارسال با دکمه)
  static final fields = <String, String>{}.obs;

  /// همه‌ی وضعیت‌ها را پاک می‌کند
  static void reset() {
    checks.clear();
    radios.clear();
    tabs.clear();
    fields.clear();
  }
}
