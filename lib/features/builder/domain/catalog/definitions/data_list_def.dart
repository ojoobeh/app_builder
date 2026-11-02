import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «dataList» (لیست داده‌ای)
///
/// فرزندان این ویجت = قالب هر آیتم (مثل یک Column: کارت، متن، عکس، ... هرچه خواستی).
/// به ازای هر ردیف پاسخ سرور، یک نسخه از قالب ساخته می‌شود و داخلش با {{item.xxx}} به داده وصل می‌شوی:
///   Text:  «{{item.title}}»      Image.url:  «{{item.image}}»
/// دکمه‌ی داخل آیتم هم می‌تواند مقدار ردیف را به صفحه‌ی دیگر بفرستد (navValue = {{item.id}}).
///
/// ویژگی‌ها:
///  • spacing: فاصله بین آیتم‌ها
///  • padding: پدینگ دور لیست
///  • emptyText: متن وقتی لیست خالی است
/// لیست از «تنظیمات درخواست صفحه» (dataPath) پر می‌شود.
final dataListDef = WidgetDef('dataList', 'لیست داده‌ای', container: true,
    defaults: {'spacing': 8.0, 'padding': 8.0, 'emptyText': 'موردی یافت نشد'},
    fields: [
      PropField('emptyText', 'متن لیست خالی', PropType.text),
      PropField('spacing', 'فاصله بین آیتم‌ها', PropType.number),
      PropField('padding', 'پدینگ', PropType.number),
    ]);
