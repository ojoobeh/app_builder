import 'prop_field.dart';

/// نمونه‌ی آماده: مجموعه‌ای از props که روی ویجت اعمال می‌شود.
/// اگر از کتابخانه باشد، importLine و depLine هم در خروجی کد لحاظ می‌شوند.
class Variant {
  final String id, label;
  final Map<String, dynamic> props;
  final String? importLine, depLine;
  const Variant(this.id, this.label, [this.props = const {}, this.importLine, this.depLine]);
}

/// تعریف یک نوع ویجت: نام، ویژگی‌ها، مقادیر پیش‌فرض و نمونه‌های آماده.
/// (آیکن نمایشی در لایه‌ی presentation نگه‌داری می‌شود تا domain از Flutter مستقل بماند.)
class WidgetDef {
  final String type, label;
  final bool container; // آیا فرزند می‌پذیرد؟
  final Map<String, dynamic> defaults;
  final List<PropField> fields;
  final List<Variant> variants;
  const WidgetDef(this.type, this.label,
      {this.container = false, this.defaults = const {}, this.fields = const [], this.variants = const []});
}
