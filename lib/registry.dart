import 'package:flutter/material.dart';
import 'node.dart';

/// ثبت ویجت‌ها: برای اضافه کردن ویجت جدید فقط همین فایل + یک case در renderer.dart
enum PropType { text, number, color, boolean, option, icon }

class PropField {
  final String key, label;
  final PropType type;
  final List<String> options;
  const PropField(this.key, this.label, this.type, {this.options = const []});
}

/// نمونه‌ی آماده: مجموعه‌ای از props که روی ویجت اعمال می‌شود.
/// اگر از کتابخانه باشد، importLine و depLine هم در خروجی کد لحاظ می‌شوند.
class Variant {
  final String id, label;
  final Map<String, dynamic> props;
  final String? importLine, depLine;
  const Variant(this.id, this.label, [this.props = const {}, this.importLine, this.depLine]);
}

class WidgetDef {
  final String type, label;
  final IconData icon;
  final bool container; // آیا فرزند می‌پذیرد؟
  final Map<String, dynamic> defaults;
  final List<PropField> fields;
  final List<Variant> variants;
  const WidgetDef(this.type, this.label, this.icon,
      {this.container = false, this.defaults = const {}, this.fields = const [], this.variants = const []});
}

const kMain = ['start', 'center', 'end', 'spaceBetween', 'spaceAround', 'spaceEvenly'];
const kCross = ['start', 'center', 'end', 'stretch'];
const kAlign = [
  'topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight',
  'bottomLeft', 'bottomCenter', 'bottomRight'
];

const kIcons = <String, IconData>{
  'home': Icons.home, 'search': Icons.search, 'person': Icons.person,
  'settings': Icons.settings, 'cart': Icons.shopping_cart, 'favorite': Icons.favorite,
  'menu': Icons.menu, 'notifications': Icons.notifications, 'add': Icons.add,
  'star': Icons.star, 'phone': Icons.phone, 'info': Icons.info,
  'close': Icons.close, 'check': Icons.check, 'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward, 'arrow_down': Icons.keyboard_arrow_down,
  'share': Icons.share, 'edit': Icons.edit, 'delete': Icons.delete, 'email': Icons.email,
  'lock': Icons.lock, 'location': Icons.location_on, 'camera': Icons.camera_alt,
  'image': Icons.image, 'play': Icons.play_arrow, 'filter': Icons.filter_list,
  'calendar': Icons.calendar_today, 'chat': Icons.chat, 'bookmark': Icons.bookmark,
  'visibility': Icons.visibility, 'more': Icons.more_vert, 'logout': Icons.logout,
  'wallet': Icons.account_balance_wallet, 'tag': Icons.local_offer,
};

const kPalette = <int>[
  0x00000000, 0x40000000, 0xFF000000, 0xFFFFFFFF, 0xFF9E9E9E, 0xFFF44336, 0xFFFF9800,
  0xFFFFEB3B, 0xFF4CAF50, 0xFF2196F3, 0xFF3F51B5, 0xFF9C27B0, 0xFFE91E63,
];

const _layout = [
  PropField('main', 'چینش اصلی', PropType.option, options: kMain),
  PropField('cross', 'چینش متقاطع', PropType.option, options: kCross),
  PropField('spacing', 'فاصله بین فرزندان', PropType.number),
  PropField('padding', 'پدینگ', PropType.number),
];
const _layoutDefaults = {'main': 'start', 'cross': 'start', 'spacing': 8.0, 'padding': 8.0};

/// فیلد عمومی Expanded؛ فقط وقتی والد Row (یا فوتر ساده) باشد در پنل ویژگی‌ها دیده می‌شود
const kFlexField = PropField('flex', 'Expanded: ضریب فضا (۰ = غیرفعال، ۱ = سهم مساوی)', PropType.number);

// آیکن‌های SVG داخلی (۲۴×۲۴). برای SVG دلخواه، کدش را در فیلد svg بچسبان.
String _svg(String d) => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="$d"/></svg>';
final _svgHeart = _svg('M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z');
final _svgStar = _svg('M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z');
final _svgHome = _svg('M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z');
final _svgBell = _svg('M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z');
final _svgSearch = _svg('M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z');
final _svgUser = _svg('M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z');

class Registry {
  static final list = <WidgetDef>[
    WidgetDef('appBar', 'اپ‌بار', Icons.web_asset, container: true,
        defaults: {
          'variant': 'simple', 'title': 'عنوان', 'bg': 0xFF3F51B5, 'fg': 0xFFFFFFFF,
          'height': 56.0, 'main': 'spaceBetween'
        },
        fields: [
          PropField('title', 'عنوان (حالت ساده)', PropType.text),
          PropField('bg', 'رنگ پس‌زمینه', PropType.color),
          PropField('fg', 'رنگ متن/آیکن', PropType.color),
          PropField('height', 'ارتفاع', PropType.number),
          PropField('main', 'چینش (حالت آزاد)', PropType.option, options: kMain),
        ],
        variants: [
          Variant('simple', 'عنوان + آیکن‌ها (ساده)'),
          Variant('custom', 'چینش آزاد (Row دلخواه)'),
        ]),
    WidgetDef('footer', 'فوتر', Icons.call_to_action, container: true,
        defaults: {'variant': 'bar', 'bg': 0xFFEEEEEE, 'sel': 0xFF3F51B5, 'height': 56.0, 'main': 'spaceAround'},
        fields: [
          PropField('bg', 'رنگ پس‌زمینه', PropType.color),
          PropField('sel', 'رنگ آیتم فعال', PropType.color),
          PropField('height', 'ارتفاع (نوار ساده)', PropType.number),
          PropField('main', 'چینش (نوار ساده)', PropType.option, options: kMain),
        ],
        variants: [
          Variant('bar', 'نوار ساده'),
          Variant('nav_classic', 'ناوبری کلاسیک (آیکن + متن)'),
          Variant('nav_m3', 'ناوبری متریال ۳ (انیمیشن)'),
          Variant('nav_text', 'ناوبری فقط متن (بدون آیکن)'),
          Variant('lib_curved', 'Curved Nav (کتابخانه، انیمیشن)', {},
              "import 'package:curved_navigation_bar/curved_navigation_bar.dart';", 'curved_navigation_bar: ^1.0.6'),
          Variant('lib_gnav', 'GNav (کتابخانه)', {},
              "import 'package:google_nav_bar/google_nav_bar.dart';", 'google_nav_bar: ^5.0.7'),
        ]),
    WidgetDef('navItem', 'آیتم ناوبری', Icons.tab,
        defaults: {'icon': 'home', 'label': 'خانه'},
        fields: [
          PropField('icon', 'آیکن', PropType.icon),
          PropField('label', 'متن', PropType.text),
        ]),
    WidgetDef('column', 'زیر هم (Column)', Icons.view_agenda, container: true,
        defaults: _layoutDefaults, fields: _layout),
    WidgetDef('row', 'کنار هم (Row)', Icons.view_column, container: true,
        defaults: {..._layoutDefaults, 'main': 'spaceBetween', 'cross': 'center'}, fields: _layout),
    WidgetDef('stack', 'روی هم (Stack)', Icons.layers, container: true,
        defaults: {'align': 'center', 'padding': 0.0},
        fields: [
          PropField('align', 'تراز', PropType.option, options: kAlign),
          PropField('padding', 'پدینگ', PropType.number),
        ]),
    WidgetDef('container', 'کادر (Container)', Icons.crop_square, container: true,
        defaults: {'bg': 0xFFE3F2FD, 'radius': 8.0, 'padding': 12.0, 'width': 0.0, 'height': 0.0},
        fields: [
          PropField('bg', 'رنگ', PropType.color),
          PropField('radius', 'گردی گوشه', PropType.number),
          PropField('padding', 'پدینگ', PropType.number),
          PropField('width', 'عرض (۰ = خودکار)', PropType.number),
          PropField('height', 'ارتفاع (۰ = خودکار)', PropType.number),
        ]),
    WidgetDef('card', 'کارت (Card)', Icons.credit_card, container: true,
        defaults: {
          'variant': 'plain', 'bg': 0xFFFFFFFF, 'radius': 12.0, 'width': 0.0, 'height': 0.0,
          'padding': 12.0, 'margin': 0.0, 'borderColor': 0xFF9E9E9E, 'borderWidth': 0.0,
          'elevation': 0.0, 'shadowColor': 0x40000000, 'clip': true
        },
        fields: [
          PropField('bg', 'رنگ', PropType.color),
          PropField('radius', 'گردی گوشه', PropType.number),
          PropField('width', 'عرض (۰ = خودکار)', PropType.number),
          PropField('height', 'ارتفاع (۰ = خودکار)', PropType.number),
          PropField('padding', 'پدینگ داخلی', PropType.number),
          PropField('margin', 'فاصله بیرونی', PropType.number),
          PropField('borderColor', 'رنگ بردر', PropType.color),
          PropField('borderWidth', 'ضخامت بردر', PropType.number),
          PropField('elevation', 'سایه (۰ = بدون سایه)', PropType.number),
          PropField('shadowColor', 'رنگ سایه', PropType.color),
          PropField('clip', 'برش محتوا با گوشه‌های گرد', PropType.boolean),
        ],
        variants: [
          Variant('plain', 'ساده', {'borderWidth': 0.0, 'elevation': 0.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 0.0}),
          Variant('outlined', 'بردردار', {'borderWidth': 1.5, 'elevation': 0.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 0.0}),
          Variant('elevated', 'سایه‌دار', {'borderWidth': 0.0, 'elevation': 8.0, 'padding': 12.0, 'radius': 12.0, 'height': 0.0, 'margin': 8.0}),
          Variant('photo', 'قاب عکس (گوشه گرد)', {'borderWidth': 0.0, 'elevation': 6.0, 'padding': 0.0, 'radius': 20.0, 'height': 160.0, 'margin': 8.0, 'bg': 0xFFE0E0E0}),
        ]),
    WidgetDef('text', 'متن', Icons.text_fields,
        defaults: {'variant': 'body', 'text': 'متن نمونه', 'size': 16.0, 'color': 0xFF000000, 'bold': false},
        fields: [
          PropField('text', 'متن', PropType.text),
          PropField('size', 'اندازه', PropType.number),
          PropField('color', 'رنگ', PropType.color),
          PropField('bold', 'بولد', PropType.boolean),
        ],
        variants: [
          Variant('display', 'Display (۳۶)', {'size': 36.0, 'bold': true, 'color': 0xFF000000}),
          Variant('headline', 'Headline (۲۸)', {'size': 28.0, 'bold': true, 'color': 0xFF000000}),
          Variant('title', 'Title (۲۲)', {'size': 22.0, 'bold': true, 'color': 0xFF000000}),
          Variant('subtitle', 'Subtitle (۱۸)', {'size': 18.0, 'bold': false, 'color': 0xFF000000}),
          Variant('body', 'Body (۱۶)', {'size': 16.0, 'bold': false, 'color': 0xFF000000}),
          Variant('label', 'Label (۱۴ بولد)', {'size': 14.0, 'bold': true, 'color': 0xFF000000}),
          Variant('caption', 'Caption (۱۲، خاکستری)', {'size': 12.0, 'bold': false, 'color': 0xFF757575}),
          Variant('overline', 'Overline (۱۰، بولد)', {'size': 10.0, 'bold': true, 'color': 0xFF757575}),
        ]),
    WidgetDef('textField', 'فیلد متن', Icons.input,
        defaults: {'hint': 'جستجو...', 'fg': 0xFF000000, 'bg': 0xFFFFFFFF, 'borderColor': 0x00000000, 'radius': 8.0},
        fields: [
          PropField('hint', 'متن راهنما', PropType.text),
          PropField('fg', 'رنگ متن', PropType.color),
          PropField('bg', 'رنگ پس‌زمینه', PropType.color),
          PropField('borderColor', 'رنگ بردر', PropType.color),
          PropField('radius', 'گردی گوشه', PropType.number),
        ]),
    WidgetDef('icon', 'آیکن', Icons.emoji_symbols,
        defaults: {'icon': 'star', 'size': 24.0, 'color': 0xFF000000},
        fields: [
          PropField('icon', 'آیکن', PropType.icon),
          PropField('size', 'اندازه', PropType.number),
          PropField('color', 'رنگ', PropType.color),
        ]),
    WidgetDef('svg', 'آیکن SVG', Icons.draw,
        defaults: {'variant': 'heart', 'svg': _svgHeart, 'size': 28.0, 'color': 0xFFE91E63},
        fields: [
          PropField('svg', 'کد SVG (از فایل svg یا Figma کپی کن)', PropType.text),
          PropField('size', 'اندازه', PropType.number),
          PropField('color', 'رنگ', PropType.color),
        ],
        variants: [
          Variant('heart', 'قلب', {'svg': _svgHeart, 'color': 0xFFE91E63}),
          Variant('star', 'ستاره', {'svg': _svgStar, 'color': 0xFFFFB300}),
          Variant('home', 'خانه', {'svg': _svgHome, 'color': 0xFF3F51B5}),
          Variant('bell', 'زنگ', {'svg': _svgBell, 'color': 0xFF3F51B5}),
          Variant('search', 'جستجو', {'svg': _svgSearch, 'color': 0xFF3F51B5}),
          Variant('user', 'کاربر', {'svg': _svgUser, 'color': 0xFF3F51B5}),
        ]),
    WidgetDef('button', 'دکمه', Icons.smart_button,
        defaults: {
          'variant': 'filled', 'text': 'دکمه', 'kind': 'filled', 'bg': 0xFF3F51B5,
          'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': false
        },
        fields: [
          PropField('text', 'متن', PropType.text),
          PropField('kind', 'نوع', PropType.option, options: ['filled', 'outlined', 'text']),
          PropField('bg', 'رنگ پس‌زمینه', PropType.color),
          PropField('fg', 'رنگ متن/بردر', PropType.color),
          PropField('radius', 'گردی گوشه', PropType.number),
          PropField('elevation', 'سایه', PropType.number),
          PropField('bold', 'متن بولد', PropType.boolean),
        ],
        variants: [
          Variant('filled', 'ساده (پر)', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': false}),
          Variant('outlined', 'فقط بردر', {'kind': 'outlined', 'fg': 0xFF3F51B5, 'radius': 8.0, 'elevation': 0.0, 'bold': false}),
          Variant('rounded', 'گوشه گرد', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 30.0, 'elevation': 2.0, 'bold': false}),
          Variant('shadow', 'سایه‌دار', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 12.0, 'bold': false}),
          Variant('bold', 'متن بولد', {'kind': 'filled', 'fg': 0xFFFFFFFF, 'radius': 8.0, 'elevation': 2.0, 'bold': true}),
          Variant('text', 'فقط متن', {'kind': 'text', 'fg': 0xFF3F51B5, 'radius': 8.0, 'elevation': 0.0, 'bold': false}),
        ]),
    WidgetDef('image', 'تصویر (URL)', Icons.image,
        defaults: {
          'variant': 'fixed', 'url': 'https://picsum.photos/600/340', 'mode': 'fixed', 'ratio': 1.78,
          'width': 0.0, 'height': 150.0, 'rTL': 0.0, 'rTR': 0.0, 'rBL': 0.0, 'rBR': 0.0
        },
        fields: [
          PropField('url', 'آدرس تصویر', PropType.text),
          PropField('mode', 'حالت (fixed ثابت / banner تمام‌عرض)', PropType.option, options: ['fixed', 'banner']),
          PropField('ratio', 'نسبت عرض÷ارتفاع در بنر (16:9 = 1.78، 4:3 = 1.33)', PropType.number),
          PropField('width', 'عرض (حالت ثابت، ۰ = خودکار)', PropType.number),
          PropField('height', 'ارتفاع (حالت ثابت)', PropType.number),
          PropField('rTL', 'گوشه بالا-چپ', PropType.number),
          PropField('rTR', 'گوشه بالا-راست', PropType.number),
          PropField('rBL', 'گوشه پایین-چپ', PropType.number),
          PropField('rBR', 'گوشه پایین-راست', PropType.number),
        ],
        variants: [
          Variant('fixed', 'اندازه ثابت', {'mode': 'fixed', 'ratio': 1.78, 'width': 0.0, 'height': 150.0, 'rTL': 0.0, 'rTR': 0.0, 'rBL': 0.0, 'rBR': 0.0}),
          Variant('banner', 'بنر تمام‌عرض', {'mode': 'banner', 'ratio': 1.78, 'width': 0.0, 'height': 150.0, 'rTL': 0.0, 'rTR': 0.0, 'rBL': 0.0, 'rBR': 0.0}),
          Variant('banner_round', 'بنر با گوشه گرد', {'mode': 'banner', 'ratio': 1.78, 'width': 0.0, 'height': 150.0, 'rTL': 16.0, 'rTR': 16.0, 'rBL': 16.0, 'rBR': 16.0}),
          Variant('top_round', 'بنر، فقط گوشه‌های بالا گرد', {'mode': 'banner', 'ratio': 1.78, 'width': 0.0, 'height': 150.0, 'rTL': 24.0, 'rTR': 24.0, 'rBL': 0.0, 'rBR': 0.0}),
          Variant('avatar', 'دایره (آواتار)', {'mode': 'fixed', 'ratio': 1.0, 'width': 100.0, 'height': 100.0, 'rTL': 50.0, 'rTR': 50.0, 'rBL': 50.0, 'rBR': 50.0}),
        ]),
  ];

  static final Map<String, WidgetDef> defs = {for (final d in list) d.type: d};
  static WidgetDef of(String type) => defs[type]!;

  /// نمونه‌های یک ویجت؛ برای آیکن، به‌ازای هر آیکن یک نمونه ساخته می‌شود
  static List<Variant> variantsOf(WidgetDef d) =>
      d.type == 'icon' ? [for (final e in kIcons.keys) Variant(e, e, {'icon': e})] : d.variants;

  /// ویجت‌هایی که کاربر می‌تواند اضافه کند (اپ‌بار و فوتر ثابت‌اند)
  static List<WidgetDef> get addable => list.where((d) => d.type != 'appBar' && d.type != 'footer').toList();

  static WidgetNode create(String type) => WidgetNode(type: type, props: Map<String, dynamic>.from(of(type).defaults));
}
