import '../widget_def.dart';
import '../prop_field.dart';
import '../catalog_constants.dart';

/// تعریف ویجت «footer»
final footerDef = WidgetDef('footer', 'فوتر', container: true,
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
    ]);
