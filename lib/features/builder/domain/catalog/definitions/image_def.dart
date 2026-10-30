import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «image»
final imageDef = WidgetDef('image', 'تصویر (URL)',
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
    ]);
