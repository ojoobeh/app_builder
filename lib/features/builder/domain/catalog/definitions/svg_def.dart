import '../widget_def.dart';
import '../prop_field.dart';
import '../svg_assets.dart';

/// تعریف ویجت «svg»
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • svg: کد کامل SVG
///  • size: اندازه
///  • color: رنگ (روی SVG اعمال می‌شود)
/// علاوه بر این، هر ویجتی می‌تواند flex (Expanded) داشته باشد.
final svgDef = WidgetDef('svg', 'آیکن SVG',
    defaults: {'variant': 'heart', 'svg': svgHeart, 'size': 28.0, 'color': 0xFFE91E63},
    fields: [
      PropField('svg', 'کد SVG (از فایل svg یا Figma کپی کن)', PropType.text),
      PropField('size', 'اندازه', PropType.number),
      PropField('color', 'رنگ', PropType.color),
    ],
    variants: [
      Variant('heart', 'قلب', {'svg': svgHeart, 'color': 0xFFE91E63}),
      Variant('star', 'ستاره', {'svg': svgStar, 'color': 0xFFFFB300}),
      Variant('home', 'خانه', {'svg': svgHome, 'color': 0xFF3F51B5}),
      Variant('bell', 'زنگ', {'svg': svgBell, 'color': 0xFF3F51B5}),
      Variant('search', 'جستجو', {'svg': svgSearch, 'color': 0xFF3F51B5}),
      Variant('user', 'کاربر', {'svg': svgUser, 'color': 0xFF3F51B5}),
    ]);
