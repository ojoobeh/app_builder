/// نوع یک ویژگی؛ تعیین می‌کند در پنل ویژگی‌ها با چه ابزاری ویرایش شود
/// text = فیلد متنی | number = عددی | color = پالت رنگ | boolean = روشن/خاموش | option = منوی گزینه‌ها | icon = انتخاب آیکن | page = انتخاب یکی از صفحه‌های پروژه (مقدار = شناسه‌ی صفحه)
enum PropType { text, number, color, boolean, option, icon, page }

/// توضیح یک ویژگی قابل‌ویرایش (کلید، برچسب، نوع)
class PropField {
  final String key, label;
  final PropType type;
  final List<String> options;
  const PropField(this.key, this.label, this.type, {this.options = const []});
}

/// فیلد عمومی Expanded؛ فقط وقتی والد Row (یا فوتر/اپ‌بار آزاد) باشد در پنل دیده می‌شود
const kFlexField = PropField('flex', 'Expanded: ضریب فضا (۰ = غیرفعال، ۱ = سهم مساوی)', PropType.number);
