import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «container»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • bg: رنگ
///  • radius: گردی گوشه
///  • padding: پدینگ داخلی
///  • width / height: اندازه (۰ = خودکار)
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final containerDef = WidgetDef('container', 'کادر (Container)', container: true,
    defaults: {'bg': 0xFFE3F2FD, 'radius': 8.0, 'padding': 12.0, 'width': 0.0, 'height': 0.0},
    fields: [
      PropField('bg', 'رنگ', PropType.color),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('padding', 'پدینگ', PropType.number),
      PropField('width', 'عرض (۰ = خودکار)', PropType.number),
      PropField('height', 'ارتفاع (۰ = خودکار)', PropType.number),
    ]);
