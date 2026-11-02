/// ثابت‌های مشترک کاتالوگ (گزینه‌های چینش، پالت رنگ، کلید آیکن‌ها)

/// گزینه‌های چینش در جهت اصلی (برای Row / Column / فوتر)
const kMainAxisOptions = ['start', 'center', 'end', 'spaceBetween', 'spaceAround', 'spaceEvenly'];
/// گزینه‌های چینش در جهت متقاطع
const kCrossAxisOptions = ['start', 'center', 'end', 'stretch'];
/// گزینه‌های تراز (برای Stack)
const kAlignmentOptions = [
  'topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight',
  'bottomLeft', 'bottomCenter', 'bottomRight'
];

/// پالت رنگ‌های قابل انتخاب (عدد ARGB؛ 0x00000000 = شفاف)
const kColorPalette = <int>[
  0x00000000, 0x40000000, 0xFF000000, 0xFFFFFFFF, 0xFF9E9E9E, 0xFFF44336, 0xFFFF9800,
  0xFFFFEB3B, 0xFF4CAF50, 0xFF2196F3, 0xFF3F51B5, 0xFF9C27B0, 0xFFE91E63,
];

/// کلید آیکن‌های متریال. تصویر هر کلید در presentation/theme/icon_registry.dart است (باید هماهنگ بمانند).
const kIconKeys = <String>['home', 'search', 'person', 'settings', 'cart', 'favorite', 'menu', 'notifications', 'add', 'star', 'phone', 'info', 'close', 'check', 'arrow_back', 'arrow_forward', 'arrow_down', 'share', 'edit', 'delete', 'email', 'lock', 'location', 'camera', 'image', 'play', 'filter', 'calendar', 'chat', 'bookmark', 'visibility', 'more', 'logout', 'wallet', 'tag'];
