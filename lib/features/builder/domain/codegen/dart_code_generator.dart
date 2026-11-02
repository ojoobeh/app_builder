import '../bindings/bindings.dart';
import '../entities/widget_node.dart';
import '../entities/page_model.dart';
import '../catalog/widget_def.dart';
import '../catalog/widget_catalog.dart';
import 'model_code_generator.dart';

// این فایل درخت ویجت‌ها (WidgetNode) را به «متن کد دارت» تبدیل می‌کند.
// خروجی فقط به material وابسته است (نه get، نه hive)، تا در هر پروژه‌ی خامی کار کند.
// کد خودش (domain) هم به Flutter وابسته نیست؛ فقط با رشته کار می‌کند.

// ============================================================================
// ابزارهای ساخت متن کد
// ============================================================================

/// فاصله‌ی ابتدای خط؛ هر سطح تو رفتگی = ۲ فاصله
String _indent(int level) => '  ' * level;

/// عدد را به‌صورت لیترال double می‌نویسد (۸ → '8.0'؛ مقدار نامعتبر → '0.0')
String _double(dynamic value) => (value is num ? value.toDouble() : 0.0).toString();

/// عدد مثبت را به لیترال double تبدیل می‌کند؛ ۰ یا منفی یعنی «خودکار» و null برمی‌گردد.
String? _positiveOrNull(dynamic value) => (value is num && value > 0) ? value.toDouble().toString() : null;

/// عدد ARGB را به متن `Color(0xAARRGGBB)` تبدیل می‌کند.
String _colorLiteral(dynamic value) => value is int
    ? 'Color(0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()})'
    : 'Colors.black';

/// متن را به یک لیترال رشته‌ی دارت تبدیل می‌کند (نقل‌قول، بک‌اسلش، $ و خط جدید را escape می‌کند).
String _stringLiteral(dynamic value) => "'${_escapeLiteralPart('${value ?? ''}')}'";

/// متن را برای قرار گرفتن وسط یک رشته‌ی تک‌نقل‌قولی دارت escape می‌کند (بدون نقل‌قول دور آن).
String _escapeLiteralPart(String text) => text
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$')
    .replaceAll('\n', r'\n');

/// کلید آیکن‌هایی که اسمشان در Icons.* فرق دارد
const _iconNameByKey = {
  'cart': 'shopping_cart', 'arrow_down': 'keyboard_arrow_down', 'location': 'location_on',
  'camera': 'camera_alt', 'play': 'play_arrow', 'filter': 'filter_list', 'calendar': 'calendar_today',
  'more': 'more_vert', 'wallet': 'account_balance_wallet', 'tag': 'local_offer',
};

/// اسم واقعی آیکن در کلاس Icons (اگر نگاشت خاصی نبود، همان کلید)
String _iconName(dynamic key) => _iconNameByKey['$key'] ?? '$key';

/// یک فراخوانی سازنده را می‌نویسد:
///   Name(
///     key: value,
///   )
/// [level] تو رفتگی خط شروع است؛ مقدار هر آرگومان باید در سطح level+1 تولید شده باشد.
String _constructorCall(String name, int level, Map<String, String> arguments) {
  final buffer = StringBuffer('$name(\n');
  arguments.forEach((key, value) => buffer.write('${_indent(level + 1)}$key: $value,\n'));
  buffer.write('${_indent(level)})');
  return buffer.toString();
}

/// لیست فرزندان را به‌صورت `[ ... ]` می‌نویسد.
/// [allowExpanded]: اگر والد Row/فوتر است، فرزندانی که ضریب flex دارند در Expanded پیچیده می‌شوند.
String _listLiteral(List<WidgetNode> nodes, int level, {bool allowExpanded = false}) {
  if (nodes.isEmpty) return '[]';
  final buffer = StringBuffer('[\n');
  for (final node in nodes) {
    buffer.write('${_indent(level + 1)}${_emitChild(node, level + 1, allowExpanded)},\n');
  }
  buffer.write('${_indent(level)}]');
  return buffer.toString();
}

/// لیستی از تکه‌کدهای آماده را به‌صورت `[ ... ]` می‌نویسد.
String _rawListLiteral(List<String> items, int level) {
  final buffer = StringBuffer('[\n');
  for (final item in items) {
    buffer.write('${_indent(level + 1)}$item,\n');
  }
  buffer.write('${_indent(level)}]');
  return buffer.toString();
}

/// کد یک فرزند؛ در صورت داشتن flex آن را در Expanded می‌پیچد.
String _emitChild(WidgetNode child, int level, bool allowExpanded) {
  final flex = (allowExpanded && child.props['flex'] is num) ? (child.props['flex'] as num).toInt() : 0;
  if (flex <= 0) {
    final code = _emitWidget(child, level);
    // TextField داخل Row بدون Expanded عرض نامحدود می‌گیرد و خطا می‌دهد؛ پس عرض ۲۰۰ می‌دهیم
    return (allowExpanded && child.type == 'textField') ? 'SizedBox(width: 200.0, child: $code)' : code;
  }
  return _constructorCall('Expanded', level, {'flex': '$flex', 'child': _emitWidget(child, level + 1)});
}

// ============================================================================
// تولید کد هر نوع ویجت
// ============================================================================

/// کد دارت یک ویجت (و فرزندانش) را می‌نویسد. [level] سطح تو رفتگی است.
String _emitWidget(WidgetNode node, int level) {
  switch (node.type) {
    case 'column':
    case 'row':
      return _emitColumnOrRow(node, level);
    case 'stack':
      return _emitStack(node, level);
    case 'container':
      return _emitContainer(node, level);
    case 'card':
      return _emitCard(node, level);
    case 'text':
      return _emitText(node.props);
    case 'textField':
      return _emitTextField(node, level);
    case 'svg':
      return _emitSvg(node.props);
    case 'icon':
      return _emitIcon(node.props);
    case 'button':
      return _emitButton(node, level);
    case 'tabs':
      return _emitTabs(node, level);
    case 'tabItem':
      return _constructorCall('Column', level, {
        'crossAxisAlignment': 'CrossAxisAlignment.start',
        'children': _listLiteral(node.children, level + 1),
      });
    case 'checkbox':
      return _emitCheckbox(node);
    case 'radio':
      return _emitRadio(node);
    case 'navItem':
      return _emitNavItem(node.props);
    case 'image':
      return _emitImage(node.props, level);
    case 'dataList':
      return _emitDataList(node, level);
    default:
      return 'const SizedBox.shrink()';
  }
}

/// Column یا Row با پدینگ
String _emitColumnOrRow(WidgetNode node, int level) {
  final props = node.props;
  final isRow = node.type == 'row';
  return _constructorCall('Padding', level, {
    'padding': 'EdgeInsets.all(${_double(props['padding'])})',
    'child': _constructorCall(isRow ? 'Row' : 'Column', level + 1, {
      'mainAxisAlignment': 'MainAxisAlignment.${props['main']}',
      'crossAxisAlignment': 'CrossAxisAlignment.${props['cross']}',
      'spacing': _double(props['spacing']),
      'children': _listLiteral(node.children, level + 2, allowExpanded: isRow),
    }),
  });
}

/// Stack با پدینگ
String _emitStack(WidgetNode node, int level) {
  final props = node.props;
  return _constructorCall('Padding', level, {
    'padding': 'EdgeInsets.all(${_double(props['padding'])})',
    'child': _constructorCall('Stack', level + 1, {
      'alignment': 'Alignment.${props['align']}',
      'children': _listLiteral(node.children, level + 2),
    }),
  });
}

/// Container ساده (رنگ، گوشه‌ی گرد، اندازه‌ی اختیاری)
String _emitContainer(WidgetNode node, int level) {
  final props = node.props;
  final width = _positiveOrNull(props['width']);
  final height = _positiveOrNull(props['height']);
  final children = node.children;
  return _constructorCall('Container', level, {
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    'padding': 'EdgeInsets.all(${_double(props['padding'])})',
    'decoration':
        'BoxDecoration(color: ${_colorLiteral(props['bg'])}, borderRadius: BorderRadius.circular(${_double(props['radius'])}))',
    // یک فرزند مستقیم؛ چند فرزند داخل Column
    if (children.length == 1) 'child': _emitWidget(children.first, level + 1),
    if (children.length > 1)
      'child': _constructorCall('Column', level + 1, {
        'mainAxisSize': 'MainAxisSize.min',
        'children': _listLiteral(children, level + 2),
      }),
  });
}

/// کارت: Container با بردر و سایه‌ی اختیاری و برش محتوا
String _emitCard(WidgetNode node, int level) {
  final props = node.props;
  final shadowStrength = (props['elevation'] is num) ? (props['elevation'] as num).toDouble() : 0.0;
  final borderWidth = _positiveOrNull(props['borderWidth']);
  final width = _positiveOrNull(props['width']);
  final height = _positiveOrNull(props['height']);
  final margin = _positiveOrNull(props['margin']);
  final children = node.children;

  // بردر و سایه فقط وقتی مقدارشان بیشتر از صفر است نوشته می‌شوند
  final borderCode = borderWidth != null
      ? ', border: Border.all(color: ${_colorLiteral(props['borderColor'])}, width: $borderWidth)'
      : '';
  final shadowCode = shadowStrength > 0
      ? ', boxShadow: [BoxShadow(color: ${_colorLiteral(props['shadowColor'])}, blurRadius: ${shadowStrength * 2}, offset: Offset(0.0, ${shadowStrength / 2}))]'
      : '';
  final decoration =
      'BoxDecoration(color: ${_colorLiteral(props['bg'])}, borderRadius: BorderRadius.circular(${_double(props['radius'])})$borderCode$shadowCode)';

  return _constructorCall('Container', level, {
    if (margin != null) 'margin': 'EdgeInsets.all($margin)',
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    'padding': 'EdgeInsets.all(${_double(props['padding'])})',
    if (props['clip'] != false) 'clipBehavior': 'Clip.antiAlias',
    'decoration': decoration,
    if (children.length == 1) 'child': _emitWidget(children.first, level + 1),
    if (children.length > 1)
      'child': _constructorCall('Column', level + 1, {
        'mainAxisSize': 'MainAxisSize.min',
        'children': _listLiteral(children, level + 2),
      }),
  });
}

/// Text با اندازه، رنگ و بولد
String _emitText(Map<String, dynamic> props) {
  final boldCode = props['bold'] == true ? ', fontWeight: FontWeight.bold' : '';
  final text = _boundString(props['text']);
  final code =
      'Text(${text.code}, style: TextStyle(fontSize: ${_double(props['size'])}, color: ${_colorLiteral(props['color'])}$boldCode))';
  return text.reactive ? 'Obx(() => $code)' : code; // وابسته به پاسخ سرور = با رسیدن داده دوباره ساخته می‌شود
}

/// TextField ساده و قابل‌شخصی‌سازی (خط زیرین / کادر / بردر / لیبل / هینت / پس‌زمینه)
String _emitTextField(WidgetNode node, int level) {
  final props = node.props;
  final controllerName = _context?.names[node.id]; // در حالت پروژه: TextEditingController کنترلر
  final textColor = _colorLiteral(props['fg']);
  final borderColor = _colorLiteral(props['borderColor'] ?? 0);
  final borderWidth = _double(props['borderWidth'] ?? 1.0);

  // شکل بردر
  final String border;
  switch (props['border'] ?? 'outline') {
    case 'none':
      border = 'InputBorder.none';
      break;
    case 'underline':
      border = 'UnderlineInputBorder(borderSide: BorderSide(color: $borderColor, width: $borderWidth))';
      break;
    default:
      border =
          'OutlineInputBorder(borderRadius: BorderRadius.circular(${_double(props['radius'] ?? 8.0)}), borderSide: BorderSide(color: $borderColor, width: $borderWidth))';
  }

  final showHint = props['showHint'] != false;
  final showLabel = props['showLabel'] == true;
  final isFilled = props['filled'] != false;
  final isPassword = props['obscure'] == true;
  final lineCount = props['maxLines'] is num ? (props['maxLines'] as num).toInt() : 1;
  final keyboard = const {
    'number': 'TextInputType.number',
    'email': 'TextInputType.emailAddress',
    'phone': 'TextInputType.phone',
  }[props['keyboard']];

  // بخش‌های InputDecoration؛ فقط مواردی که روشن‌اند نوشته می‌شوند
  final decorationParts = [
    if (showHint) 'hintText: ${_stringLiteral(props['hint'])}',
    'hintStyle: TextStyle(color: $textColor.withValues(alpha: 0.5))',
    if (showLabel) 'labelText: ${_stringLiteral(props['label'])}',
    if (showLabel) 'labelStyle: TextStyle(color: $textColor.withValues(alpha: 0.7))',
    'filled: $isFilled',
    if (isFilled) 'fillColor: ${_colorLiteral(props['bg'] ?? 0xFFFFFFFF)}',
    'isDense: true',
    'contentPadding: EdgeInsets.all(${_double(props['padding'] ?? 12.0)})',
    'border: $border',
    'enabledBorder: $border',
    'focusedBorder: $border',
  ];

  return _constructorCall('TextField', level, {
    if (controllerName != null) 'controller': 'controller.${controllerName}Controller',
    if (isPassword) 'obscureText': 'true',
    if (!isPassword && lineCount > 1) 'maxLines': '$lineCount',
    if (keyboard != null) 'keyboardType': keyboard,
    'style': 'TextStyle(color: $textColor, fontSize: ${_double(props['size'] ?? 16.0)})',
    'decoration': 'InputDecoration(${decorationParts.join(', ')})',
  });
}

/// آیکن SVG (نیاز به پکیج flutter_svg)
String _emitSvg(Map<String, dynamic> props) =>
    'SvgPicture.string(${_stringLiteral(props['svg'])}, width: ${_double(props['size'])}, height: ${_double(props['size'])}, colorFilter: ColorFilter.mode(${_colorLiteral(props['color'])}, BlendMode.srcIn))';

/// آیکن متریال
String _emitIcon(Map<String, dynamic> props) =>
    'Icon(Icons.${_iconName(props['icon'])}, size: ${_double(props['size'])}, color: ${_colorLiteral(props['color'])})';

/// دکمه: ElevatedButton (filled) / OutlinedButton (outlined) / TextButton (text)
String _emitButton(WidgetNode node, int level) {
  final props = node.props;
  final actionName = _context?.names[node.id]; // در حالت پروژه: متد کنترلر (اگر action دارد)
  final shape =
      'RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_double(props['radius'] ?? 8.0)}))';
  final foreground = _colorLiteral(props['fg'] ?? 0xFFFFFFFF); // رنگ متن (و بردر در outlined)
  final boldCode = props['bold'] == true ? ', style: TextStyle(fontWeight: FontWeight.bold)' : '';
  final kind = props['kind'] ?? 'filled';
  final buttonClass = kind == 'outlined' ? 'OutlinedButton' : (kind == 'text' ? 'TextButton' : 'ElevatedButton');

  final String style;
  if (kind == 'outlined') {
    style = '$buttonClass.styleFrom(foregroundColor: $foreground, shape: $shape, side: BorderSide(color: $foreground, width: 1.5))';
  } else if (kind == 'text') {
    style = '$buttonClass.styleFrom(foregroundColor: $foreground, shape: $shape)';
  } else {
    style =
        '$buttonClass.styleFrom(backgroundColor: ${_colorLiteral(props['bg'])}, foregroundColor: $foreground, elevation: ${_double(props['elevation'] ?? 2.0)}, shape: $shape)';
  }
  return _constructorCall(buttonClass, level, {
    // دکمه‌ی داخل آیتم لیست، ردیف جاری (item) را هم به متد می‌دهد
    'onPressed': actionName == null
        ? '() {}' // بدون action: عملکرد را خودت می‌نویسی
        : (_context!.itemActions.contains(node.id) ? '() => controller.$actionName(item)' : 'controller.$actionName'),
    'style': style,
    'child': 'Text(${_stringLiteral(props['text'])}$boldCode)',
  });
}

/// آیتم ناوبری خارج از فوتر ناوبری (آیکن + متن زیرش)
String _emitNavItem(Map<String, dynamic> props) =>
    'Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.${_iconName(props['icon'])}), Text(${_stringLiteral(props['label'])})])';

/// تصویر شبکه‌ای با چهار گوشه‌ی مستقل؛ حالت banner (تمام‌عرض) یا fixed (ثابت)
String _emitImage(Map<String, dynamic> props, int level) {
  final url = _boundString(props['url']);
  // اگر آدرس از داده می‌آید، تا رسیدن/خطا یک آیکن جایگزین نشان بده
  final errorCode = hasBinding(props['url']) && _context != null
      ? ', errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)'
      : '';
  /// شعاع یک گوشه؛ اگر مقدار اختصاصی نبود از 'radius' قدیمی
  String cornerOf(String key) => _double(props[key] ?? props['radius']);
  final borderRadius =
      'BorderRadius.only(topLeft: Radius.circular(${cornerOf('rTL')}), topRight: Radius.circular(${cornerOf('rTR')}), bottomLeft: Radius.circular(${cornerOf('rBL')}), bottomRight: Radius.circular(${cornerOf('rBR')}))';

  final String content;
  if (props['mode'] == 'banner') {
    content =
        'AspectRatio(aspectRatio: ${_positiveOrNull(props['ratio']) ?? '1.78'}, child: Image.network(${url.code}, width: double.infinity, height: double.infinity, fit: BoxFit.cover$errorCode))';
  } else {
    final width = _positiveOrNull(props['width']);
    final height = _positiveOrNull(props['height']) ?? '150.0';
    content =
        'Image.network(${url.code}${width != null ? ', width: $width' : ''}, height: $height, fit: BoxFit.cover$errorCode)';
  }
  final image = _constructorCall('ClipRRect', level, {'borderRadius': borderRadius, 'child': content});
  return url.reactive ? 'Obx(() => $image)' : image;
}

// ============================================================================
// لیست داده‌ای و اتصال داده (binding)
// ============================================================================

/// یک رشته‌ی دارت (کد) که ممکن است به پاسخ سرور وابسته باشد
class _BoundString {
  final String code;
  final bool reactive; // وابسته به data (باید داخل Obx برود)
  const _BoundString(this.code, this.reactive);
}

/// عبارت دارت یک binding مثل item.title.
/// [self] پیشوند دسترسی به اعضای کنترلر است: 'controller.' داخل صفحه، '' داخل خود کنترلر.
String _bindingExpression(String path, String self, void Function() markReactive) {
  final dot = path.indexOf('.');
  final scope = dot < 0 ? path : path.substring(0, dot);
  final rest = dot < 0 ? '' : path.substring(dot + 1);
  switch (scope) {
    case 'item': // ردیف جاری لیست
      return "jsonPath(item, '$rest')";
    case 'data': // پاسخ سرور (واکنشی)
      markReactive();
      return "jsonPath(${self}data.value, '$rest')";
    case 'args': // مقدار ارسالی از صفحه‌ی قبل
      return "jsonPath(${self}args, '$rest')";
    case 'field': // متن یک فیلد متنی همین صفحه
      final variable = _context?.fieldVars[fieldKeyOf(rest)];
      return variable == null ? "''" : '$self${variable}Controller.text';
  }
  return "''";
}

/// متن با bindingها را به رشته‌ی دارت با interpolation تبدیل می‌کند:
/// «سلام {{item.name}}» → 'سلام ${jsonPath(item, 'name') ?? ''}'
/// خارج از حالت پروژه (خروجی تک‌صفحه) متن همان‌طور که هست نوشته می‌شود.
_BoundString _boundString(dynamic raw, {String self = 'controller.'}) {
  final text = '${raw ?? ''}';
  if (_context == null || !hasBinding(text)) return _BoundString(_stringLiteral(raw), false);
  var reactive = false;
  final buffer = StringBuffer("'");
  var last = 0;
  for (final match in kBindingPattern.allMatches(text)) {
    buffer.write(_escapeLiteralPart(text.substring(last, match.start)));
    final expression = _bindingExpression(match.group(1)!, self, () => reactive = true);
    buffer.write(expression.startsWith('jsonPath') ? '\${$expression ?? \'\'}' : '\${$expression}');
    last = match.end;
  }
  buffer.write(_escapeLiteralPart(text.substring(last)));
  buffer.write("'");
  return _BoundString(buffer.toString(), reactive);
}

/// مقدار ارسالی دکمه: اگر کل متن یک binding باشد خود مقدار (با نوع اصلی)، وگرنه رشته؛ خالی = null
String _boundValueExpression(String raw, String self) {
  final text = raw.trim();
  if (text.isEmpty) return 'null';
  final match = kBindingPattern.firstMatch(text);
  if (match != null && match.start == 0 && match.end == text.length) {
    return _bindingExpression(match.group(1)!, self, () {});
  }
  return _boundString(text, self: self).code;
}

/// لیست داده‌ای: فرزندان = قالب آیتم. به ازای هر ردیف controller.items یک نسخه ساخته می‌شود
/// (در حال دریافت = چرخان، خطا = پیام، خالی = emptyText).
String _emitDataList(WidgetNode node, int level) {
  final props = node.props;
  final spacing = _double(props['spacing'] ?? 8.0);
  final padding = _double(props['padding'] ?? 8.0);
  final template = node.children;

  // خروجی تک‌صفحه‌ای (بدون کنترلر): فقط خود قالب یک‌بار
  if (_context == null) {
    return _constructorCall('Padding', level, {
      'padding': 'EdgeInsets.all($padding)',
      'child': _constructorCall('Column', level + 1, {
        'spacing': spacing,
        'children': _listLiteral(template, level + 2),
      }),
    });
  }

  final itemCode = template.isEmpty
      ? 'const SizedBox.shrink()'
      : (template.length == 1
          ? _emitWidget(template.first, level + 5)
          : _constructorCall('Column', level + 5, {
              'crossAxisAlignment': 'CrossAxisAlignment.start',
              'mainAxisSize': 'MainAxisSize.min',
              'children': _listLiteral(template, level + 6),
            }));
  final i1 = _indent(level + 1), i2 = _indent(level + 2), i3 = _indent(level + 3), i4 = _indent(level + 4);
  final i5 = _indent(level + 5);
  return [
    'Obx(() {',
    '${i1}if (controller.isLoading.value) {',
    '${i2}return Padding(padding: EdgeInsets.all($padding), child: const Center(child: CircularProgressIndicator()));',
    '$i1}',
    '${i1}if (controller.errorMessage.value.isNotEmpty) {',
    '${i2}return Padding(padding: EdgeInsets.all($padding), child: Center(child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red))));',
    '$i1}',
    '${i1}if (controller.items.isEmpty) {',
    '${i2}return Padding(padding: EdgeInsets.all($padding), child: Center(child: Text(${_stringLiteral(props['emptyText'])})));',
    '$i1}',
    '${i1}return Padding(',
    '${i2}padding: EdgeInsets.all($padding),',
    '${i2}child: Column(',
    '${i3}spacing: $spacing,',
    '${i3}children: [',
    '${i4}for (final item in controller.items)',
    '$i5$itemCode,',
    '${i3}],',
    '${i2}),',
    '$i1);',
    '${_indent(level)}})',
  ].join('\n');
}

// ============================================================================
// تولید کد کل صفحه
// ============================================================================

/// نام کلاس پیش‌فرض: از اسم انگلیسی صفحه، وگرنه Page + چند رقم آخر id
String _defaultClassName(PageModel page) {
  final asciiName = page.name.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ').trim();
  if (asciiName.isEmpty || RegExp(r'^[0-9]').hasMatch(asciiName)) {
    return 'Page${page.id.substring(page.id.length - 4)}';
  }
  final words = asciiName.split(RegExp(r'\s+')).map((word) => word[0].toUpperCase() + word.substring(1));
  return '${words.join()}Page';
}

/// نام فایل از نام کلاس (HomePage → home_page.dart)
String _fileNameOf(String className) =>
    '${className.replaceAllMapped(RegExp(r'(?<=[a-z0-9])[A-Z]'), (match) => '_${match[0]}').toLowerCase()}.dart';

/// آیتم‌های ناوبری فوتر
List<WidgetNode> _navItemsOf(PageModel page) =>
    page.footer.children.where((child) => child.type == 'navItem').toList();

/// آیا فوتر این صفحه یکی از مدل‌های ناوبری است؟ (باید نمایان باشد و حداقل ۲ آیتم داشته باشد)
bool _hasNavigationFooter(PageModel page) =>
    page.footer.props['hidden'] != true &&
    '${page.footer.props['variant'] ?? 'bar'}' != 'bar' &&
    _navItemsOf(page).length >= 2;

/// نمونه‌ی (Variant) فعال فوتر ناوبری؛ برای فهمیدن import و پکیج لازم
Variant? _footerVariantOf(PageModel page) {
  if (!_hasNavigationFooter(page)) return null;
  final variantId = page.footer.props['variant'];
  return WidgetCatalog.of('footer').variants.where((variant) => variant.id == variantId).firstOrNull;
}

/// آیا در درخت ویجتی از این نوع هست؟
bool _containsType(WidgetNode node, String type) =>
    node.type == type || node.children.any((child) => _containsType(child, type));

bool _usesSvg(PageModel page) =>
    [page.appBar, page.body, page.footer].any((root) => _containsType(root, 'svg'));

/// خطوط pubspec که این صفحه نیاز دارد (برای کتابخانه‌ها)
List<String> _requiredDependencies(PageModel page) {
  final navigationDependency = _footerVariantOf(page)?.depLine;
  return [
    if (navigationDependency != null) navigationDependency,
    if (_usesSvg(page)) 'flutter_svg: ^2.0.10+1',
  ];
}

/// کد AppBar: حالت ساده (عنوان + actions) یا آزاد (Row دلخواه داخل title)
String _appBarCode(PageModel page) {
  final props = page.appBar.props;
  final height = _double(props['height'] ?? 56.0);
  if (props['variant'] == 'custom') {
    return _constructorCall('AppBar', 3, {
      'automaticallyImplyLeading': 'false',
      'toolbarHeight': height,
      'titleSpacing': '12.0',
      'backgroundColor': _colorLiteral(props['bg']),
      'foregroundColor': _colorLiteral(props['fg']),
      'title': _constructorCall('Row', 4, {
        'mainAxisAlignment': 'MainAxisAlignment.${props['main'] ?? 'spaceBetween'}',
        'children': _listLiteral(page.appBar.children, 5, allowExpanded: true),
      }),
    });
  }
  return _constructorCall('AppBar', 3, {
    'toolbarHeight': height,
    'title': 'Text(${_stringLiteral(props['title'])})',
    'backgroundColor': _colorLiteral(props['bg']),
    'foregroundColor': _colorLiteral(props['fg']),
    'actions': _listLiteral(page.appBar.children, 4),
  });
}

/// ناوبری فشرده (بدون پدینگ اضافه): آیتم‌ها کنار هم؛ با آیکن (متن زیرش) یا فقط متن
String _compactNavCode(
  List<WidgetNode> items,
  Map<String, dynamic> props,
  String background,
  String activeColor, {
  required bool showIcons,
}) {
  /// رنگ آیتم: فعال = رنگ انتخابی، غیرفعال = خاکستری
  String colorOf(int index) => '_index == $index ? $activeColor : Colors.grey';
  final itemCodes = [
    for (var index = 0; index < items.length; index++)
      showIcons
          ? 'Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _index = $index), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.${_iconName(items[index].props['icon'])}, size: 22.0, color: ${colorOf(index)}), Text(${_stringLiteral(items[index].props['label'])}, style: TextStyle(fontSize: 10.0, color: ${colorOf(index)}))])))'
          : 'Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _index = $index), child: Center(child: Text(${_stringLiteral(items[index].props['label'])}, style: TextStyle(fontSize: 13.0, color: ${colorOf(index)}, fontWeight: _index == $index ? FontWeight.bold : FontWeight.normal)))))',
  ];
  return _constructorCall('Container', 3, {
    'height': _double(props['height'] ?? 48.0),
    'color': background,
    'child': _constructorCall('Row', 4, {'children': _rawListLiteral(itemCodes, 5)}),
  });
}

/// کد bottomNavigationBar؛ اگر فوتر حذف شده یا خالی باشد null (یعنی نوشته نمی‌شود)
String? _footerCode(PageModel page) {
  final code = _footerCodeCore(page);
  if (code == null || _context == null || !_hasNavigationFooter(page)) return code;
  // حالت پروژه: وضعیت ناوبری در کنترلر است (navIndex) و فوتر داخل Obx می‌رود
  final projectCode = code
      .replaceAll('(i) => setState(() => _index = i)', 'controller.changeNavIndex')
      .replaceAllMapped(RegExp(r'setState\(\(\) => _index = (\d+)\)'), (match) => 'controller.changeNavIndex(${match[1]})')
      .replaceAll('_index', 'controller.navIndex.value');
  return 'Obx(() => $projectCode)';
}

String? _footerCodeCore(PageModel page) {
  final props = page.footer.props;
  if (props['hidden'] == true) return null;

  final background = _colorLiteral(props['bg']);
  final activeColor = _colorLiteral(props['sel'] ?? 0xFF3F51B5);

  // نوار ساده: یک Row از فرزندان
  if (!_hasNavigationFooter(page)) {
    if (page.footer.children.isEmpty) return null;
    return _constructorCall('Container', 3, {
      'height': _double(props['height']),
      'color': background,
      'child': _constructorCall('Row', 4, {
        'mainAxisAlignment': 'MainAxisAlignment.${props['main']}',
        'children': _listLiteral(page.footer.children, 5, allowExpanded: true),
      }),
    });
  }

  // مدل‌های ناوبری: صفحه Stateful می‌شود و `_index` آیتم فعال را نگه می‌دارد
  const onChange = '(i) => setState(() => _index = i)';
  final items = _navItemsOf(page);
  String iconOf(WidgetNode item) => 'Icons.${_iconName(item.props['icon'])}';
  String labelOf(WidgetNode item) => _stringLiteral(item.props['label']);

  switch ('${props['variant']}') {
    case 'nav_classic': // آیکن + متن، فشرده
      return _compactNavCode(items, props, background, activeColor, showIcons: true);
    case 'nav_m3':
      return _constructorCall('NavigationBar', 3, {
        'height': '64.0',
        'backgroundColor': background,
        'indicatorColor': '$activeColor.withValues(alpha: 0.2)',
        'selectedIndex': '_index',
        'onDestinationSelected': onChange,
        'destinations': _rawListLiteral([
          for (final item in items) 'NavigationDestination(icon: Icon(${iconOf(item)}), label: ${labelOf(item)})'
        ], 4),
      });
    case 'nav_text': // فقط متن
      return _compactNavCode(items, props, background, activeColor, showIcons: false);
    case 'lib_curved':
      return _constructorCall('CurvedNavigationBar', 3, {
        'index': '_index',
        'height': '50.0',
        'backgroundColor': 'Colors.transparent',
        'color': background,
        'buttonBackgroundColor': activeColor,
        'animationDuration': 'const Duration(milliseconds: 300)',
        'items': _rawListLiteral([for (final item in items) 'Icon(${iconOf(item)})'], 4),
        'onTap': onChange,
      });
    case 'lib_gnav':
      return _constructorCall('Container', 3, {
        'color': background,
        'child': _constructorCall('GNav', 4, {
          'gap': '6.0',
          'iconSize': '22.0',
          'color': 'Colors.grey',
          'activeColor': activeColor,
          'tabBackgroundColor': '$activeColor.withValues(alpha: 0.15)',
          'mainAxisAlignment': 'MainAxisAlignment.spaceEvenly',
          'padding': 'const EdgeInsets.symmetric(horizontal: 12, vertical: 8)',
          'selectedIndex': '_index',
          'onTabChange': onChange,
          'tabs': _rawListLiteral([for (final item in items) 'GButton(icon: ${iconOf(item)}, text: ${labelOf(item)})'], 5),
        }),
      });
  }
  return null;
}

/// کد Scaffold صفحه (اپ‌بار + بدنه + فوتر)؛ صفحه‌ی راست‌چین داخل Directionality می‌رود.
String _scaffoldCode(PageModel page) {
  final footerCode = _footerCode(page);
  // Scaffold: اپ‌بار (اگر حذف نشده) + بدنه‌ی اسکرول‌شونده + فوتر (اگر هست)
  final scaffold = _constructorCall('Scaffold', 2, {
    if (page.appBar.props['hidden'] != true) 'appBar': _appBarCode(page),
    'body': _constructorCall('SafeArea', 3, {
      'child': _constructorCall('SingleChildScrollView', 4, {
        'child': _constructorCall('SizedBox', 5, {
          'width': 'double.infinity',
          'child': _emitWidget(page.body, 6),
        }),
      }),
    }),
    if (footerCode != null) 'bottomNavigationBar': footerCode,
  });

  // صفحه‌ی راست‌چین داخل Directionality می‌رود (کد Scaffold دو فاصله جلوتر نوشته می‌شود)
  final scaffoldCode = page.direction == 'rtl'
      ? _constructorCall('Directionality', 2, {
          'textDirection': 'TextDirection.rtl',
          'child': scaffold.replaceAll('\n', '\n  '),
        })
      : scaffold;

  return scaffoldCode;
}

/// کد کامل فایل یک صفحه: import ها + کلاس (Stateless، یا Stateful اگر ناوبری دارد)
String _generatePage(PageModel page, String className) {
  final isStateful = _hasNavigationFooter(page);

  final scaffoldCode = _scaffoldCode(page);

  // importهای لازم: material + (کتابخانه‌ی ناوبری) + (flutter_svg)
  final libraryImport = _footerVariantOf(page)?.importLine;
  final imports = [
    if (libraryImport != null) libraryImport,
    if (_usesSvg(page)) "import 'package:flutter_svg/flutter_svg.dart';",
  ];
  final header =
      "import 'package:flutter/material.dart';${imports.map((line) => '\n$line').join()}\n\n/// Generated by Page Builder\n";

  if (!isStateful) {
    return '''${header}class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return $scaffoldCode;
  }
}
''';
  }
  return '''${header}class $className extends StatefulWidget {
  const $className({super.key});

  @override
  State<$className> createState() => _${className}State();
}

class _${className}State extends State<$className> {
  int _index = 0; // آیتم فعال ناوبری

  @override
  Widget build(BuildContext context) {
    return $scaffoldCode;
  }
}
''';
}

// ============================================================================
// چک‌باکس و رادیو
// ============================================================================

/// چک‌باکس؛ در حالت پروژه با متغیر واکنشی کنترلر (Obx) کار می‌کند.
String _emitCheckbox(WidgetNode node) {
  final props = node.props;
  final memberName = _context?.names[node.id];
  final active = _colorLiteral(props['activeColor'] ?? 0xFF3F51B5);
  final isFilled = props['filled'] != false;
  final valueExpression = memberName != null ? 'controller.$memberName.value' : '${props['value'] == true}';
  final changeExpression = memberName != null ? 'controller.toggle${_capitalize(memberName)}' : '(_) {}';

  final checkbox =
      'Checkbox(value: $valueExpression, onChanged: $changeExpression, activeColor: ${isFilled ? active : 'Colors.transparent'}, checkColor: ${isFilled ? _colorLiteral(props['checkColor'] ?? 0xFFFFFFFF) : active}, side: BorderSide(color: $active, width: 2.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_double(props['radius'] ?? 4.0)})))';
  final withLabel = _withLabelCode(checkbox, props);
  return memberName != null ? 'Obx(() => $withLabel)' : withLabel;
}

/// رادیو باتن؛ در حالت پروژه، انتخاب‌شده بودن از متغیر گروه کنترلر خوانده می‌شود.
String _emitRadio(WidgetNode node) {
  final props = node.props;
  final memberName = _context?.names[node.id];
  final active = _colorLiteral(props['activeColor'] ?? 0xFF3F51B5);
  final isFilled = props['filled'] == true;
  final diameterValue = props['size'] is num ? (props['size'] as num).toDouble() : 22.0;
  final diameter = _double(diameterValue);
  final dotSize = _double(diameterValue * 0.5);
  final optionValue = _stringLiteral(props['value']);
  final selectedExpression =
      memberName != null ? 'controller.$memberName.value == $optionValue' : '${props['selected'] == true}';
  final onTap = memberName != null ? '() => controller.select${_capitalize(memberName)}($optionValue)' : '() {}';

  // توپر: کل دایره پر می‌شود؛ توخالی: یک نقطه‌ی کوچک داخل حلقه
  final innerDot =
      'Center(child: Container(width: $dotSize, height: $dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: $active)))';
  final circle = isFilled
      ? 'Container(width: $diameter, height: $diameter, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: $active, width: 2.0), color: $selectedExpression ? $active : Colors.transparent))'
      : 'Container(width: $diameter, height: $diameter, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: $active, width: 2.0)), child: $selectedExpression ? $innerDot : null)';
  final withLabel = _withLabelCode('GestureDetector(onTap: $onTap, child: $circle)', props);
  return memberName != null ? 'Obx(() => $withLabel)' : withLabel;
}

/// کنترل (چک‌باکس/رادیو) را همراه متن کنارش (اگر showLabel روشن است) در یک Row می‌نویسد.
String _withLabelCode(String control, Map<String, dynamic> props) {
  if (props['showLabel'] != true) return control;
  return 'Row(mainAxisSize: MainAxisSize.min, children: [$control, const SizedBox(width: 8), Text(${_stringLiteral(props['label'])}, style: TextStyle(color: ${_colorLiteral(props['fg'])}, fontSize: ${_double(props['labelSize'] ?? 14.0)}))])';
}

// ============================================================================
// تب‌بندی
// ============================================================================

/// تب‌بندی (نوار تب + محتوای تب فعال با انیمیشن).
/// در حالت پروژه، شماره‌ی تب فعال در کنترلر نگه داشته می‌شود (RxInt) و با Obx به‌روز می‌شود.
String _emitTabs(WidgetNode node, int level) {
  final props = node.props;
  final tabItems = node.children.where((child) => child.type == 'tabItem').toList();
  if (tabItems.isEmpty) return 'const SizedBox.shrink()';

  final memberName = _context?.names[node.id];
  final indexExpression = memberName != null ? 'controller.${memberName}Index.value' : '0';
  final style = '${props['style'] ?? 'underline'}';
  final activeColor = _colorLiteral(props['activeColor'] ?? 0xFF3F51B5);
  final activeTextColor = _colorLiteral(props['activeTextColor'] ?? props['activeColor'] ?? 0xFF3F51B5);
  final inactiveColor = _colorLiteral(props['inactiveColor'] ?? 0xFF757575);
  final barColor = _colorLiteral(props['barColor'] ?? 0);
  final labelSizeValue = props['labelSize'] is num ? (props['labelSize'] as num).toDouble() : 14.0;
  final labelSize = _double(labelSizeValue);
  final radiusValue = props['radius'] is num ? (props['radius'] as num).toDouble() : 20.0;
  final radius = _double(radiusValue);
  final indicatorHeight = _double(props['indicatorHeight'] ?? 3.0);
  final showIcons = props['showIcons'] == true;
  final isScrollable = props['scrollable'] == true;
  final boldActive = props['bold'] != false;
  final isSegmented = style == 'segmented';

  /// سربرگ یک تب (فعال بودنش در زمان اجرا از روی شماره‌ی تب فعال تعیین می‌شود)
  String header(int index) {
    final isActive = '$indexExpression == $index';
    final color = '($isActive ? $activeTextColor : $inactiveColor)';
    final String decoration;
    if (style == 'underline') {
      decoration =
          'BoxDecoration(border: Border(bottom: BorderSide(color: $isActive ? $activeColor : Colors.transparent, width: $indicatorHeight)))';
    } else if (style == 'pill' || isSegmented) {
      decoration =
          'BoxDecoration(color: $isActive ? $activeColor : Colors.transparent, borderRadius: BorderRadius.circular($radius))';
    } else {
      decoration = 'const BoxDecoration()';
    }
    final onTap = memberName != null ? '() => controller.select${_capitalize(memberName)}Tab($index)' : '() {}';
    final iconCode = showIcons
        ? 'Icon(Icons.${_iconName(tabItems[index].props['icon'])}, size: ${_double(labelSizeValue + 4)}, color: $color), const SizedBox(width: 6.0), '
        : '';
    final weight = boldActive ? '$isActive ? FontWeight.bold : FontWeight.normal' : 'FontWeight.normal';
    return 'GestureDetector(behavior: HitTestBehavior.opaque, onTap: $onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), decoration: $decoration, child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [${iconCode}Text(${_stringLiteral(tabItems[index].props['label'])}, style: TextStyle(color: $color, fontSize: $labelSize, fontWeight: $weight))])))';
  }

  // نوار: اسکرولی یا هم‌عرض؛ سبک segmented یک قاب دور نوار دارد
  final headers = [for (var index = 0; index < tabItems.length; index++) header(index)];
  final barRow = isScrollable
      ? 'SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [${headers.join(', ')}]))'
      : 'Row(children: [${headers.map((header) => 'Expanded(child: $header)').join(', ')}])';
  final segmentedRadius = isSegmented ? ', borderRadius: BorderRadius.circular(${_double(radiusValue + 4)})' : '';
  final bar =
      'Container(padding: ${isSegmented ? 'const EdgeInsets.all(4.0)' : 'EdgeInsets.zero'}, decoration: BoxDecoration(color: $barColor$segmentedRadius), child: $barRow)';

  // محتوای تب فعال با انیمیشن (fade پیش‌فرض AnimatedSwitcher است)
  final animationName = '${props['animation'] ?? 'fade'}';
  final milliseconds = animationName == 'none' ? 0 : (props['duration'] is num ? (props['duration'] as num).toInt() : 250);
  final transition = animationName == 'slide'
      ? 'transitionBuilder: (child, animation) => SlideTransition(position: Tween<Offset>(begin: const Offset(0.2, 0.0), end: Offset.zero).animate(animation), child: FadeTransition(opacity: animation, child: child)), '
      : (animationName == 'scale'
          ? 'transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child), '
          : '');
  final contents = [
    for (final tab in tabItems)
      tab.children.isEmpty
          ? 'const SizedBox.shrink()'
          : 'Column(crossAxisAlignment: CrossAxisAlignment.start, children: ${_listLiteral(tab.children, level + 3)})',
  ];
  final content =
      'AnimatedSwitcher(duration: Duration(milliseconds: $milliseconds), ${transition}child: KeyedSubtree(key: ValueKey<int>($indexExpression), child: [${contents.join(', ')}][$indexExpression]))';

  final gap = 'SizedBox(height: ${_double(props['gap'] ?? 8.0)})';
  final isBottom = props['barPosition'] == 'bottom';
  final column =
      'Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [${isBottom ? '$content, $gap, $bar' : '$bar, $gap, $content'}])';
  return memberName != null ? 'Obx(() => $column)' : column;
}

// ============================================================================
// حالت «پروژه»: صفحه با کنترلر GetX
// ============================================================================

/// صفحه‌ی مقصد یک دکمه‌ی ناوبری: نام ثابت مسیر در AppRoutes و نام PascalCase صفحه
class PageTarget {
  final String route, pascal;
  const PageTarget(this.route, this.pascal);
}

/// زمینه‌ی تولید کد با کنترلر: اسم متغیرها را نگه می‌دارد و اعضای کنترلر را جمع می‌کند.
/// (فقط هنگام تولید یک صفحه‌ی پروژه مقدار دارد؛ در خروجی تک‌صفحه‌ای null است.)
class _ControllerContext {
  /// اسم متغیر/متد کنترلر برای هر گره‌ی تعاملی (شناسه‌ی گره ← اسم)
  final Map<String, String> names = {};

  /// اسم متغیر هر گروه رادیو (نام گروه ← اسم متغیر)
  final Map<String, String> radioGroups = {};

  /// خطوط فیلدها، متدها و dispose های کنترلر
  final List<String> fields = [];
  final List<String> methods = [];
  final List<String> disposals = [];

  /// صفحه‌های مقصد ناوبری (شناسه‌ی صفحه ← مسیر و نام کلاس)
  final Map<String, PageTarget> targets;

  /// پاسخ سرور با نوع مدل (اگر برای درخواست صفحه نوع پاسخ انتخاب شده باشد)
  final TypedResponse? typedResponse;

  /// نام فیلد متنی (props.name به‌صورت شناسه) ← اسم متغیر کنترلر آن
  final Map<String, String> fieldVars = {};

  /// دکمه‌هایی که متدشان ردیف جاری لیست (item) را هم می‌گیرد
  final Set<String> itemActions = {};

  /// import های اضافه‌ی کنترلر و دستورهای onInit
  final List<String> imports = [];
  final List<String> initLines = [];

  /// آیا صفحه به داده‌ی سرور / args / لیست نیاز دارد؟ (فیلدهای isLoading و data و items ساخته می‌شوند)
  bool usesData = false;

  _ControllerContext(this.targets, [this.typedResponse]);

  final Set<String> _usedNames = {'navIndex', 'response'}; // navIndex و response رزرو هستند

  /// یک اسم یکتا می‌سازد (در صورت تکرار، عدد اضافه می‌شود)
  String unique(String base) {
    var candidate = base;
    var counter = 2;
    while (!_usedNames.add(candidate)) {
      candidate = '$base$counter';
      counter++;
    }
    return candidate;
  }
}

_ControllerContext? _context;

String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// متن را به شناسه‌ی camelCase انگلیسی تبدیل می‌کند؛ اگر نشد [fallback] را برمی‌گرداند.
String _identifier(dynamic raw, String fallback) {
  final words = '${raw ?? ''}'.split(RegExp(r'[^A-Za-z0-9]+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return fallback;
  final camel = words.first[0].toLowerCase() + words.first.substring(1) + words.skip(1).map(_capitalize).join();
  return RegExp(r'^[a-z]').hasMatch(camel) ? camel : fallback;
}

/// همه‌ی گره‌ها (خود گره + فرزندان)
Iterable<WidgetNode> _flatten(WidgetNode node) sync* {
  yield node;
  for (final child in node.children) {
    yield* _flatten(child);
  }
}

/// ویجت‌های تعاملی صفحه را پیدا می‌کند و برایشان فیلد/متد کنترلر می‌سازد.
void _collectMembers(PageModel page, _ControllerContext context) {
  final roots = [
    if (page.appBar.props['hidden'] != true) page.appBar,
    page.body,
    if (page.footer.props['hidden'] != true) page.footer,
  ];
  final radioInitialValues = <String, String>{}; // متغیر گروه ← مقدار اولیه
  final navigationButtons = <WidgetNode>[];

  for (final node in roots.expand(_flatten)) {
    final props = node.props;
    switch (node.type) {
      case 'textField':
        final name = context.unique(_identifier(props['name'], 'field'));
        context.names[node.id] = name;
        context.fieldVars.putIfAbsent(_identifier(props['name'], 'field'), () => name);
        context.fields.add('final TextEditingController ${name}Controller = TextEditingController();');
        context.disposals.add('${name}Controller.dispose();');
        break;
      case 'checkbox':
        final name = context.unique(_identifier(props['name'], 'checkbox'));
        context.names[node.id] = name;
        context.fields.add('final RxBool $name = ${props['value'] == true}.obs;');
        context.methods.add('void toggle${_capitalize(name)}(bool? value) => $name.value = value ?? false;');
        break;
      case 'radio':
        final groupKey = _identifier(props['group'], 'radioGroup');
        final variableName = context.radioGroups.putIfAbsent(groupKey, () => context.unique(groupKey));
        context.names[node.id] = variableName;
        radioInitialValues.putIfAbsent(variableName, () => '');
        // رادیوی انتخاب‌شده‌ی اولیه، مقدار اولیه‌ی گروه می‌شود
        if (props['selected'] == true && radioInitialValues[variableName]!.isEmpty) {
          radioInitialValues[variableName] = '${props['value'] ?? ''}';
        }
        break;
      case 'tabs':
        final name = context.unique(_identifier(props['name'], 'tabs'));
        context.names[node.id] = name;
        context.fields.add('final RxInt ${name}Index = 0.obs;');
        context.methods.add('void select${_capitalize(name)}Tab(int index) => ${name}Index.value = index;');
        break;
      case 'button':
        // ناوبری به صفحه‌ی دیگر (به‌جای action): بعد از جمع‌شدن فیلدها ساخته می‌شود
        if (context.targets.containsKey('${props['navTo'] ?? ''}')) {
          navigationButtons.add(node);
          break;
        }
        final action = _identifier(props['action'], '');
        if (action.isNotEmpty) {
          final name = context.unique(action);
          context.names[node.id] = name;
          context.methods.add('/// TODO: کار مربوط به بکند (دکمه‌ی «${props['text'] ?? ''}») را اینجا بنویس.\nvoid $name() {\n  // TODO\n}');
        }
        break;
    }
  }

  // ---------- ناوبری: Get.toNamed با مقدار ارسالی ----------
  var hasNavigation = false;
  for (final node in navigationButtons) {
    final props = node.props;
    final target = context.targets['${props['navTo']}']!;
    final name = context.unique('goTo${target.pascal}');
    context.names[node.id] = name;
    final navValue = '${props['navValue'] ?? ''}';
    // اگر مقدار از ردیف لیست می‌آید ({{item.id}})، متد خودش ردیف را به‌عنوان پارامتر می‌گیرد
    final needsItem = RegExp(r'\{\{\s*item[.\s}]').hasMatch(navValue);
    if (needsItem) context.itemActions.add(node.id);
    final value = _boundValueExpression(navValue, '');
    final argument = value == 'null' ? '' : ', arguments: $value';
    hasNavigation = true;
    context.methods.add('/// رفتن به صفحه‌ی ${target.pascal} (دکمه‌ی «${props['text'] ?? ''}») و فرستادن مقدار به آن.\n'
        'void $name(${needsItem ? 'dynamic item' : ''}) => Get.toNamed(AppRoutes.${target.route}$argument);');
  }
  if (hasNavigation) context.imports.add("import '../../../../app/routes/app_routes.dart';");

  // ---------- داده‌ی سرور: وضعیت دریافت + پاسخ + ردیف‌های لیست ----------
  final request = page.request;
  final usesBindings = roots
      .expand(_flatten)
      .any((node) => node.type == 'dataList' || node.props.values.any(hasBinding));
  context.usesData = request.enabled || usesBindings;
  if (context.usesData) {
    context.imports.add("import '../../../../app/core/json_path.dart';");
    context.fields.insertAll(0, [
      'final RxBool isLoading = false.obs;',
      "final RxString errorMessage = ''.obs;",
      'final Rxn<dynamic> data = Rxn<dynamic>(); // کل پاسخ سرور ({{data.xxx}})',
      'final RxList<dynamic> items = <dynamic>[].obs; // ردیف‌های لیست داده‌ای',
      'dynamic get args => Get.arguments; // مقدار ارسالی از صفحه‌ی قبل ({{args}})',
      if (request.enabled && context.typedResponse != null) context.typedResponse!.field,
    ]);
  }
  if (request.enabled) {
    final typed = context.typedResponse;
    if (typed != null && typed.importLine.isNotEmpty) context.imports.add(typed.importLine);
    context.initLines.add('load();');
    context.methods.add(r'''/// دریافت اطلاعات از سرور؛ هنگام ورود به صفحه خودکار صدا زده می‌شود (برای تلاش دوباره: load()).
Future<void> load() async {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    final result = await _repository.fetch(args?.toString());
    data.value = result;
    final payload = jsonPath(result, ''' +
        _stringLiteral(request.dataPath.trim()) +
        r''');
    items.assignAll(payload is List ? payload : const <dynamic>[]);
''' +
        (typed == null ? '' : '    ${typed.assign}\n') +
        r'''  } catch (error) {
    errorMessage.value = 'خطا در دریافت اطلاعات: $error';
  } finally {
    isLoading.value = false;
  }
}''');
  }

  // فیلد و متد هر گروه رادیو (یک بار برای هر گروه)
  radioInitialValues.forEach((variableName, initialValue) {
    context.fields.add('final RxString $variableName = ${_stringLiteral(initialValue)}.obs;');
    context.methods.add("void select${_capitalize(variableName)}(String? value) => $variableName.value = value ?? '';");
  });

  // ناوبری پایین: شماره‌ی آیتم فعال در کنترلر نگه داشته می‌شود
  if (_hasNavigationFooter(page)) {
    context.fields.add('final RxInt navIndex = 0.obs;');
    context.methods.add('void changeNavIndex(int index) => navIndex.value = index;');
  }
}

/// نتیجه‌ی تولید یک صفحه‌ی پروژه: کد صفحه + اعضایی که باید در کنترلرش نوشته شود
class GeneratedControllerPage {
  /// متن فایل صفحه (GetView)
  final String pageSource;

  /// فیلدها، متدها (چندخطی) و دستورهای dispose برای کنترلر
  final List<String> controllerFields;
  final List<String> controllerMethods;
  final List<String> controllerDisposals;

  /// پکیج‌هایی که صفحه نیاز دارد (خطوط pubspec)
  final List<String> dependencies;

  /// importهای اضافه‌ی کنترلر و دستورهایی که در onInit اجرا می‌شوند (مثل load();)
  final List<String> controllerImports;
  final List<String> controllerInit;

  const GeneratedControllerPage({
    this.controllerImports = const [],
    this.controllerInit = const [],
    required this.pageSource,
    required this.controllerFields,
    required this.controllerMethods,
    required this.controllerDisposals,
    required this.dependencies,
  });
}

/// صفحه را با کنترلر GetX می‌سازد (GetView) و اعضای لازم کنترلر را برمی‌گرداند.
GeneratedControllerPage _generateControllerPage(
  PageModel page, {
  required String className,
  required String controllerClass,
  required String controllerImport,
  Map<String, PageTarget> targets = const {},
  TypedResponse? typedResponse,
}) {
  final context = _ControllerContext(targets, typedResponse);
  _context = context; // از همین‌جا اسم فیلدها و مقصدها برای تولید bindingها لازم است
  try {
    _collectMembers(page, context);
    final scaffoldCode = _scaffoldCode(page);
    final libraryImport = _footerVariantOf(page)?.importLine;
    final imports = [
      "import 'package:flutter/material.dart';",
      "import 'package:get/get.dart';",
      if (libraryImport != null) libraryImport,
      if (_usesSvg(page)) "import 'package:flutter_svg/flutter_svg.dart';",
      if (context.usesData) "import '../../../../app/core/json_path.dart';",
      "import '$controllerImport';",
    ];
    final source = """${imports.join('\n')}

/// Generated by Page Builder
class $className extends GetView<$controllerClass> {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return $scaffoldCode;
  }
}
""";
    return GeneratedControllerPage(
      pageSource: source,
      controllerFields: context.fields,
      controllerMethods: context.methods,
      controllerDisposals: context.disposals,
      controllerImports: context.imports,
      controllerInit: context.initLines,
      dependencies: ['get: ^4.6.6', ..._requiredDependencies(page)],
    );
  } finally {
    _context = null; // زمینه فقط هنگام تولید همین صفحه معتبر است
  }
}

// ============================================================================
// نمای عمومی (تنها چیزی که لایه‌های بالاتر می‌بینند)
// ============================================================================

/// نمای عمومی تولید کد؛ لایه‌های بالاتر فقط از همین کلاس استفاده می‌کنند.
class DartCodeGenerator {
  const DartCodeGenerator();

  /// کد کامل یک صفحه (محتوای فایل .dart)
  String page(PageModel page, String className) => _generatePage(page, className);

  /// کد یک ویجت تکی (برای نمایشگاه ویجت‌ها)
  String snippet(WidgetNode node) => _emitWidget(node, 0);

  /// نام کلاس پیشنهادی برای یک صفحه
  String suggestClassName(PageModel page) => _defaultClassName(page);

  /// نام فایل از روی نام کلاس
  String fileName(String className) => _fileNameOf(className);

  /// خطوط pubspec که این صفحه نیاز دارد
  List<String> dependencies(PageModel page) => _requiredDependencies(page);

  /// صفحه‌ی یک پروژه با کنترلر GetX (برای خروجی کامل پروژه)
  GeneratedControllerPage controllerPage(
    PageModel page, {
    required String className,
    required String controllerClass,
    required String controllerImport,
    Map<String, PageTarget> targets = const {},
    TypedResponse? typedResponse,
  }) =>
      _generateControllerPage(page,
          className: className,
          controllerClass: controllerClass,
          controllerImport: controllerImport,
          targets: targets,
          typedResponse: typedResponse);
}
