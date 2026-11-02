import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «icon»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • icon: کلید آیکن متریال (از kIconKeys)
///  • size: اندازه
///  • color: رنگ
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final iconDef = WidgetDef('icon', 'آیکن',
    defaults: {'icon': 'star', 'size': 24.0, 'color': 0xFF000000},
    fields: [
      PropField('icon', 'آیکن', PropType.icon),
      PropField('size', 'اندازه', PropType.number),
      PropField('color', 'رنگ', PropType.color),
    ]);
