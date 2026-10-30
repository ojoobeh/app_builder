import '../widget_def.dart';
import '../prop_field.dart';
import '../catalog_constants.dart';

/// تعریف ویجت «stack»
final stackDef = WidgetDef('stack', 'روی هم (Stack)', container: true,
    defaults: {'align': 'center', 'padding': 0.0},
    fields: [
      PropField('align', 'تراز', PropType.option, options: kAlign),
      PropField('padding', 'پدینگ', PropType.number),
    ]);
