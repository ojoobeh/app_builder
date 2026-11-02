import '../widget_def.dart';
import '../common_fields.dart';

/// تعریف ویجت «row»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • main / cross: چینش اصلی / متقاطع
///  • spacing: فاصله بین فرزندان
///  • padding: پدینگ
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final rowDef = WidgetDef('row', 'کنار هم (Row)', container: true,
    defaults: {...layoutDefaults, 'main': 'spaceBetween', 'cross': 'center'}, fields: layoutFields);
