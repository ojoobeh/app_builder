import '../widget_def.dart';
import '../common_fields.dart';

/// تعریف ویجت «row»
final rowDef = WidgetDef('row', 'کنار هم (Row)', container: true,
    defaults: {...layoutDefaults, 'main': 'spaceBetween', 'cross': 'center'}, fields: layoutFields);
