import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «textField»
final textFieldDef = WidgetDef('textField', 'فیلد متن',
    defaults: {'hint': 'جستجو...', 'fg': 0xFF000000, 'bg': 0xFFFFFFFF, 'borderColor': 0x00000000, 'radius': 8.0},
    fields: [
      PropField('hint', 'متن راهنما', PropType.text),
      PropField('fg', 'رنگ متن', PropType.color),
      PropField('bg', 'رنگ پس‌زمینه', PropType.color),
      PropField('borderColor', 'رنگ بردر', PropType.color),
      PropField('radius', 'گردی گوشه', PropType.number),
    ]);
