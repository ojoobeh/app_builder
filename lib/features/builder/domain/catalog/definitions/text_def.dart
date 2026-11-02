import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «text»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • variant: display / headline / title / subtitle / body / label / caption / overline
///  • text: متن (می‌تواند binding داشته باشد: {{item.title}} ، {{data.name}} ، {{args}} ، {{field.q}})
///  • size: اندازه
///  • color: رنگ
///  • bold: بولد
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final textDef = WidgetDef('text', 'متن',
    defaults: {'variant': 'body', 'text': 'متن نمونه', 'size': 16.0, 'color': 0xFF000000, 'bold': false},
    fields: [
      PropField('text', 'متن', PropType.text),
      PropField('size', 'اندازه', PropType.number),
      PropField('color', 'رنگ', PropType.color),
      PropField('bold', 'بولد', PropType.boolean),
    ],
    variants: [
      Variant('display', 'Display (۳۶)', {'size': 36.0, 'bold': true, 'color': 0xFF000000}),
      Variant('headline', 'Headline (۲۸)', {'size': 28.0, 'bold': true, 'color': 0xFF000000}),
      Variant('title', 'Title (۲۲)', {'size': 22.0, 'bold': true, 'color': 0xFF000000}),
      Variant('subtitle', 'Subtitle (۱۸)', {'size': 18.0, 'bold': false, 'color': 0xFF000000}),
      Variant('body', 'Body (۱۶)', {'size': 16.0, 'bold': false, 'color': 0xFF000000}),
      Variant('label', 'Label (۱۴ بولد)', {'size': 14.0, 'bold': true, 'color': 0xFF000000}),
      Variant('caption', 'Caption (۱۲، خاکستری)', {'size': 12.0, 'bold': false, 'color': 0xFF757575}),
      Variant('overline', 'Overline (۱۰، بولد)', {'size': 10.0, 'bold': true, 'color': 0xFF757575}),
    ]);
