import '../widget_def.dart';
import '../prop_field.dart';
import '../catalog_constants.dart';

/// تعریف ویجت «textField» (فیلد متن ساده و قابل‌شخصی‌سازی)
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • border: none (بدون خط و کادر) / underline (فقط خط زیرین) / outline (کادر دور)
///  • borderColor / borderWidth: رنگ و ضخامت بردر
///  • radius: گردی گوشه‌ی کادر (فقط outline)
///  • showHint + hint: نمایش و متن هینت (متن راهنمای داخل فیلد)
///  • showLabel + label: نمایش و متن لیبل (عنوان کوچک بالای فیلد)
///  • filled + bg: پس‌زمینه‌ی رنگی روشن/خاموش و رنگ آن
///  • fg / size: رنگ و اندازه‌ی متن
///  • padding: فاصله‌ی داخلی
///  • maxLines: تعداد خط‌ها (۱ = تک‌خطی)
///  • keyboard: text / number / email / phone
///  • obscure: مخفی کردن متن (رمز عبور)
///  • name: نام متغیر در کنترلر صفحه (انگلیسی؛ خالی = نام خودکار)؛ در خروجی پروژه یک TextEditingController می‌سازد
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final textFieldDef = WidgetDef('textField', 'فیلد متن',
    defaults: {
      'variant': 'simple',
      'hint': 'متن را وارد کنید', 'label': 'عنوان', 'showHint': true, 'showLabel': false,
      'border': 'none', 'borderColor': 0xFF9E9E9E, 'borderWidth': 1.0, 'radius': 8.0,
      'filled': false, 'bg': 0xFFF5F5F5, 'fg': 0xFF000000, 'size': 16.0, 'padding': 12.0,
      'maxLines': 1.0, 'keyboard': 'text', 'obscure': false, 'name': '',
    },
    fields: [
      PropField('hint', 'متن هینت (Hint)', PropType.text),
      PropField('label', 'متن لیبل (Label)', PropType.text),
      PropField('name', 'نام متغیر در کنترلر (انگلیسی)', PropType.text),
      PropField('fg', 'رنگ متن', PropType.color),
      PropField('bg', 'رنگ پس‌زمینه', PropType.color),
      PropField('borderColor', 'رنگ بردر', PropType.color),
      PropField('size', 'اندازه متن', PropType.number),
      PropField('padding', 'پدینگ', PropType.number),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('borderWidth', 'ضخامت بردر', PropType.number),
      PropField('maxLines', 'تعداد خط', PropType.number),
      PropField('border', 'بردر (خط / کادر)', PropType.option, options: ['none', 'underline', 'outline']),
      PropField('keyboard', 'کیبورد', PropType.option, options: ['text', 'number', 'email', 'phone']),
      PropField('showHint', 'نمایش هینت', PropType.boolean),
      PropField('showLabel', 'نمایش لیبل', PropType.boolean),
      PropField('filled', 'پس‌زمینه رنگی', PropType.boolean),
      PropField('obscure', 'رمز (مخفی)', PropType.boolean),
    ],
    variants: [
      Variant('simple', 'ساده (بدون خط و کادر)', {'border': 'none', 'filled': false, 'showLabel': false, 'showHint': true, 'obscure': false, 'radius': 8.0}),
      Variant('underline', 'فقط خط زیرین', {'border': 'underline', 'filled': false, 'showLabel': false, 'showHint': true, 'obscure': false, 'radius': 8.0}),
      Variant('outlined', 'کادر دور', {'border': 'outline', 'filled': false, 'showLabel': false, 'showHint': true, 'obscure': false, 'radius': 8.0}),
      Variant('filled', 'با پس‌زمینه رنگی', {'border': 'none', 'filled': true, 'showLabel': false, 'showHint': true, 'obscure': false, 'radius': 8.0}),
      Variant('labeled', 'کادر + لیبل', {'border': 'outline', 'filled': false, 'showLabel': true, 'showHint': false, 'obscure': false, 'radius': 8.0}),
      Variant('password', 'رمز عبور', {'border': 'outline', 'filled': false, 'showLabel': true, 'showHint': false, 'obscure': true, 'radius': 8.0, 'label': 'رمز عبور'}),
    ]);
