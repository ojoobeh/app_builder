import '../widget_def.dart';
import '../common_fields.dart';

/// تعریف ویجت «column»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • main / cross: چینش اصلی / متقاطع
///  • spacing: فاصله بین فرزندان
///  • padding: پدینگ
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final columnDef = WidgetDef('column', 'زیر هم (Column)', container: true,
    defaults: layoutDefaults, fields: layoutFields);
