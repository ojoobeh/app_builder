import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «tabItem» (یک تب؛ فرزند ویجت tabs)
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • label: عنوان تب
///  • icon: آیکن تب (وقتی showIcons در tabs روشن باشد دیده می‌شود)
/// فرزندان این گره، محتوای همین تب هستند.
final tabItemDef = WidgetDef('tabItem', 'تب (آیتم)',
    container: true,
    defaults: {'label': 'تب', 'icon': 'star'},
    fields: [
      PropField('label', 'عنوان تب', PropType.text),
      PropField('icon', 'آیکن تب', PropType.icon),
    ]);
