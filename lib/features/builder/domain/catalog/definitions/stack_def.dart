import '../widget_def.dart';
import '../prop_field.dart';
import '../catalog_constants.dart';

/// تعریف ویجت «stack»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • align: تراز فرزندان روی هم
///  • padding: پدینگ
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final stackDef = WidgetDef('stack', 'روی هم (Stack)', container: true,
    defaults: {'align': 'center', 'padding': 0.0},
    fields: [
      PropField('align', 'تراز', PropType.option, options: kAlignmentOptions),
      PropField('padding', 'پدینگ', PropType.number),
    ]);
