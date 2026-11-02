import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «card»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • bg: رنگ
///  • radius: گردی گوشه
///  • width / height: اندازه (۰ = خودکار)
///  • padding / margin: فاصله‌ی داخلی / بیرونی
///  • borderColor / borderWidth: رنگ و ضخامت بردر (ضخامت ۰ = بدون بردر)
///  • elevation / shadowColor: شدت و رنگ سایه (۰ = بدون سایه)
///  • clip: برش محتوا با گوشه‌های گرد
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final cardDef = WidgetDef('card', 'کارت (Card)', container: true,
    defaults: {
      'variant': 'plain', 'bg': 0xFFFFFFFF, 'radius': 12.0, 'width': 0.0, 'height': 0.0,
      'padding': 12.0, 'margin': 0.0, 'borderColor': 0xFF9E9E9E, 'borderWidth': 0.0,
      'elevation': 0.0, 'shadowColor': 0x40000000, 'clip': true
    },
    fields: [
      PropField('bg', 'رنگ', PropType.color),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('width', 'عرض (۰ = خودکار)', PropType.number),
      PropField('height', 'ارتفاع (۰ = خودکار)', PropType.number),
      PropField('padding', 'پدینگ داخلی', PropType.number),
      PropField('margin', 'فاصله بیرونی', PropType.number),
      PropField('borderColor', 'رنگ بردر', PropType.color),
      PropField('borderWidth', 'ضخامت بردر', PropType.number),
      PropField('elevation', 'سایه (۰ = بدون سایه)', PropType.number),
      PropField('shadowColor', 'رنگ سایه', PropType.color),
      PropField('clip', 'برش محتوا با گوشه‌های گرد', PropType.boolean),
    ],
    variants: [
      Variant('plain', 'ساده', {'borderWidth': 0.0, 'elevation': 0.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 0.0}),
      Variant('outlined', 'بردردار', {'borderWidth': 1.5, 'elevation': 0.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 0.0}),
      Variant('elevated', 'سایه‌دار', {'borderWidth': 0.0, 'elevation': 8.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 8.0}),
      Variant('photo', 'قاب عکس (گوشه گرد)', {'borderWidth': 0.0, 'elevation': 6.0, 'padding': 0.0, 'radius': 20.0, 'height': 160.0, 'margin': 8.0, 'bg': 0xFFE0E0E0}),
    ]);
