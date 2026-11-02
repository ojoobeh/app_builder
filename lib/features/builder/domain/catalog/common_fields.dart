import 'catalog_constants.dart';
import 'prop_field.dart';

/// فیلدهای مشترک ویجت‌های چیدمانی (Column / Row)
/// فیلدهای قابل‌ویرایش مشترک: چینش اصلی، چینش متقاطع، فاصله بین فرزندان، پدینگ
const layoutFields = [
  PropField('main', 'چینش اصلی', PropType.option, options: kMainAxisOptions),
  PropField('cross', 'چینش متقاطع', PropType.option, options: kCrossAxisOptions),
  PropField('spacing', 'فاصله بین فرزندان', PropType.number),
  PropField('padding', 'پدینگ', PropType.number),
];

/// مقادیر پیش‌فرض این فیلدها
const layoutDefaults = {'main': 'start', 'cross': 'start', 'spacing': 8.0, 'padding': 8.0};
