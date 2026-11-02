import '../widget_def.dart';
import '../prop_field.dart';

/// تعریف ویجت «tabs» (تب‌بندی: نوار تب + محتوای تب فعال)
///
/// ویژگی‌ها (کلید در props ← معنی):
///  • style: underline (خط زیرین) / pill (حبابی) / segmented (نوار تکه‌تکه) / plain (فقط متن)
///  • activeColor: رنگ خط یا حباب تب فعال
///  • activeTextColor / inactiveColor: رنگ متن تب فعال / غیرفعال
///  • barColor: پس‌زمینه‌ی نوار تب
///  • labelSize / radius / indicatorHeight: اندازه‌ی متن، گردی گوشه، ضخامت خط
///  • animation: fade / slide / scale / none؛ duration: مدت انیمیشن (میلی‌ثانیه)
///  • barPosition: top / bottom؛ gap: فاصله‌ی نوار تا محتوا
///  • showIcons / scrollable / bold: آیکن تب‌ها، نوار اسکرولی، بولد بودن تب فعال
///  • name: نام متغیر شماره‌ی تب در کنترلر صفحه (انگلیسی؛ خالی = نام خودکار)
/// فرزندان این گره باید tabItem باشند.
final tabsDef = WidgetDef('tabs', 'تب‌بندی',
    container: true,
    defaults: {
      'variant': 'underline', 'name': '', 'style': 'underline',
      'activeColor': 0xFF3F51B5, 'activeTextColor': 0xFF3F51B5, 'inactiveColor': 0xFF757575, 'barColor': 0x00000000,
      'labelSize': 14.0, 'radius': 20.0, 'indicatorHeight': 3.0,
      'animation': 'fade', 'duration': 250.0, 'barPosition': 'top', 'gap': 8.0,
      'showIcons': false, 'scrollable': false, 'bold': true,
    },
    fields: [
      PropField('name', 'نام متغیر در کنترلر (انگلیسی)', PropType.text),
      PropField('activeColor', 'رنگ خط/حباب تب فعال', PropType.color),
      PropField('activeTextColor', 'رنگ متن تب فعال', PropType.color),
      PropField('inactiveColor', 'رنگ متن تب غیرفعال', PropType.color),
      PropField('barColor', 'رنگ پس‌زمینه نوار', PropType.color),
      PropField('labelSize', 'اندازه متن', PropType.number),
      PropField('radius', 'گردی گوشه', PropType.number),
      PropField('indicatorHeight', 'ضخامت خط', PropType.number),
      PropField('duration', 'مدت انیمیشن (ms)', PropType.number),
      PropField('gap', 'فاصله نوار تا محتوا', PropType.number),
      PropField('style', 'سبک نوار', PropType.option, options: ['underline', 'pill', 'segmented', 'plain']),
      PropField('animation', 'انیمیشن', PropType.option, options: ['fade', 'slide', 'scale', 'none']),
      PropField('barPosition', 'جای نوار', PropType.option, options: ['top', 'bottom']),
      PropField('showIcons', 'نمایش آیکن', PropType.boolean),
      PropField('scrollable', 'نوار اسکرولی', PropType.boolean),
      PropField('bold', 'بولد تب فعال', PropType.boolean),
    ],
    variants: [
      Variant('underline', 'خط زیرین', {'style': 'underline', 'activeColor': 0xFF3F51B5, 'activeTextColor': 0xFF3F51B5, 'inactiveColor': 0xFF757575, 'barColor': 0x00000000, 'radius': 20.0, 'showIcons': false}),
      Variant('pill', 'حبابی', {'style': 'pill', 'activeColor': 0xFF3F51B5, 'activeTextColor': 0xFFFFFFFF, 'inactiveColor': 0xFF757575, 'barColor': 0x00000000, 'radius': 20.0, 'showIcons': false}),
      Variant('segmented', 'نوار تکه‌تکه', {'style': 'segmented', 'activeColor': 0xFFFFFFFF, 'activeTextColor': 0xFF000000, 'inactiveColor': 0xFF757575, 'barColor': 0xFFE0E0E0, 'radius': 10.0, 'showIcons': false}),
      Variant('icons', 'با آیکن', {'style': 'underline', 'activeColor': 0xFF3F51B5, 'activeTextColor': 0xFF3F51B5, 'inactiveColor': 0xFF757575, 'barColor': 0x00000000, 'radius': 20.0, 'showIcons': true}),
      Variant('plain', 'فقط متن', {'style': 'plain', 'activeColor': 0xFF3F51B5, 'activeTextColor': 0xFF3F51B5, 'inactiveColor': 0xFF757575, 'barColor': 0x00000000, 'radius': 20.0, 'showIcons': false}),
    ]);
