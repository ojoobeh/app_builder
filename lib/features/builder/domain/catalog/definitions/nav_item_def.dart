import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «navItem»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • icon: کلید آیکن
///  • label: متن زیر آیکن
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final navItemDef = WidgetDef('navItem', 'آیتم ناوبری',
    defaults: {'icon': 'home', 'label': 'خانه'},
    fields: [
      PropField('icon', 'آیکن', PropType.icon),
      PropField('label', 'متن', PropType.text),
    ]);
