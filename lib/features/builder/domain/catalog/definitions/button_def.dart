import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «button»
final buttonDef = WidgetDef('button', 'دکمه',
    defaults: {
      'variant': 'filled', 'text': 'دکمه', 'kind': 'filled', 'bg': 0xFF3F51B5,
      'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': false
    },
    fields: [
      PropField('text', 'متن', PropType.text),
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
