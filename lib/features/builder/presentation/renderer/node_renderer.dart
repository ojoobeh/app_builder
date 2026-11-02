import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../domain/bindings/bindings.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../theme/icon_registry.dart';
import 'preview_state.dart';

/// محیط رندر: به رندر می‌گوید در چه حالتی ویجت‌ها را بکشد.
/// (رندر مستقیم به هیچ کنترلری وابسته نیست؛ همه‌چیز از همین‌جا می‌آید.)
class RenderEnv {
  /// true = حالت ویرایش (ویجت‌ها قابل انتخاب‌اند)؛ false = پیش‌نمایش
  final bool edit;

  /// شناسه‌ی ویجتی که الان انتخاب شده (برای کشیدن قاب آبی دورش)
  final String? selectedId;

  /// وقتی روی یک ویجت می‌زنیم، شناسه‌اش به این تابع داده می‌شود
  final void Function(String id)? onSelect;

  /// دامنه‌های داده برای bindingها در حالت اجرا: {'data': پاسخ سرور، 'args': مقدار ورودی صفحه، 'item': ردیف جاری}.
  /// خالی بودن یعنی «اجرا نمی‌شویم» (ادیتور/گالری) و متن‌های {{...}} همان‌طور که هستند دیده می‌شوند.
  final Map<String, dynamic> scope;

  /// وضعیت درخواست صفحه (فقط در حالت اجرا): در حال دریافت / پیام خطا / ردیف‌های لیست (null = داده‌ای نداریم)
  final bool loading;
  final String? error;
  final List<dynamic>? items;

  /// کلیک دکمه‌ی دارای ناوبری: شناسه‌ی صفحه‌ی مقصد و مقدار ارسالی (فقط در حالت اجرا)
  final void Function(String pageId, String value)? onNavigate;

  const RenderEnv({
    this.edit = true,
    this.selectedId,
    this.onSelect,
    this.scope = const {},
    this.loading = false,
    this.error,
    this.items,
    this.onNavigate,
  });

  /// نمایش ساده بدون انتخاب (برای پیش‌نمایش‌ها و گالری)
  static const preview = RenderEnv(edit: false);

  /// آیا bindingها باید با داده جایگزین شوند؟
  bool get resolves => !edit && scope.isNotEmpty;

  /// همین محیط، با یک ردیف داده به‌عنوان {{item}}
  RenderEnv withItem(dynamic item) => RenderEnv(
        edit: edit,
        selectedId: selectedId,
        onSelect: onSelect,
        scope: {...scope, 'item': item},
        loading: loading,
        error: error,
        items: items,
        onNavigate: onNavigate,
      );
}

/// متن را (اگر در حالت اجرا هستیم) با داده‌ی bindingها پر می‌کند.
String _bound(dynamic raw, RenderEnv env) {
  final text = '${raw ?? ''}';
  if (!env.resolves || !hasBinding(text)) return text;
  return resolveBindings(text, {...env.scope, 'field': PreviewState.fields});
}

// ============================================================================
// توابع کمکی: تبدیل مقدارهای ذخیره‌شده در props به نوع‌های Flutter
// ============================================================================

/// مقدار را به double تبدیل می‌کند؛ اگر عدد نبود از [fallback] استفاده می‌کند.
double _toDouble(dynamic value, [double fallback = 0]) => value is num ? value.toDouble() : fallback;

/// عدد مثبت را برمی‌گرداند؛ ۰ یا منفی یعنی «خودکار» و null برمی‌گردد.
double? _positiveOrNull(dynamic value) => _toDouble(value) <= 0 ? null : _toDouble(value);

/// عدد ARGB ذخیره‌شده را به Color تبدیل می‌کند.
Color _toColor(dynamic value, [Color fallback = Colors.black]) => value is int ? Color(value) : fallback;

/// نام چینش ('center'، 'spaceBetween' و ...) را به MainAxisAlignment تبدیل می‌کند.
MainAxisAlignment _mainAxisFrom(dynamic name) =>
    MainAxisAlignment.values.firstWhere((option) => option.name == name, orElse: () => MainAxisAlignment.start);

/// نام چینش متقاطع را به CrossAxisAlignment تبدیل می‌کند.
CrossAxisAlignment _crossAxisFrom(dynamic name) =>
    CrossAxisAlignment.values.firstWhere((option) => option.name == name, orElse: () => CrossAxisAlignment.start);

/// نام تراز ('topLeft'، 'center' و ...) را به Alignment تبدیل می‌کند.
Alignment _alignmentFrom(dynamic name) =>
    const {
      'topLeft': Alignment.topLeft, 'topCenter': Alignment.topCenter, 'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft, 'center': Alignment.center, 'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft, 'bottomCenter': Alignment.bottomCenter, 'bottomRight': Alignment.bottomRight,
    }[name] ??
    Alignment.center;

/// شعاع یک گوشه‌ی تصویر؛ اگر مقدار اختصاصی نبود از 'radius' قدیمی استفاده می‌کند.
double _cornerRadius(Map<String, dynamic> props, String key) => _toDouble(props[key] ?? props['radius']);

// ============================================================================
// ابزارهای ادیتور
// ============================================================================

/// جعبه‌ی خاکستری کوچکی که برای کانتینر خالی نشان داده می‌شود (فقط در حالت ویرایش)
Widget _emptyContainerHint(String label) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );

/// ویجت را قابل‌انتخاب می‌کند: با لمس انتخاب می‌شود و اگر انتخاب‌شده باشد قاب آبی می‌گیرد.
Widget _makeSelectable(WidgetNode node, Widget content, RenderEnv env) {
  final isSelected = env.selectedId == node.id;
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => env.onSelect?.call(node.id),
    child: Container(
      // foregroundDecoration روی ویجت کشیده می‌شود و اندازه‌ی چیدمان را عوض نمی‌کند
      foregroundDecoration: BoxDecoration(border: isSelected ? Border.all(color: Colors.blue, width: 2) : null),
      child: content,
    ),
  );
}

// ============================================================================
// تابع اصلی: تبدیل یک گره (WidgetNode) به ویجت واقعی Flutter
// ============================================================================

/// [node] را به ویجت Flutter تبدیل می‌کند (و فرزندانش را به‌صورت بازگشتی).
/// [canExpand] یعنی والد (Row / فوتر / اپ‌بار آزاد) اجازه‌ی Expanded می‌دهد.
Widget renderNode(WidgetNode node, RenderEnv env, {bool canExpand = false}) {
  final props = node.props;

  // اپ‌بار یا فوتری که کاربر حذف کرده نشان داده نمی‌شود
  if (props['hidden'] == true) return const SizedBox.shrink();

  // آیا فرزندان این گره اجازه‌ی Expanded دارند؟
  final childrenCanExpand =
      node.type == 'row' || node.type == 'footer' || (node.type == 'appBar' && props['variant'] == 'custom');
  // لیست داده‌ای فرزندانش را خودش (به ازای هر ردیف) می‌سازد
  final childWidgets = node.type == 'dataList'
      ? <Widget>[]
      : node.children.map((child) => renderNode(child, env, canExpand: childrenCanExpand)).toList();

  // کانتینر خالی در ادیتور یک راهنما نشان می‌دهد تا قابل‌لمس باشد
  final visibleChildren = (childWidgets.isEmpty && env.edit)
      ? (node.type == 'dataList' ? <Widget>[] : [_emptyContainerHint(WidgetCatalog.of(node.type).label)])
      : childWidgets;

  // ساخت ویجت مناسب هر نوع
  final Widget built;
  switch (node.type) {
    case 'appBar':
      built = _buildAppBar(props, childWidgets, visibleChildren);
      break;
    case 'footer':
      built = _buildFooter(node, visibleChildren, env);
      break;
    case 'navItem':
      built = _buildNavItem(props);
      break;
    case 'column':
      built = _buildColumn(props, visibleChildren);
      break;
    case 'row':
      built = _buildRow(props, visibleChildren);
      break;
    case 'stack':
      built = _buildStack(props, visibleChildren);
      break;
    case 'container':
      built = _buildContainer(props, visibleChildren);
      break;
    case 'card':
      built = _buildCard(props, visibleChildren);
      break;
    case 'text':
      built = _buildText(props, env);
      break;
    case 'textField':
      built = _buildTextField(props, env.edit);
      break;
    case 'svg':
      built = _buildSvg(props);
      break;
    case 'icon':
      built = _buildIcon(props);
      break;
    case 'button':
      built = _buildButton(props, env);
      break;
    case 'checkbox':
      built = _buildCheckbox(node, env.edit);
      break;
    case 'radio':
      built = _buildRadio(node, env.edit);
      break;
    case 'tabs':
      built = _buildTabs(node, childWidgets, env);
      break;
    case 'tabItem':
      built = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: visibleChildren);
      break;
    case 'image':
      built = _buildImage(props, env);
      break;
    case 'dataList':
      built = _buildDataList(node, env);
      break;
    default:
      built = const SizedBox.shrink();
  }

  // در حالت ویرایش، ویجت قابل انتخاب می‌شود
  final result = env.edit ? _makeSelectable(node, built, env) : built;

  // ضریب Expanded: فقط وقتی والد Row/فوتر است (در Column داخل اسکرول خطا می‌دهد)
  final flexValue = props['flex'];
  if (canExpand && flexValue is num && flexValue > 0) {
    return Expanded(flex: flexValue.toInt(), child: result);
  }
  return result;
}

// ============================================================================
// سازنده‌ی هر نوع ویجت (هرکدام فقط props خودش را می‌خواند)
// ============================================================================

/// اپ‌بار: حالت ساده (عنوان + آیکن‌ها) یا حالت آزاد (یک Row دلخواه)
Widget _buildAppBar(Map<String, dynamic> props, List<Widget> actions, List<Widget> visibleChildren) {
  final isCustomLayout = props['variant'] == 'custom';
  final barHeight = _toDouble(props['height'], 56);
  return SizedBox(
    height: barHeight,
    child: AppBar(
      primary: false, // بدون فضای نوار وضعیت (داخل ادیتور است)
      automaticallyImplyLeading: false,
      toolbarHeight: barHeight,
      centerTitle: false,
      titleSpacing: isCustomLayout ? 12 : null,
      backgroundColor: _toColor(props['bg']),
      foregroundColor: _toColor(props['fg']),
      // حالت آزاد: فرزندان در یک Row؛ حالت ساده: عنوان + فرزندان به‌عنوان actions
      title: isCustomLayout
          ? Row(mainAxisAlignment: _mainAxisFrom(props['main']), children: visibleChildren)
          : Text(props['title'] ?? ''),
      actions: isCustomLayout ? null : actions,
    ),
  );
}

/// یک آیتم ناوبری (آیکن + متن)؛ وقتی فوتر حالت ناوبری ندارد به همین شکل دیده می‌شود
Widget _buildNavItem(Map<String, dynamic> props) => Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(kIconData[props['icon']] ?? Icons.circle),
      Text('${props['label'] ?? ''}', style: const TextStyle(fontSize: 12)),
    ]);

/// زیر هم (Column) با پدینگ
Widget _buildColumn(Map<String, dynamic> props, List<Widget> children) => Padding(
      padding: EdgeInsets.all(_toDouble(props['padding'])),
      child: Column(
        mainAxisAlignment: _mainAxisFrom(props['main']),
        crossAxisAlignment: _crossAxisFrom(props['cross']),
        spacing: _toDouble(props['spacing']),
        children: children,
      ),
    );

/// کنار هم (Row) با پدینگ
Widget _buildRow(Map<String, dynamic> props, List<Widget> children) => Padding(
      padding: EdgeInsets.all(_toDouble(props['padding'])),
      child: Row(
        mainAxisAlignment: _mainAxisFrom(props['main']),
        crossAxisAlignment: _crossAxisFrom(props['cross']),
        spacing: _toDouble(props['spacing']),
        children: children,
      ),
    );

/// روی هم (Stack) با پدینگ
Widget _buildStack(Map<String, dynamic> props, List<Widget> children) => Padding(
      padding: EdgeInsets.all(_toDouble(props['padding'])),
      child: Stack(alignment: _alignmentFrom(props['align']), children: children),
    );

/// کادر ساده با رنگ، گوشه‌ی گرد و اندازه‌ی اختیاری (۰ = خودکار)
Widget _buildContainer(Map<String, dynamic> props, List<Widget> children) => Container(
      width: _positiveOrNull(props['width']),
      height: _positiveOrNull(props['height']),
      padding: EdgeInsets.all(_toDouble(props['padding'])),
      decoration: BoxDecoration(
        color: _toColor(props['bg']),
        borderRadius: BorderRadius.circular(_toDouble(props['radius'])),
      ),
      // یک فرزند مستقیم؛ چند فرزند داخل Column
      child: children.length == 1 ? children.first : Column(mainAxisSize: MainAxisSize.min, children: children),
    );

/// کارت: رنگ، اندازه، بردر، سایه و برش محتوا با گوشه‌های گرد
Widget _buildCard(Map<String, dynamic> props, List<Widget> children) {
  final shadowStrength = _toDouble(props['elevation']); // شدت سایه (۰ = بدون سایه)
  final borderWidth = _toDouble(props['borderWidth']); // ۰ = بدون بردر
  return Container(
    margin: EdgeInsets.all(_toDouble(props['margin'])), // فاصله‌ی بیرونی
    width: _positiveOrNull(props['width']),
    height: _positiveOrNull(props['height']),
    padding: EdgeInsets.all(_toDouble(props['padding'])), // فاصله‌ی داخلی
    // با برش، محتوا (مثلاً عکس) با گوشه‌های گرد کارت بریده می‌شود
    clipBehavior: props['clip'] == false ? Clip.none : Clip.antiAlias,
    decoration: BoxDecoration(
      color: _toColor(props['bg'], Colors.white),
      borderRadius: BorderRadius.circular(_toDouble(props['radius'])),
      border: borderWidth > 0
          ? Border.all(color: _toColor(props['borderColor'], Colors.grey), width: borderWidth)
          : null,
      boxShadow: shadowStrength > 0
          ? [
              BoxShadow(
                color: _toColor(props['shadowColor'], Colors.black26),
                blurRadius: shadowStrength * 2,
                offset: Offset(0, shadowStrength / 2),
              ),
            ]
          : null,
    ),
    child: children.length == 1 ? children.first : Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// متن با اندازه، رنگ و بولد
Widget _buildText(Map<String, dynamic> props, RenderEnv env) => Text(
      _bound(props['text'], env),
      style: TextStyle(
        fontSize: _toDouble(props['size'], 16),
        color: _toColor(props['color']),
        fontWeight: props['bold'] == true ? FontWeight.bold : FontWeight.normal,
      ),
    );

/// نوع کیبورد از روی نام ('number'، 'email'، 'phone' یا پیش‌فرض متن)
TextInputType _keyboardFrom(dynamic name) {
  switch (name) {
    case 'number':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    default:
      return TextInputType.text;
  }
}

/// فیلد متن ساده و قابل‌شخصی‌سازی: خط زیرین / کادر دور / بردر / لیبل / هینت / پس‌زمینه.
/// (فیلدهای قدیمی که این ویژگی‌ها را ندارند مثل قبل با کادر و پس‌زمینه‌ی سفید نمایش داده می‌شوند.)
Widget _buildTextField(Map<String, dynamic> props, bool isEditing) {
  final textColor = _toColor(props['fg']);
  final borderColor = _toColor(props['borderColor'], Colors.transparent);
  final borderWidth = _toDouble(props['borderWidth'], 1);

  // شکل بردر: none = هیچ، underline = فقط خط زیرین، outline = کادر دور
  final InputBorder inputBorder;
  switch (props['border'] ?? 'outline') {
    case 'none':
      inputBorder = InputBorder.none;
      break;
    case 'underline':
      inputBorder = UnderlineInputBorder(borderSide: BorderSide(color: borderColor, width: borderWidth));
      break;
    default:
      inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(_toDouble(props['radius'], 8)),
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      );
  }

  final showHint = props['showHint'] != false; // پیش‌فرض: نمایش
  final showLabel = props['showLabel'] == true; // پیش‌فرض: عدم نمایش
  final isPassword = props['obscure'] == true;
  final lineCount = props['maxLines'] is num ? (props['maxLines'] as num).toInt() : 1;

  final field = TextField(
    obscureText: isPassword,
    maxLines: (isPassword || lineCount < 1) ? 1 : lineCount, // متن مخفی فقط تک‌خطی می‌شود
    keyboardType: _keyboardFrom(props['keyboard']),
    // مقدار فیلد برای {{field.name}} و دکمه‌های ناوبری نگه داشته می‌شود
    onChanged: (value) => PreviewState.fields[fieldKeyOf(props['name'])] = value,
    style: TextStyle(color: textColor, fontSize: _toDouble(props['size'], 16)),
    decoration: InputDecoration(
      hintText: showHint ? props['hint'] : null,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
      labelText: showLabel ? props['label'] : null,
      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
      filled: props['filled'] != false,
      fillColor: _toColor(props['bg'], Colors.white),
      isDense: true,
      contentPadding: EdgeInsets.all(_toDouble(props['padding'], 12)),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder,
    ),
  );

  // TextField عرض محدود لازم دارد؛ اگر والد عرض نامحدود داد (مثلاً Row)، عرض ۲۰۰ می‌گیرد
  final sized = LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth.isFinite ? field : SizedBox(width: 200, child: field),
  );
  // در ادیتور لمس باید ویجت را انتخاب کند، نه اینکه کیبورد باز شود
  return isEditing ? IgnorePointer(child: sized) : sized;
}

/// آیکن SVG: کد SVG را می‌کشد و با رنگ انتخابی رنگ می‌کند
Widget _buildSvg(Map<String, dynamic> props) => SvgPicture.string(
      '${props['svg'] ?? ''}',
      width: _toDouble(props['size'], 28),
      height: _toDouble(props['size'], 28),
      colorFilter: ColorFilter.mode(_toColor(props['color']), BlendMode.srcIn),
    );

/// آیکن متریال با اندازه و رنگ
Widget _buildIcon(Map<String, dynamic> props) => Icon(
      kIconData[props['icon']] ?? Icons.help_outline,
      size: _toDouble(props['size'], 24),
      color: _toColor(props['color']),
    );

/// دکمه: سه نوع filled (پر) / outlined (فقط بردر) / text (فقط متن)
Widget _buildButton(Map<String, dynamic> props, RenderEnv env) {
  final isEditing = env.edit;
  // ناوبری: در حالت اجرا، کلیک مقدار navValue را به صفحه‌ی navTo می‌فرستد
  final targetPageId = '${props['navTo'] ?? ''}';
  final VoidCallback onPressed = (!isEditing && targetPageId.isNotEmpty && env.onNavigate != null)
      ? () => env.onNavigate!(targetPageId, _bound(props['navValue'], env))
      : () {};
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_toDouble(props['radius'], 8)));
  final foreground = _toColor(props['fg'], Colors.white); // رنگ متن (و بردر در حالت outlined)
  final label = Text(
    props['text'] ?? '',
    style: TextStyle(fontWeight: props['bold'] == true ? FontWeight.bold : FontWeight.normal),
  );

  final Widget button;
  switch (props['kind']) {
    case 'outlined':
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          shape: shape,
          side: BorderSide(color: foreground, width: 1.5),
        ),
        child: label,
      );
      break;
    case 'text':
      button = TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: foreground, shape: shape),
        child: label,
      );
      break;
    default: // filled
      button = ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _toColor(props['bg'], Colors.indigo),
          foregroundColor: foreground,
          elevation: _toDouble(props['elevation'], 2),
          shape: shape,
        ),
        child: label,
      );
  }
  // در ادیتور کلیک دکمه نباید جلوی انتخاب شدن ویجت را بگیرد
  return isEditing ? IgnorePointer(child: button) : button;
}

/// تصویر از URL: حالت fixed (اندازه‌ی ثابت) یا banner (تمام‌عرض با نسبت ثابت)، با چهار گوشه‌ی مستقل
Widget _buildImage(Map<String, dynamic> props, RenderEnv env) {
  final borderRadius = BorderRadius.only(
    topLeft: Radius.circular(_cornerRadius(props, 'rTL')),
    topRight: Radius.circular(_cornerRadius(props, 'rTR')),
    bottomLeft: Radius.circular(_cornerRadius(props, 'rBL')),
    bottomRight: Radius.circular(_cornerRadius(props, 'rBR')),
  );

  /// خود تصویر؛ اگر لود نشد یک جعبه‌ی خاکستری با آیکن نشان می‌دهد
  Widget networkImage(double? width, double? height) => Image.network(
        _bound(props['url'], env),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height ?? 100,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image),
        ),
      );

  final aspectRatio = _positiveOrNull(props['ratio']) ?? 1.78; // عرض ÷ ارتفاع (۱٫۷۸ = 16:9)

  final Widget content;
  if (props['mode'] == 'banner') {
    // بنر: عرض کامل، ارتفاع از روی نسبت. اگر عرض نامحدود بود (داخل Row) عرض ۲۴۰ می‌گیرد.
    content = LayoutBuilder(
      builder: (_, constraints) => constraints.maxWidth.isFinite
          ? AspectRatio(aspectRatio: aspectRatio, child: networkImage(double.infinity, double.infinity))
          : SizedBox(width: 240, height: 240 / aspectRatio, child: networkImage(240, 240 / aspectRatio)),
    );
  } else {
    // ثابت: عرض (۰ = خودکار) و ارتفاع (پیش‌فرض ۱۵۰)
    content = networkImage(_positiveOrNull(props['width']), _positiveOrNull(props['height']) ?? 150);
  }
  return ClipRRect(borderRadius: borderRadius, child: content);
}

/// متن کنار چک‌باکس یا رادیو (فقط اگر showLabel روشن باشد)
Widget _withLabel(Widget control, Map<String, dynamic> props) {
  if (props['showLabel'] != true) return control;
  return Row(mainAxisSize: MainAxisSize.min, children: [
    control,
    const SizedBox(width: 8),
    Text(
      props['label'] ?? '',
      style: TextStyle(color: _toColor(props['fg']), fontSize: _toDouble(props['labelSize'], 14)),
    ),
  ]);
}

/// چک‌باکس: توپر (داخلش با رنگ اصلی پر می‌شود) یا توخالی (فقط بردر و تیک رنگی).
/// در ادیتور لمس ویجت را انتخاب می‌کند؛ در پیش‌نمایش لمس، تیک را عوض می‌کند.
Widget _buildCheckbox(WidgetNode node, bool isEditing) {
  final props = node.props;
  final activeColor = _toColor(props['activeColor'], Colors.indigo);
  final isFilled = props['filled'] != false;

  Widget draw(bool isChecked, ValueChanged<bool?> onChanged) => _withLabel(
        Checkbox(
          value: isChecked,
          onChanged: onChanged,
          // توخالی: پس‌زمینه شفاف و تیک به رنگ اصلی
          activeColor: isFilled ? activeColor : Colors.transparent,
          checkColor: isFilled ? _toColor(props['checkColor'], Colors.white) : activeColor,
          side: BorderSide(color: activeColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_toDouble(props['radius'], 4))),
        ),
        props,
      );

  if (isEditing) return IgnorePointer(child: draw(props['value'] == true, (_) {}));
  // پیش‌نمایش: وضعیت تیک در PreviewState نگه داشته می‌شود
  return Obx(() => draw(
        PreviewState.checks[node.id] ?? (props['value'] == true),
        (value) => PreviewState.checks[node.id] = value ?? false,
      ));
}

/// رادیو باتن: کاملاً توپر یا حلقه با نقطه‌ی داخل (در حالت انتخاب‌شده).
/// رادیوهای هم‌گروه (props.group) فقط یکی‌شان انتخاب می‌شود (در پیش‌نمایش).
Widget _buildRadio(WidgetNode node, bool isEditing) {
  final props = node.props;
  final activeColor = _toColor(props['activeColor'], Colors.indigo);
  final isFilled = props['filled'] == true;
  final diameter = _toDouble(props['size'], 22);
  final group = '${props['group'] ?? ''}';
  final optionValue = '${props['value'] ?? ''}';

  Widget draw(bool isSelected, VoidCallback onTap) {
    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: activeColor, width: 2),
        color: (isSelected && isFilled) ? activeColor : Colors.transparent,
      ),
      child: (isSelected && !isFilled)
          ? Center(
              child: Container(
                width: diameter * 0.5,
                height: diameter * 0.5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
              ),
            )
          : null,
    );
    return _withLabel(GestureDetector(onTap: onTap, child: circle), props);
  }

  if (isEditing) return IgnorePointer(child: draw(props['selected'] == true, () {}));
  return Obx(() {
    // اگر هنوز چیزی انتخاب نشده، رادیویی که selected دارد انتخاب‌شده حساب می‌شود
    final current = PreviewState.radios[group] ?? (props['selected'] == true ? optionValue : null);
    return draw(current == optionValue, () => PreviewState.radios[group] = optionValue);
  });
}

// ============================================================================
// لیست داده‌ای
// ============================================================================

/// لیست داده‌ای: فرزندان = قالب آیتم؛ به ازای هر ردیف پاسخ سرور یک نسخه ساخته می‌شود.
/// ادیتور: قالب فقط یک‌بار (قابل ویرایش). اجرا: در حال دریافت / خطا / خالی / ردیف‌ها.
Widget _buildDataList(WidgetNode node, RenderEnv env) {
  final props = node.props;
  final spacing = _toDouble(props['spacing'], 8);
  final padding = EdgeInsets.all(_toDouble(props['padding'], 8));

  /// یک نسخه از قالب آیتم در محیط [itemEnv]
  Widget template(RenderEnv itemEnv) {
    final kids = node.children.map((child) => renderNode(child, itemEnv)).toList();
    return kids.length == 1
        ? kids.first
        : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: kids);
  }

  Widget boxed(Widget child) => Padding(padding: padding, child: child);

  // ادیتور: قالب یک‌بار
  if (env.edit) {
    return boxed(node.children.isEmpty ? _emptyContainerHint('لیست داده‌ای (قالب آیتم را اضافه کن)') : template(env));
  }
  // اجرا نمی‌شویم (گالری/پیش‌نمایش ساده): سه نمونه‌ی ظاهری
  if (!env.resolves) {
    return boxed(Column(spacing: spacing, children: [for (var i = 0; i < 3; i++) template(env)]));
  }
  if (env.loading) return boxed(const Center(child: CircularProgressIndicator()));
  if (env.error != null) {
    return boxed(Center(child: Text(env.error!, style: const TextStyle(color: Colors.red))));
  }
  final rows = env.items ?? const [];
  if (rows.isEmpty) return boxed(Center(child: Text('${props['emptyText'] ?? ''}')));
  return boxed(Column(spacing: spacing, children: [for (final row in rows) template(env.withItem(row))]));
}

// ============================================================================
// تب‌بندی
// ============================================================================

/// تب‌بندی: نوار تب (۴ سبک) + محتوای تب فعال با انیمیشن.
/// [childWidgets] ویجت ساخته‌شده‌ی هر فرزند (tabItem) است؛ محتوای هر تب همان است.
Widget _buildTabs(WidgetNode node, List<Widget> childWidgets, RenderEnv env) {
  final props = node.props;
  // فقط فرزندانی که tabItem هستند تب حساب می‌شوند
  final tabIndexes = [
    for (var index = 0; index < node.children.length; index++)
      if (node.children[index].type == 'tabItem') index,
  ];
  if (tabIndexes.isEmpty) return _emptyContainerHint('تب‌بندی (یک تب اضافه کن)');
  final tabItems = [for (final index in tabIndexes) node.children[index]];
  final contents = [for (final index in tabIndexes) childWidgets[index]];

  final style = '${props['style'] ?? 'underline'}';
  final activeColor = _toColor(props['activeColor'], Colors.indigo);
  final activeTextColor = _toColor(props['activeTextColor'] ?? props['activeColor'], Colors.indigo);
  final inactiveColor = _toColor(props['inactiveColor'], Colors.grey);
  final barColor = _toColor(props['barColor'], Colors.transparent);
  final labelSize = _toDouble(props['labelSize'], 14);
  final radius = _toDouble(props['radius'], 20);
  final indicatorHeight = _toDouble(props['indicatorHeight'], 3);
  final showIcons = props['showIcons'] == true;
  final isScrollable = props['scrollable'] == true;
  final boldActive = props['bold'] != false;
  final isSegmented = style == 'segmented';

  // انیمیشن تغییر محتوا: fade / slide / scale / none
  final animationName = '${props['animation'] ?? 'fade'}';
  final duration = Duration(milliseconds: animationName == 'none' ? 0 : _toDouble(props['duration'], 250).toInt());
  Widget transition(Widget child, Animation<double> animation) {
    switch (animationName) {
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'scale':
        return ScaleTransition(scale: animation, child: child);
      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }

  return Obx(() {
    // تب فعال: آخرین تبی که لمس شده (در PreviewState نگه داشته می‌شود)
    final storedIndex = PreviewState.tabs[node.id] ?? 0;
    final activeIndex = storedIndex < tabItems.length ? storedIndex : 0;

    /// سربرگ یک تب
    Widget header(int index) {
      final isActive = index == activeIndex;
      final color = isActive ? activeTextColor : inactiveColor;
      final BoxDecoration decoration;
      if (style == 'underline') {
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: indicatorHeight),
          ),
        );
      } else if (style == 'pill' || isSegmented) {
        decoration = BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        );
      } else {
        decoration = const BoxDecoration();
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          PreviewState.tabs[node.id] = index;
          // در ادیتور، لمس تب خود تب را هم انتخاب می‌کند تا محتوایش قابل ویرایش شود
          if (env.edit) env.onSelect?.call(tabItems[index].id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: decoration,
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (showIcons) ...[
              Icon(kIconData[tabItems[index].props['icon']] ?? Icons.circle, size: labelSize + 4, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              '${tabItems[index].props['label'] ?? ''}',
              style: TextStyle(
                color: color,
                fontSize: labelSize,
                fontWeight: (isActive && boldActive) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ]),
        ),
      );
    }

    final headers = [for (var index = 0; index < tabItems.length; index++) header(index)];
    // نوار: اسکرولی یا هم‌عرض؛ سبک segmented یک قاب دور نوار دارد
    final Widget barRow = isScrollable
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: headers))
        : Row(children: [for (final headerWidget in headers) Expanded(child: headerWidget)]);
    final bar = Container(
      padding: isSegmented ? const EdgeInsets.all(4) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: isSegmented ? BorderRadius.circular(radius + 4) : null,
      ),
      child: barRow,
    );

    // محتوای تب فعال؛ با تغییر کلید، انیمیشن اجرا می‌شود
    final content = AnimatedSwitcher(
      duration: duration,
      transitionBuilder: transition,
      child: KeyedSubtree(key: ValueKey<int>(activeIndex), child: contents[activeIndex]),
    );
    final gap = SizedBox(height: _toDouble(props['gap'], 8));
    final isBottom = props['barPosition'] == 'bottom';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: isBottom ? [content, gap, bar] : [bar, gap, content],
    );
  });
}

// ============================================================================
// فوتر: نوار ساده یا یکی از مدل‌های ناوبری پایین
// ============================================================================

/// نوار ساده‌ی فوتر: یک Row با رنگ و ارتفاع
Widget _buildPlainFooterBar(WidgetNode footer, List<Widget> children) => Container(
      height: _toDouble(footer.props['height'], 56),
      color: _toColor(footer.props['bg']),
      child: Row(mainAxisAlignment: _mainAxisFrom(footer.props['main']), children: children),
    );

/// ناوبری فشرده بدون پدینگ اضافه: آیتم‌ها کنار هم و هم‌اندازه؛ با آیکن (زیرش متن) یا فقط متن.
Widget _buildCompactNav({
  required List<WidgetNode> items,
  required int activeIndex,
  required void Function(int index) onItemTap,
  required bool showIcons,
  required double height,
  required Color background,
  required Color activeColor,
}) {
  /// یک آیتم: فعال = رنگ انتخابی، غیرفعال = خاکستری
  Widget itemAt(int index) {
    final item = items[index];
    final color = index == activeIndex ? activeColor : Colors.grey;
    final label = '${item.props['label'] ?? ''}';
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onItemTap(index),
        child: showIcons
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(kIconData[item.props['icon']] ?? Icons.circle, size: 22, color: color),
                Text(label, style: TextStyle(fontSize: 10, color: color)),
              ])
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: index == activeIndex ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
      ),
    );
  }

  return Container(
    height: height,
    color: background,
    child: Row(children: [for (var index = 0; index < items.length; index++) itemAt(index)]),
  );
}

/// فوتر بر اساس variant: نوار ساده یا مدل‌های ناوبری (آیتم‌ها = فرزندهای navItem)
Widget _buildFooter(WidgetNode footer, List<Widget> visibleChildren, RenderEnv env) {
  final props = footer.props;
  final variantId = '${props['variant'] ?? 'bar'}';
  final navItems = footer.children.where((child) => child.type == 'navItem').toList();

  // ناوبری حداقل ۲ آیتم لازم دارد؛ وگرنه نوار ساده نشان می‌دهیم
  if (variantId == 'bar' || navItems.length < 2) return _buildPlainFooterBar(footer, visibleChildren);

  // لمس یک آیتم در ادیتور، همان آیتم را انتخاب می‌کند
  void onItemTap(int index) {
    if (env.edit) env.onSelect?.call(navItems[index].id);
  }

  // آیتم فعال = آیتم انتخاب‌شده؛ اگر هیچ‌کدام نبود، اولی
  var activeIndex = navItems.indexWhere((item) => item.id == env.selectedId);
  if (activeIndex < 0) activeIndex = 0;

  final activeColor = _toColor(props['sel'], Colors.indigo);
  final background = _toColor(props['bg'], Colors.white);
  IconData iconOf(WidgetNode item) => kIconData[item.props['icon']] ?? Icons.circle;
  String labelOf(WidgetNode item) => '${item.props['label'] ?? ''}';

  switch (variantId) {
    case 'nav_classic': // آیکن + متن، فشرده و بدون پدینگ اضافه
      return _buildCompactNav(
        items: navItems,
        activeIndex: activeIndex,
        onItemTap: onItemTap,
        showIcons: true,
        height: _toDouble(props['height'], 48),
        background: background,
        activeColor: activeColor,
      );
    case 'nav_m3': // NavigationBar متریال ۳ (با انیمیشن)
      return NavigationBar(
        height: 64, // پیش‌فرض متریال ۸۰ است؛ کمتر شده تا صفحه جای بیشتری داشته باشد
        backgroundColor: background,
        indicatorColor: activeColor.withValues(alpha: 0.2),
        selectedIndex: activeIndex,
        onDestinationSelected: onItemTap,
        destinations: [
          for (final item in navItems) NavigationDestination(icon: Icon(iconOf(item)), label: labelOf(item)),
        ],
      );
    case 'nav_text': // فقط متن، بدون آیکن
      return _buildCompactNav(
        items: navItems,
        activeIndex: activeIndex,
        onItemTap: onItemTap,
        showIcons: false,
        height: _toDouble(props['height'], 48),
        background: background,
        activeColor: activeColor,
      );
    case 'lib_curved': // کتابخانه curved_navigation_bar (با انیمیشن)
      return CurvedNavigationBar(
        index: activeIndex,
        height: 50,
        backgroundColor: Colors.transparent,
        color: background,
        buttonBackgroundColor: activeColor,
        animationDuration: const Duration(milliseconds: 300),
        items: [for (final item in navItems) Icon(iconOf(item))],
        onTap: onItemTap,
      );
    case 'lib_gnav': // کتابخانه google_nav_bar (بدون پدینگ بیرونی)
      return Container(
        color: background,
        child: GNav(
          gap: 6,
          iconSize: 22,
          color: Colors.grey,
          activeColor: activeColor,
          tabBackgroundColor: activeColor.withValues(alpha: 0.15),
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          selectedIndex: activeIndex,
          onTabChange: onItemTap,
          tabs: [for (final item in navItems) GButton(icon: iconOf(item), text: labelOf(item))],
        ),
      );
    default:
      return _buildPlainFooterBar(footer, visibleChildren);
  }
}

// ============================================================================
// پیش‌نمایش
// ============================================================================

/// تصویر بندانگشتی کوچک یک ویجت (برای کاشی قالب‌ها).
/// ویجت با عرض طراحی ثابت (۲۰۰) ساخته و سپس کوچک می‌شود تا داخل کاشی جا شود.
Widget templateThumbnail(WidgetNode node) => FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 200,
        child: Align(child: IgnorePointer(child: renderNode(node, RenderEnv.preview))),
      ),
    );

/// پیش‌نمایش کوچک و غیرقابل لمس یک ویجت (برای لیست قالب‌ها و نمونه‌ها)
Widget templatePreview(WidgetNode node) => Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        // ارتفاع پیش‌نمایش محدود است تا قالب‌های بلند لیست را پر نکنند
        constraints: const BoxConstraints(maxHeight: 140),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: IgnorePointer(child: renderNode(node, RenderEnv.preview)),
        ),
      ),
    );

