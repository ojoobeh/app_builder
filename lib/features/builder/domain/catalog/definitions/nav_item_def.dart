import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «navItem»
final navItemDef = WidgetDef('navItem', 'آیتم ناوبری',
    defaults: {'icon': 'home', 'label': 'خانه'},
    fields: [
      PropField('icon', 'آیکن', PropType.icon),
      PropField('label', 'متن', PropType.text),
    ]);
