import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/bindings/bindings.dart';
import '../../domain/entities/page_model.dart';
import '../controllers/project_detail_controller.dart';
import '../renderer/node_renderer.dart';
import '../services/preview_http.dart';

/// اجرای آزمایشی یک صفحه، مثل خود اپ:
///  • به‌محض ورود، اگر «درخواست صفحه» روشن باشد به سرور می‌زند
///  • دکمه‌های دارای ناوبری، صفحه‌ی مقصد را (با مقدار ارسالی) باز می‌کنند
///  • نتیجه روی ویجت‌های دارای binding ({{data.x}} و لیست داده‌ای) نمایش داده می‌شود
class PreviewPageScreen extends StatefulWidget {
  final PageModel page;

  /// مقداری که صفحه‌ی قبلی فرستاده (در bindingها {{args}})
  final String? args;
  const PreviewPageScreen({super.key, required this.page, this.args});

  @override
  State<PreviewPageScreen> createState() => _PreviewPageScreenState();
}

class _PreviewPageScreenState extends State<PreviewPageScreen> {
  bool _loading = false;
  String? _error;
  dynamic _data; // کل پاسخ سرور
  List<dynamic>? _items; // ردیف‌های لیست (null = درخواستی نبوده)

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// درخواست صفحه (اگر روشن و آدرس‌دار باشد)
  Future<void> _load() async {
    final request = widget.page.request;
    if (!request.enabled || request.url.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await sendPageRequest(request, widget.args);
      final list = jsonPath(result, request.dataPath.trim());
      if (!mounted) return;
      setState(() {
        _data = result;
        _items = list is List ? list : <dynamic>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'خطا در دریافت اطلاعات: $error';
        _loading = false;
      });
    }
  }

  /// رفتن به صفحه‌ی دیگر پروژه با یک مقدار
  void _navigate(String pageId, String value) {
    final target = Get.find<ProjectDetailController>().pages.firstWhereOrNull((page) => page.id == pageId);
    if (target == null) {
      Get.snackbar('خطا', 'صفحه‌ی مقصد پیدا نشد (شاید حذف شده است).');
      return;
    }
    Get.to(() => PreviewPageScreen(page: target, args: value));
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final env = RenderEnv(
      edit: false,
      scope: {'data': _data, 'args': widget.args}, // غیرخالی = bindingها پر می‌شوند
      loading: _loading,
      error: _error,
      items: _items,
      onNavigate: _navigate,
    );
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: page.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
          child: Column(children: [
            renderNode(page.appBar, env),
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight, minWidth: constraints.maxWidth),
                    child: renderNode(page.body, env),
                  ),
                ),
              ),
            ),
            renderNode(page.footer, env),
          ]),
        ),
      ),
      // خروج از اجرای آزمایشی
      floatingActionButton: FloatingActionButton.small(
        heroTag: null,
        tooltip: 'بستن اجرای آزمایشی',
        onPressed: () => Get.back(),
        child: const Icon(Icons.close),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }
}
