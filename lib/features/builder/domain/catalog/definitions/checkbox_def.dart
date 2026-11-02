import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «checkbox» (چک‌باکس)
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • name: نام متغیر در کنترلر صفحه (انگلیسی؛ خالی = نام خودکار)
///  • value: تیک‌خورده بودن اولیه
///  • filled: true = توپر (داخلش با activeColor پر می‌شود) | false = توخالی (فقط بردر و تیک رنگی)
///  • activeColor / checkColor: رنگ اصلی (پر و بردر) / رنگ تیک در حالت توپر
///  • radius: گردی گوشه‌ی مربع
///  • showLabel + label: نمایش و متن کنار چک‌باکس
///  • fg / labelSize: رنگ و اندازه‌ی متن
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final checkboxDef = WidgetDef('checkbox', 'چک‌باکس',
    defaults: {
      'variant': 'filled', 'name': '', 'value': false, 'filled': true,
      'activeColor': 0xFF3F51B5, 'checkColor': 0xFFFFFFFF, 'radius': 4.0,
      'showLabel': true, 'label': 'گزینه', 'fg': 0xFF000000, 'labelSize': 14.0,
    },
    fields: [
      PropField('name', 'نام متغیر در کنترلر (انگلیسی)', PropType.text),
      PropField('label', 'متن کنار چک‌باکس', PropType.text),
      PropField('activeColor', 'رنگ اصلی', PropType.color),
      PropField('checkColor', 'رنگ تیک (توپر)', PropType.color),
      PropField('fg', 'رنگ متن', PropType.color),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('labelSize', 'اندازه متن', PropType.number),
      PropField('value', 'تیک‌خورده', PropType.boolean),
      PropField('filled', 'توپر', PropType.boolean),
      PropField('showLabel', 'نمایش متن', PropType.boolean),
    ],
    variants: [
      Variant('filled', 'توپر', {'filled': true, 'radius': 4.0}),
      Variant('outlined', 'توخالی (فقط بردر)', {'filled': false, 'radius': 4.0}),
      Variant('round', 'گرد توپر', {'filled': true, 'radius': 12.0}),
    ]);
