import '../widget_def.dart';
import '../prop_field.dart';
import '../catalog_constants.dart';

/// تعریف ویجت «appBar»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • variant: simple = عنوان + آیکن‌ها | custom = چینش آزاد (یک Row دلخواه)
///  • title: عنوان (فقط حالت ساده)
///  • bg / fg: رنگ پس‌زمینه / رنگ متن و آیکن
///  • height: ارتفاع نوار
///  • main: چینش فرزندان در حالت آزاد
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final appBarDef = WidgetDef('appBar', 'اپ‌بار', container: true,
    defaults: {
      'variant': 'simple', 'title': 'عنوان', 'bg': 0xFF3F51B5, 'fg': 0xFFFFFFFF,
      'height': 56.0, 'main': 'spaceBetween'
    },
    fields: [
      PropField('title', 'عنوان (حالت ساده)', PropType.text),
      PropField('bg', 'رنگ پس‌زمینه', PropType.color),
      PropField('fg', 'رنگ متن/آیکن', PropType.color),
      PropField('height', 'ارتفاع', PropType.number),
      PropField('main', 'چینش (حالت آزاد)', PropType.option, options: kMainAxisOptions),
    ],
    variants: [
      Variant('simple', 'عنوان + آیکن‌ها (ساده)'),
      Variant('custom', 'چینش آزاد (Row دلخواه)'),
    ]);
