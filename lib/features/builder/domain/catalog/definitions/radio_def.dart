import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «radio» (رادیو باتن)
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • group: نام گروه؛ رادیوهای هم‌گروه فقط یکی‌شان انتخاب می‌شود (انگلیسی؛ خالی = گروه پیش‌فرض)
///  • value: مقدار این گزینه (وقتی انتخاب شد در متغیر گروه ذخیره می‌شود)
///  • selected: انتخاب‌شده بودن اولیه
///  • filled: true = کاملاً توپر | false = حلقه با نقطه‌ی داخل
///  • activeColor: رنگ
///  • size: قطر دایره
///  • showLabel + label: نمایش و متن کنار رادیو
///  • fg / labelSize: رنگ و اندازه‌ی متن
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final radioDef = WidgetDef('radio', 'رادیو باتن',
    defaults: {
      'variant': 'dot', 'group': '', 'value': 'option1', 'selected': false, 'filled': false,
      'activeColor': 0xFF3F51B5, 'size': 22.0, 'showLabel': true, 'label': 'گزینه',
      'fg': 0xFF000000, 'labelSize': 14.0,
    },
    fields: [
      PropField('group', 'نام گروه (انگلیسی)', PropType.text),
      PropField('value', 'مقدار این گزینه', PropType.text),
      PropField('label', 'متن کنار رادیو', PropType.text),
      PropField('activeColor', 'رنگ', PropType.color),
      PropField('fg', 'رنگ متن', PropType.color),
      PropField('size', 'قطر دایره', PropType.number),
      PropField('labelSize', 'اندازه متن', PropType.number),
      PropField('selected', 'انتخاب‌شده', PropType.boolean),
      PropField('filled', 'کاملاً توپر', PropType.boolean),
      PropField('showLabel', 'نمایش متن', PropType.boolean),
    ],
    variants: [
      Variant('dot', 'حلقه با نقطه', {'filled': false}),
      Variant('solid', 'کاملاً توپر', {'filled': true}),
    ]);
