import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «button»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • kind: filled (پر) / outlined (فقط بردر) / text (فقط متن)
///  • text: متن دکمه
///  • bg: رنگ پس‌زمینه (filled)
///  • fg: رنگ متن و بردر
///  • radius: گردی گوشه
///  • elevation: سایه
///  • bold: متن بولد
///  • navTo: شناسه‌ی صفحه‌ای که با کلیک باز می‌شود (خالی = بدون ناوبری؛ اگر پر باشد به‌جای action اجرا می‌شود)
///  • navValue: مقداری که به آن صفحه فرستاده می‌شود؛ می‌تواند متن ثابت یا binding باشد:
///      {{field.name}} = متن یک فیلد متنی | {{item.id}} = ردیف لیست داده‌ای (داخل آیتم)
///  • action: نام متدی که در کنترلر صفحه ساخته می‌شود و با کلیک دکمه صدا زده می‌شود (خالی = بدون متد)
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final buttonDef = WidgetDef('button', 'دکمه',
    defaults: {
      'variant': 'filled', 'text': 'دکمه', 'kind': 'filled', 'bg': 0xFF3F51B5,
      'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': false, 'action': '', 'navTo': '', 'navValue': ''
    },
    fields: [
      PropField('text', 'متن', PropType.text),
      PropField('action', 'نام متد در کنترلر (انگلیسی)', PropType.text),
      PropField('navTo', 'رفتن به صفحه', PropType.page),
      PropField('navValue', 'مقدار ارسالی به صفحه (مثلاً {{field.q}} یا {{item.id}})', PropType.text),
      PropField('kind', 'نوع', PropType.option, options: ['filled', 'outlined', 'text']),
      PropField('bg', 'رنگ پس‌زمینه', PropType.color),
      PropField('fg', 'رنگ متن/بردر', PropType.color),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('elevation', 'سایه', PropType.number),
      PropField('bold', 'متن بولد', PropType.boolean),
    ],
    variants: [
      Variant('filled', 'ساده (پر)', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': false}),
      Variant('outlined', 'فقط بردر', {'kind': 'outlined', 'fg': 0xFF3F51B5, 'radius': 8.0, 'elevation': 0.0, 'bold': false}),
      Variant('rounded', 'گوشه گرد', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 30.0, 'elevation': 2.0, 'bold': false}),
      Variant('shadow', 'سایه‌دار', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 12.0, 'bold': false}),
      Variant('bold', 'متن بولد', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': true}),
      Variant('text', 'فقط متن', {'kind': 'text', 'fg': 0xFF3F51B5, 'radius': 8.0, 'elevation': 0.0, 'bold': false}),
    ]);
