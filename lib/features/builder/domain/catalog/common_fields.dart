import 'catalog_constants.dart';
import 'prop_field.dart';

/// فیلدهای مشترک ویجت‌های چیدمانی (Column / Row)
const layoutFields = [
  PropField('main', 'چینش اصلی', PropType.option, options: kMain),
  PropField('cross', 'چینش متقاطع', PropType.option, options: kCross),
  PropField('spacing', 'فاصله بین فرزندان', PropType.number),
  PropField('padding', 'پدینگ', PropType.number),
];

const layoutDefaults = {'main': 'start', 'cross': 'start', 'spacing': 8.0, 'padding': 8.0};
