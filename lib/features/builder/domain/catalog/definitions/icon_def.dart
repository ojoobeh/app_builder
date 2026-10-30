import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «icon»
final iconDef = WidgetDef('icon', 'آیکن',
    defaults: {'icon': 'star', 'size': 24.0, 'color': 0xFF000000},
    fields: [
      PropField('icon', 'آیکن', PropType.icon),
      PropField('size', 'اندازه', PropType.number),
      PropField('color', 'رنگ', PropType.color),
    ]);
