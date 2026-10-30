enum PropType { text, number, color, boolean, option, icon }

/// توضیح یک ویژگی قابل‌ویرایش (کلید، برچسب، نوع)
class PropField {
  final String key, label;
  final PropType type;
  final List<String> options;
  const PropField(this.key, this.label, this.type, {this.options = const []});
}

/// فیلد عمومی Expanded؛ فقط وقتی والد Row (یا فوتر/اپ‌بار آزاد) باشد در پنل دیده می‌شود
const kFlexField = PropField('flex', 'Expanded: ضریب فضا (۰ = غیرفعال، ۱ = سهم مساوی)', PropType.number);
