import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/bindings/response_bindings.dart';
import '../../domain/entities/model_def.dart';
import '../../domain/entities/page_request.dart';
import '../../domain/entities/template.dart';
import '../../domain/models/model_type_parser.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/catalog/catalog_constants.dart';
import '../../domain/catalog/prop_field.dart';
import '../../domain/catalog/widget_catalog.dart';
import '../../domain/catalog/widget_def.dart';
import '../../domain/usecases/edit_page_usecases.dart';
import '../controllers/editor_controller.dart';
import '../controllers/models_controller.dart';
import '../controllers/project_detail_controller.dart';
import '../controllers/templates_controller.dart';
import 'binding_text_field.dart';
import '../renderer/node_renderer.dart';
import 'field_type_picker.dart';
import '../theme/icon_registry.dart';

/// پنل‌های پایین ادیتور: افزودن ویجت، انتخاب نمونه، ویژگی‌ها و ذخیره‌ی قالب.
/// همه‌ی پنل‌ها داخل یک پنل چسبیده به پایین نشان داده می‌شوند (نه bottom sheet)
/// تا صفحه‌ی بالا همیشه دیده شود.
class EditorPanels {
  /// کتابخانه‌ی قالب‌های کاربر (برای بخش «قالب‌های من»)
  final TemplatesController templates;
  const EditorPanels(this.templates);

  // ==========================================================================
  // قالب‌ها
  // ==========================================================================

  /// دیالوگ گرفتن نام و ذخیره‌ی ویجت انتخاب‌شده به‌عنوان قالب
  void showSaveTemplateDialog(EditorController controller) {
    final nameController = TextEditingController();
    Get.defaultDialog(
      title: 'نام قالب',
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'مثلاً دکمه سبز بولد'),
      ),
      textConfirm: 'ذخیره',
      textCancel: 'لغو',
      onConfirm: () async {
        final name = nameController.text.trim();
        if (name.isEmpty) return;
        Get.back();
        final selectedNode = controller.selected;
        if (selectedNode != null) await templates.saveFromNode(name, selectedNode);
        Get.snackbar('ذخیره شد', 'در لیست افزودن، بخش «قالب‌های من» است.');
      },
    );
  }

  // ==========================================================================
  // قاب مشترک پنل
  // ==========================================================================

  /// پنل چسبیده به پایین؛ صفحه‌ی بالا همچنان دیده می‌شود و قابل لمس است.
  /// بالای آن عنوان و دکمه‌ی بستن است و زیرش محتوای پنل فعلی.
  Widget panelBox(EditorController controller) => Material(
        elevation: 12,
        color: Get.theme.colorScheme.surface,
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  controller.panelTitle.value,
                  style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              tooltip: 'بستن',
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              icon: const Icon(Icons.close),
              onPressed: controller.closePanel,
            ),
          ]),
          const Divider(height: 1),
          Expanded(child: controller.panel.value!),
        ]),
      );

  // ==========================================================================
  // پنل افزودن ویجت
  // ==========================================================================

  /// پنل افزودن با دو تب جدا: «ویجت‌ها» و «قالب‌های من»
  void showAddPanel(EditorController controller) {
    final page = controller.page.value!;
    // بخش‌هایی که قبلاً حذف (پنهان) شده‌اند و می‌شود برشان گرداند
    final hiddenSections = [
      if (page.appBar.props['hidden'] == true) 'appBar',
      if (page.footer.props['hidden'] == true) 'footer',
    ];

    controller.showPanel(
      'افزودن',
      'add',
      DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(
            labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            tabs: [Tab(text: 'ویجت‌ها', height: 36), Tab(text: 'قالب‌های من', height: 36)],
          ),
          Expanded(
            child: TabBarView(children: [
              _widgetsTab(controller, hiddenSections),
              _templatesTab(controller),
            ]),
          ),
        ]),
      ),
    );
  }

  /// تب «ویجت‌ها»: گرید فشرده‌ی شش‌ستونه (بدون نیاز به اسکرول) + بازگرداندن اپ‌بار/فوتر حذف‌شده
  Widget _widgetsTab(EditorController controller, List<String> hiddenSections) => ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        children: [
          for (final sectionType in hiddenSections)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(iconForType(sectionType)),
              title: Text('بازگرداندن ${WidgetCatalog.of(sectionType).label}'),
              onTap: () {
                controller.closePanel();
                controller.restoreSection(sectionType);
              },
            ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.95,
            children: [
              for (final definition in WidgetCatalog.addable) _addTile(controller, definition),
            ],
          ),
        ],
      );

  /// تب «قالب‌های من»: گرید سه‌ستونه از قالب‌های کاربر
  Widget _templatesTab(EditorController controller) {
    if (templates.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'هنوز قالبی نداری.\nیک ویجت را انتخاب کن و آیکن «ذخیره به‌عنوان قالب» را بزن.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [_templateGrid(controller, templates.items.toList())],
    );
  }

  /// قالب‌ها را به‌صورت گرید فشرده (سه‌تا در هر سطر) نشان می‌دهد؛
  /// هر کاشی یک پیش‌نمایش کوچک و اسم قالب دارد و لمسش قالب را به صفحه اضافه می‌کند.
  Widget _templateGrid(EditorController controller, List<Template> items) {
    final tileWidth = (Get.width - 16 - 12) / 3; // دو حاشیه‌ی ۸ و دو فاصله‌ی ۶
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final template in items)
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            controller.closePanel();
            controller.addTemplate(template);
          },
          child: Container(
            width: tileWidth,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: 56, width: double.infinity, child: templateThumbnail(template.node)),
              const SizedBox(height: 4),
              Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
            ]),
          ),
        ),
    ]);
  }

  /// یک کاشی فشرده در گرید افزودن (آیکن کوچک + اسم ویجت)
  Widget _addTile(EditorController controller, WidgetDef definition) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // اگر نمونه‌ی آماده یا قالب شخصی از این نوع هست، اول لیست نمونه‌ها را نشان بده
          final hasChoices = WidgetCatalog.variantsOf(definition).length > 1 ||
              templates.items.any((template) => template.node.type == definition.type);
          if (hasChoices) {
            _showVariantPanel(controller, definition);
          } else {
            controller.closePanel();
            controller.add(definition.type);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(iconForType(definition.type), size: 20),
            const SizedBox(height: 2),
            Text(
              definition.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, height: 1.1),
            ),
          ]),
        ),
      );

  /// نمونه‌های آماده‌ی داخلی + قالب‌های ذخیره‌شده‌ی خود کاربر از همین نوع
  void _showVariantPanel(EditorController controller, WidgetDef definition) {
    final variants = WidgetCatalog.variantsOf(definition);
    final myTemplates = templates.items.where((template) => template.node.type == definition.type).toList();

    controller.showPanel(
      'نمونه‌ی ${definition.label}',
      'variant',
      ListView(padding: const EdgeInsets.all(8), children: [
        // ویجت‌هایی که نمونه‌ی آماده ندارند (مثل فیلد متن) یک گزینه‌ی «پیش‌فرض» دارند
        if (variants.isEmpty)
          ListTile(
            title: const Text('پیش‌فرض'),
            subtitle: templatePreview(WidgetCatalog.create(definition.type)),
            onTap: () {
              controller.closePanel();
              controller.add(definition.type);
            },
          ),
        for (final variant in variants)
          ListTile(
            title: Text(variant.label),
            // پیش‌نمایش: مقادیر پیش‌فرض + مقادیر این نمونه
            subtitle: templatePreview(WidgetNode(
              type: definition.type,
              props: {...definition.defaults, 'variant': variant.id, ...variant.props},
            )),
            onTap: () {
              controller.closePanel();
              controller.add(definition.type, variant);
            },
          ),
        if (myTemplates.isNotEmpty) ...[
          const Divider(),
          Text('قالب‌های من', style: Get.textTheme.titleSmall),
          _templateGrid(controller, myTemplates),
        ],
      ]),
    );
  }

  // ==========================================================================
  // پنل ویژگی‌ها
  // ==========================================================================

  /// پنل ویژگی‌های [node]؛ فیلدها بر اساس نوعشان در گروه‌های فشرده چیده می‌شوند.
  void showPropsPanel(EditorController controller, WidgetNode node) {
    final definition = WidgetCatalog.of(node.type);
    final parent = controller.parentOf(node.id);

    // فیلد Expanded فقط وقتی والد Row / فوتر ساده / اپ‌بار آزاد است نمایش داده می‌شود
    final parentAllowsExpanded = parent != null &&
        (parent.type == 'row' ||
            (parent.type == 'footer' && (parent.props['variant'] ?? 'bar') == 'bar') ||
            (parent.type == 'appBar' && parent.props['variant'] == 'custom'));
    final fields = [...definition.fields, if (parentAllowsExpanded) kFlexField];

    List<PropField> fieldsOfType(PropType type) => fields.where((field) => field.type == type).toList();

    controller.showPanel(
      'ویژگی‌های ${definition.label}',
      'props',
      StatefulBuilder(builder: (context, refresh) {
        final numberCellWidth = (Get.width - 32 - 16) / 3; // فیلدهای عددی: سه ستون
        final optionCellWidth = (Get.width - 32 - 8) / 2; // منوی گزینه‌ها: دو ستون
        final numberFields = fieldsOfType(PropType.number);
        final optionFields = fieldsOfType(PropType.option);
        final booleanFields = fieldsOfType(PropType.boolean);

        // هر عضو این لیست یک گروه از پنل است؛ بین گروه‌ها فاصله می‌افتد
        final sections = <Widget>[
          // ۱) نمونه‌های آماده: چیپ‌های فشرده
          if (definition.variants.length > 1)
            Wrap(spacing: 6, children: [
              for (final variant in definition.variants)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: const TextStyle(fontSize: 12),
                  label: Text(variant.label),
                  selected: node.props['variant'] == variant.id,
                  onSelected: (_) {
                    controller.applyVariant(node, variant);
                    refresh(() {});
                  },
                ),
            ]),
          // ۲) انتخاب آیکن
          for (final field in fieldsOfType(PropType.icon)) _iconPicker(controller, node, field, refresh),
          // ۳) فیلدهای متنی (تمام‌عرض)
          for (final field in fieldsOfType(PropType.text)) _textBox(controller, node, field),
          // ۳.۵) انتخاب صفحه‌ی مقصد (ناوبری)
          for (final field in fieldsOfType(PropType.page)) _pageBox(controller, node, field),
          // ۴) انتخاب رنگ
          for (final field in fieldsOfType(PropType.color)) _colorRow(controller, node, field, refresh),
          // ۵) فیلدهای عددی: سه‌تا کنار هم
          if (numberFields.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final field in numberFields)
                SizedBox(width: numberCellWidth, child: _numberBox(controller, node, field)),
            ]),
          // ۶) منوی گزینه‌ها: دوتا کنار هم
          if (optionFields.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final field in optionFields)
                SizedBox(width: optionCellWidth, child: _optionBox(controller, node, field)),
            ]),
          // ۷) گزینه‌های روشن/خاموش: چیپ‌های کوچک
          if (booleanFields.isNotEmpty)
            Wrap(spacing: 6, children: [
              for (final field in booleanFields)
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: const TextStyle(fontSize: 12),
                  label: Text(_shortLabel(field.label)),
                  selected: node.props[field.key] == true,
                  onSelected: (value) {
                    controller.setProp(node, field.key, value);
                    refresh(() {});
                  },
                ),
            ]),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            for (final section in sections) Padding(padding: const EdgeInsets.only(bottom: 12), child: section),
          ],
        );
      }),
    );
  }

  // ==========================================================================
  // پنل «درخواست صفحه»
  // ==========================================================================

  /// تنظیم اینکه این صفحه هنگام ورود، چه درخواستی به سرور بزند.
  /// مقداری که صفحه‌ی قبلی با دکمه فرستاده، همان {{args}} است و به آدرس/پارامتر وصل می‌شود.
  void showRequestPanel(EditorController controller) {
    final request = controller.page.value!.request;
    final models = Get.find<ModelsController>();
    final project = Get.find<ProjectDetailController>().project.value;
    if (project != null) models.open(project); // مدل‌های همین پروژه برای انتخاب نوع پاسخ

    Widget textBox(String label, String initial, void Function(String) onChanged, {String? helper}) =>
        TextFormField(
          initialValue: initial,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 3,
            labelStyle: _labelStyle,
            isDense: true,
            border: _outlineBorder,
          ),
          onChanged: (text) => controller.updateRequest((r) => onChanged(text)),
        );

    /// ویرایشگر لیست key/value (پارامترها و هدرها)
    Widget pairsEditor(String title, List<RequestParam> pairs, void Function(void Function()) refresh, {String? helper}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('افزودن'),
              onPressed: () {
                controller.updateRequest((r) => pairs.add(RequestParam()));
                refresh(() {});
              },
            ),
          ]),
          if (helper != null) Text(helper, style: const TextStyle(fontSize: 11)),
          for (final pair in pairs)
            Padding(
              key: ObjectKey(pair),
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Expanded(child: textBox('key', pair.key, (text) => pair.key = text)),
                const SizedBox(width: 8),
                Expanded(child: textBox('value', pair.value, (text) => pair.value = text)),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    controller.updateRequest((r) => pairs.remove(pair));
                    refresh(() {});
                  },
                ),
              ]),
            ),
        ]);

    controller.showPanel(
      'درخواست صفحه (هنگام ورود)',
      'request',
      StatefulBuilder(builder: (context, refresh) {
        final fields = <Widget>[
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('با ورود به صفحه از سرور اطلاعات بگیر', style: TextStyle(fontSize: 13)),
            value: request.enabled,
            onChanged: (value) {
              controller.updateRequest((r) => r.enabled = value);
              refresh(() {});
            },
          ),
          if (request.enabled) ...[
            textBox('آدرس (URL)', request.url, (text) => request.url = text,
                helper: 'مثال: https://api.example.com/users/{value}  —  {value} با مقدار ارسالی از صفحه‌ی قبل پر می‌شود'),
            DropdownButtonFormField<String>(
              value: request.method,
              isDense: true,
              decoration: const InputDecoration(
                  labelText: 'متد', labelStyle: _labelStyle, isDense: true, border: _outlineBorder),
              items: [for (final method in kRequestMethods) DropdownMenuItem(value: method, child: Text(method))],
              onChanged: (value) {
                controller.updateRequest((r) => r.method = value ?? 'GET');
                refresh(() {});
              },
            ),
            pairsEditor('پارامترها', request.params, refresh,
                helper: 'مثلاً id و name؛ در value می‌توانی {value} بنویسی تا با مقدار صفحه‌ی قبل پر شود.'),
            if (request.params.isNotEmpty && request.method != 'GET')
              DropdownButtonFormField<String>(
                value: request.paramsIn,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'پارامترها چطور فرستاده شوند؟',
                    labelStyle: _labelStyle,
                    isDense: true,
                    border: _outlineBorder),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('خودکار (DELETE: کوئری، بقیه: بدنه‌ی JSON)')),
                  DropdownMenuItem(value: 'query', child: Text('کوئری (?id=1&name=x)')),
                  DropdownMenuItem(value: 'body', child: Text('بدنه‌ی JSON')),
                ],
                onChanged: (value) {
                  controller.updateRequest((r) => r.paramsIn = value ?? 'auto');
                  refresh(() {});
                },
              ),
            pairsEditor('هدرها (اختیاری)', request.headers, refresh, helper: 'مثلاً Authorization: Bearer ...'),
            // نوع پاسخ: مدل‌های ساخته‌شده‌ی همین پروژه (User، List<User>، ...)
            Obx(() {
              // همیشه فهرست مدل‌ها خوانده شود (GetX به یک متغیر observable داخل Obx نیاز دارد)
              models.models.length;
              return OutlinedButton.icon(
                  icon: const Icon(Icons.data_object),
                  label: Text(
                    request.responseType == null
                        ? 'نوع پاسخ: بدون نوع (فقط داده‌ی خام)'
                        : 'نوع پاسخ: ${describeFieldType(request.responseType!, models.nameOf)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    final choices = [for (final model in models.models) MapEntry(model.id, model.name)];
                    final picked = await pickFieldType(models: choices, current: request.responseType, allowNone: true);
                    if (picked == null) return;
                    controller.updateRequest((r) => r.responseType = picked.type);
                    refresh(() {});
                  },
                );
            }),
            // یک‌کلیک: ویجت نمایش پاسخ (لیست یا کارت اطلاعات) با bindingهای وصل‌شده بساز
            Obx(() {
              final built = buildResponseWidgets(request, models.models.toList());
              if (built == null) return const SizedBox.shrink();
              final isList = built.type == 'dataList';
              return FilledButton.tonalIcon(
                icon: const Icon(Icons.auto_awesome),
                label: Text(isList ? 'ساخت لیست از این پاسخ در صفحه' : 'ساخت نمایش اطلاعات از این پاسخ'),
                onPressed: () {
                  controller.addNode(buildResponseWidgets(request, models.models.toList())!);
                  controller.closePanel();
                  Get.snackbar('ساخته شد', isList ? 'لیست به صفحه اضافه شد؛ هر ردیف با {{item.…}} به داده وصل است.' : 'متن‌ها به صفحه اضافه شدند.');
                },
              );
            }),
            textBox('مسیر داده در پاسخ (اختیاری)', request.dataPath, (text) => request.dataPath = text,
                helper: 'جایی از پاسخ که نوع بالا روی آن پیاده می‌شود؛ مثلاً data یا data.items — خالی = خود پاسخ. '
                    'برای «لیست داده‌ای» هم همین مسیر لیست است.'),
            const Text(
              'نتیجه در کنترلر صفحه ذخیره می‌شود (controller.response با نوع انتخابی، controller.data خام).',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [for (final field in fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: field)],
        );
      }),
    );
  }

  // ==========================================================================
  // اجزای پنل ویژگی‌ها (هر نوع فیلد یک ویجت کوچک)
  // ==========================================================================

  static const _outlineBorder = OutlineInputBorder();
  static const _labelStyle = TextStyle(fontSize: 12);

  /// کلید فیلد؛ با عوض شدن نمونه‌ی آماده تغییر می‌کند تا مقدار نمایش‌داده‌شده تازه شود
  ValueKey<String> _fieldKey(WidgetNode node, PropField field) =>
      ValueKey('${node.id}${field.key}${node.props['variant']}');

  /// پراپرتی‌هایی که binding ({{...}}) می‌پذیرند
  static const _bindableKeys = {'text', 'url', 'navValue'};

  /// چیپ‌های binding از روی نوع پاسخ درخواست و مدل‌های پروژه (فقط برای پراپرتی‌های قابل‌اتصال)
  List<BindingSuggestion> _suggestionsFor(EditorController controller, WidgetNode node, PropField field) {
    final page = controller.page.value;
    if (page == null || !_bindableKeys.contains(field.key)) return const [];
    final insideList = PageTree.ancestorOfType(page, node, 'dataList') != null;
    return bindingSuggestions(page.request, Get.find<ModelsController>().models.toList(), insideList: insideList);
  }

  /// فیلد متنی تمام‌عرض (کد SVG چندخطی است) + چیپ‌های binding
  Widget _textBox(EditorController controller, WidgetNode node, PropField field) => BindingTextField(
        key: _fieldKey(node, field),
        label: field.label,
        initialValue: '${node.props[field.key] ?? ''}',
        maxLines: field.key == 'svg' ? 4 : 1,
        suggestions: _suggestionsFor(controller, node, field),
        onChanged: (text) => controller.setProp(node, field.key, text),
      );

  /// منوی انتخاب صفحه‌ی مقصد از صفحه‌های همین پروژه (مقدار ذخیره‌شده = شناسه‌ی صفحه)
  Widget _pageBox(EditorController controller, WidgetNode node, PropField field) {
    final pages = Get.find<ProjectDetailController>().pages;
    final current = '${node.props[field.key] ?? ''}';
    return DropdownButtonFormField<String>(
      key: ValueKey('${node.id}${field.key}$current'),
      value: pages.any((page) => page.id == current) ? current : '',
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: _shortLabel(field.label),
        labelStyle: _labelStyle,
        isDense: true,
        border: _outlineBorder,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('— بدون ناوبری —', style: TextStyle(fontSize: 13))),
        for (final page in pages)
          DropdownMenuItem(value: page.id, child: Text(page.name, style: const TextStyle(fontSize: 13))),
      ],
      onChanged: (value) => controller.setProp(node, field.key, value ?? ''),
    );
  }

  /// فیلد عددی کوچک؛ برچسب کامل با نگه‌داشتن انگشت (Tooltip) دیده می‌شود
  Widget _numberBox(EditorController controller, WidgetNode node, PropField field) => Tooltip(
        message: field.label,
        child: TextFormField(
          key: _fieldKey(node, field),
          initialValue: _formatNumber(node.props[field.key]),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _shortLabel(field.label),
            labelStyle: _labelStyle,
            isDense: true,
            border: _outlineBorder,
          ),
          onChanged: (text) => controller.setProp(node, field.key, double.tryParse(text) ?? 0.0),
        ),
      );

  /// منوی کشویی برای ویژگی‌های گزینه‌ای (مثل چینش)
  Widget _optionBox(EditorController controller, WidgetNode node, PropField field) =>
      DropdownButtonFormField<String>(
        key: ValueKey('${node.id}${field.key}${node.props[field.key]}'),
        value: field.options.contains(node.props[field.key]) ? node.props[field.key] as String : null,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _shortLabel(field.label),
          labelStyle: _labelStyle,
          isDense: true,
          border: _outlineBorder,
        ),
        items: [
          for (final option in field.options)
            DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 13))),
        ],
        onChanged: (value) {
          if (value != null) controller.setProp(node, field.key, value);
        },
      );

  /// ردیف انتخاب رنگ: دایره‌های کوچک پالت (دایره‌ی انتخاب‌شده قاب آبی دارد)
  Widget _colorRow(EditorController controller, WidgetNode node, PropField field, StateSetter refresh) {
    final currentColor = node.props[field.key];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_shortLabel(field.label), style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final color in kColorPalette)
          GestureDetector(
            onTap: () {
              controller.setProp(node, field.key, color);
              refresh(() {});
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentColor == color ? Colors.blue : Colors.grey.shade400,
                  width: currentColor == color ? 3 : 1,
                ),
              ),
              // رنگ شفاف با آیکن «ممنوع» نشان داده می‌شود
              child: color == 0x00000000 ? const Icon(Icons.block, size: 14, color: Colors.grey) : null,
            ),
          ),
      ]),
    ]);
  }

  /// گرید انتخاب آیکن (آیکن انتخاب‌شده پس‌زمینه‌ی رنگی دارد)
  Widget _iconPicker(EditorController controller, WidgetNode node, PropField field, StateSetter refresh) {
    final currentIconKey = node.props[field.key];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_shortLabel(field.label), style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (final entry in kIconData.entries)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              controller.setProp(node, field.key, entry.key);
              refresh(() {});
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: currentIconKey == entry.key ? Get.theme.colorScheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(entry.value, size: 20),
            ),
          ),
      ]),
    ]);
  }
}

/// «عرض (۰ = خودکار)» → «عرض»؛ متن کامل در Tooltip (نگه‌داشتن انگشت) دیده می‌شود
String _shortLabel(String label) => label.split('(').first.trim();

/// ۸.۰ → ۸  (عددهای صحیح بدون اعشار نمایش داده می‌شوند)
String _formatNumber(dynamic value) {
  if (value is! num) return '';
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
