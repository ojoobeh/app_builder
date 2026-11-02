import '../bindings/bindings.dart';
import '../entities/model_def.dart';
import '../entities/page_model.dart';
import '../entities/page_request.dart';
import '../entities/project.dart';
import 'dart_code_generator.dart';
import 'model_code_generator.dart';

// این فایل کل یک پروژه را به «فایل‌های کد دارت با معماری Clean Architecture» تبدیل می‌کند.
// هر صفحه‌ی پروژه یک feature جدا می‌شود: domain / data / presentation (صفحه + کنترلر + binding).
// خروجی فقط یک Map از «مسیر فایل ← متن» است؛ ساخت zip کار لایه‌ی data است.

/// یک صفحه‌ی پروژه همراه با نام‌های آماده‌ی فایل و کلاس
class _Feature {
  final PageModel page;
  final String snake; // login → نام پوشه و فایل‌ها
  final String pascal; // Login → نام کلاس‌ها
  final String route; // نام ثابت مسیر در AppRoutes (camelCase)
  const _Feature(this.page, this.snake, this.pascal, this.route);
}

/// کلمه‌های انگلیسی/عددی یک متن (فارسی و علامت‌ها حذف می‌شوند)
List<String> _asciiWords(String text) =>
    text.split(RegExp(r'[^A-Za-z0-9]+')).where((word) => word.isNotEmpty).toList();

/// نام snake_case از متن؛ اگر کلمه‌ی انگلیسی نداشت [fallback]
String _snakeOf(String text, String fallback) {
  final words = _asciiWords(text).map((word) => word.toLowerCase()).toList();
  if (words.isEmpty) return fallback;
  final joined = words.join('_');
  return RegExp(r'^[0-9]').hasMatch(joined) ? '${fallback}_$joined' : joined;
}

String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// متن را برای قرار گرفتن داخل رشته‌ی تک‌نقل‌قولی دارت escape می‌کند
String _escapeForSingleQuotes(String text) =>
    text.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$');

/// صفحه‌های پروژه را به feature تبدیل می‌کند (نام‌ها یکتا می‌شوند)
List<_Feature> _featuresOf(List<PageModel> pages) {
  final usedNames = <String>{};
  final features = <_Feature>[];
  for (final page in pages) {
    final fallback = 'page${page.id.substring(page.id.length - 4)}';
    final baseName = _snakeOf(page.name, fallback);
    var snake = baseName;
    var counter = 2;
    while (!usedNames.add(snake)) {
      snake = '${baseName}_$counter';
      counter++;
    }
    final parts = snake.split('_');
    final pascal = parts.map(_capitalize).join();
    final route = parts.first + parts.skip(1).map(_capitalize).join();
    features.add(_Feature(page, snake, pascal, route));
  }
  return features;
}

/// صفحه‌ی شروع: splash، وگرنه main، وگرنه home، وگرنه اولین صفحه
_Feature _initialFeature(List<_Feature> features) {
  for (final preferred in ['splash', 'main', 'home']) {
    for (final feature in features) {
      if (feature.snake == preferred) return feature;
    }
  }
  return features.first;
}

class ProjectCodeGenerator {
  final DartCodeGenerator _pageGenerator;
  final ModelCodeGenerator _modelGenerator;
  const ProjectCodeGenerator(this._pageGenerator, [this._modelGenerator = const ModelCodeGenerator()]);

  /// نام پوشه‌ی ریشه‌ی پروژه (برای zip)
  String folderName(Project project) => _snakeOf(project.name, 'project');

  /// همه‌ی فایل‌های پروژه: مسیر نسبی ← متن
  Map<String, String> generate(Project project, List<PageModel> pages, {List<ModelDef> models = const []}) {
    final files = <String, String>{};
    final features = _featuresOf(pages);
    final dependencies = <String>{'get: ^4.6.6'};

    // مقصد دکمه‌های ناوبری: شناسه‌ی صفحه ← مسیر و نام کلاس (تغییر نام صفحه ناوبری را خراب نمی‌کند)
    final targets = {for (final feature in features) feature.page.id: PageTarget(feature.route, feature.pascal)};

    // ---------- هر صفحه یک feature ----------
    for (final feature in features) {
      final generated = _pageGenerator.controllerPage(
        feature.page,
        className: '${feature.pascal}Page',
        controllerClass: '${feature.pascal}Controller',
        controllerImport: '../controllers/${feature.snake}_controller.dart',
        targets: targets,
        typedResponse: feature.page.request.enabled
            ? _modelGenerator.typedResponse(feature.page.request.responseType, models)
            : null,
      );
      if (feature.page.request.enabled) dependencies.add('http: ^1.2.0'); // repository از http استفاده می‌کند
      dependencies.addAll(generated.dependencies);

      final base = 'lib/features/${feature.snake}';
      files['$base/domain/repositories/${feature.snake}_repository.dart'] = _repositoryInterface(feature);
      files['$base/data/repositories/${feature.snake}_repository_impl.dart'] = _repositoryImpl(feature);
      files['$base/presentation/controllers/${feature.snake}_controller.dart'] = _controller(feature, generated);
      files['$base/presentation/bindings/${feature.snake}_binding.dart'] = _binding(feature);
      files['$base/presentation/pages/${feature.snake}_page.dart'] = generated.pageSource;
    }

    // ---------- بخش مشترک برنامه ----------
    if (features.isNotEmpty) {
      files['lib/app/routes/app_routes.dart'] = _routes(features);
      files['lib/app/routes/app_pages.dart'] = _appPages(features);
      files['lib/app/app.dart'] = _app(project, _initialFeature(features));
      files['lib/app/core/json_path.dart'] = kJsonPathFileSource; // خواندن مسیر a.b.c از پاسخ JSON (برای bindingها)
    }
    files.addAll(_modelGenerator.generate(models)); // lib/app/models/*.dart
    files['lib/main.dart'] = _main();
    files['pubspec_dependencies.yaml'] = _dependenciesFile(dependencies);
    files['README.md'] = _readme(project, features, models);
    return files;
  }

  // --------------------------------------------------------------------------
  // لایه‌ی domain / data (اسکلت قرارداد و پیاده‌سازی بکند)
  // --------------------------------------------------------------------------

  String _repositoryInterface(_Feature f) {
    if (!f.page.request.enabled) {
      return '''/// قرارداد داده‌ی صفحه‌ی ${f.pascal} (لایه‌ی domain).
/// کارهای مربوط به بکند را اینجا تعریف کن؛ کنترلر فقط از همین قرارداد استفاده می‌کند.
abstract class ${f.pascal}Repository {
  // TODO: متدهای دسترسی به داده را اینجا بنویس. مثال:
  // Future<void> submit(String email);
}
''';
    }
    return '''/// قرارداد داده‌ی صفحه‌ی ${f.pascal} (لایه‌ی domain).
abstract class ${f.pascal}Repository {
  /// اطلاعات صفحه را از سرور می‌گیرد؛ [value] همان مقداری است که صفحه‌ی قبلی فرستاده (ممکن است null باشد).
  /// خروجی: پاسخ JSON (Map یا List).
  Future<dynamic> fetch(String? value);
}
''';
  }

  String _repositoryImpl(_Feature f) {
    final request = f.page.request;
    if (!request.enabled) {
      return '''import '../../domain/repositories/${f.snake}_repository.dart';

/// پیاده‌سازی ${f.pascal}Repository (لایه‌ی data): ارتباط با API یا دیتابیس اینجا نوشته می‌شود.
class ${f.pascal}RepositoryImpl implements ${f.pascal}Repository {
  // TODO: متدهای قرارداد را اینجا پیاده‌سازی کن.
}
''';
    }
    final params = request.params.where((pair) => pair.key.trim().isNotEmpty).toList();
    final headers = request.headers.where((pair) => pair.key.trim().isNotEmpty).toList();
    final inBody = request.paramsInBody && params.isNotEmpty;
    final inQuery = !request.paramsInBody && params.isNotEmpty;
    final httpMethod = request.method.toLowerCase(); // get / post / put / patch / delete
    final bodyArgument = inBody ? ', body: jsonEncode(params)' : '';
    final urlLiteral = _escapeForSingleQuotes(request.url.trim());

    String mapLiteral(List<RequestParam> pairs) => '{\n' +
        pairs
            .map((pair) => "    '${_escapeForSingleQuotes(pair.key.trim())}': '${_escapeForSingleQuotes(pair.value)}',\n")
            .join() +
        '  }';

    final constants = StringBuffer();
    if (params.isNotEmpty) {
      constants.writeln('\n  /// پارامترهای ارسالی (key: value)؛ {value} با مقدار ورودی پر می‌شود');
      constants.writeln('  static const Map<String, String> _params = ${mapLiteral(params)};');
    }
    if (headers.isNotEmpty) {
      constants.writeln('\n  /// هدرها؛ {value} با مقدار ورودی پر می‌شود');
      constants.writeln('  static const Map<String, String> _headers = ${mapLiteral(headers)};');
    }

    final body = StringBuffer()
      ..writeln("    final raw = value ?? '';")
      ..writeln("    String fill(String text) => text.replaceAll('{value}', raw);")
      ..writeln("    final uri = Uri.parse(_url.replaceAll('{value}', Uri.encodeComponent(raw)));");
    if (params.isNotEmpty) {
      body.writeln('    final params = {for (final entry in _params.entries) entry.key: fill(entry.value)};');
    }
    body.writeln("    final headers = <String, String>{'Accept': 'application/json'"
        "${inBody ? ", 'Content-Type': 'application/json'" : ''}};");
    if (headers.isNotEmpty) {
      body.writeln('    for (final entry in _headers.entries) {\n      headers[entry.key] = fill(entry.value);\n    }');
    }
    body.writeln(inQuery
        ? '    final target = uri.replace(queryParameters: {...uri.queryParameters, ...params});'
        : '    final target = uri;');

    return '''import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/repositories/${f.snake}_repository.dart';

/// پیاده‌سازی ${f.pascal}Repository (لایه‌ی data): درخواست ${request.method} به سرور
class ${f.pascal}RepositoryImpl implements ${f.pascal}Repository {
  /// آدرس؛ اگر {value} داشته باشد با مقدار ورودی پر می‌شود
  static const String _url = '$urlLiteral';
$constants
  @override
  Future<dynamic> fetch(String? value) async {
$body    final response = await http.$httpMethod(target, headers: headers$bodyArgument);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP \${response.statusCode}');
    }
    return response.body.trim().isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
  }
}
''';
  }

  // --------------------------------------------------------------------------
  // لایه‌ی presentation: کنترلر و binding
  // --------------------------------------------------------------------------

  /// کنترلر صفحه: وضعیت (فیلدها)، کارها (متدها) و آزادسازی منابع
  String _controller(_Feature f, GeneratedControllerPage generated) {
    final out = StringBuffer();
    if (generated.controllerDisposals.isNotEmpty) out.writeln("import 'package:flutter/material.dart';");
    out.writeln("import 'package:get/get.dart';");
    out.writeln("import '../../domain/repositories/${f.snake}_repository.dart';");
    for (final extraImport in generated.controllerImports) {
      out.writeln(extraImport);
    }
    out.writeln();
    out.writeln('/// کنترلر صفحه‌ی ${f.pascal}: وضعیت صفحه و کارهای مربوط به بکند اینجاست.');
    out.writeln('class ${f.pascal}Controller extends GetxController {');
    out.writeln('  ${f.pascal}Controller(this._repository);');
    out.writeln();
    out.writeln('  // ignore: unused_field');
    out.writeln('  final ${f.pascal}Repository _repository;');

    if (generated.controllerFields.isNotEmpty) {
      out.writeln();
      out.writeln('  // ---------- وضعیت صفحه ----------');
      for (final field in generated.controllerFields) {
        out.writeln('  $field');
      }
    }
    if (generated.controllerMethods.isNotEmpty) {
      out.writeln();
      out.writeln('  // ---------- کارها (کلیک‌ها و کارهای بکند) ----------');
      for (final method in generated.controllerMethods) {
        out.writeln(method.split('\n').map((line) => '  $line').join('\n'));
        out.writeln();
      }
    }
    if (generated.controllerInit.isNotEmpty) {
      out.writeln('  @override');
      out.writeln('  void onInit() {');
      out.writeln('    super.onInit();');
      for (final line in generated.controllerInit) {
        out.writeln('    $line');
      }
      out.writeln('  }');
      out.writeln();
    }
    if (generated.controllerDisposals.isNotEmpty) {
      out.writeln('  @override');
      out.writeln('  void onClose() {');
      for (final disposal in generated.controllerDisposals) {
        out.writeln('    $disposal');
      }
      out.writeln('    super.onClose();');
      out.writeln('  }');
    }
    out.writeln('}');
    return out.toString();
  }

  /// binding: وابستگی‌های صفحه را هنگام ورود به آن می‌سازد (repository → controller)
  String _binding(_Feature f) => '''import 'package:get/get.dart';
import '../../data/repositories/${f.snake}_repository_impl.dart';
import '../../domain/repositories/${f.snake}_repository.dart';
import '../controllers/${f.snake}_controller.dart';

/// اتصال وابستگی‌های صفحه‌ی ${f.pascal} (Dependency Injection)
class ${f.pascal}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<${f.pascal}Repository>(() => ${f.pascal}RepositoryImpl());
    Get.lazyPut<${f.pascal}Controller>(() => ${f.pascal}Controller(Get.find<${f.pascal}Repository>()));
  }
}
''';

  // --------------------------------------------------------------------------
  // بخش مشترک برنامه: مسیرها و شروع
  // --------------------------------------------------------------------------

  String _routes(List<_Feature> features) {
    final lines = features.map((f) => "  static const ${f.route} = '/${f.snake}';").join('\n');
    return '''/// نام مسیرهای برنامه (برای رفتن به یک صفحه: Get.toNamed(AppRoutes.login))
abstract class AppRoutes {
$lines
}
''';
  }

  String _appPages(List<_Feature> features) {
    final imports = features.map((f) => "import '../../features/${f.snake}/presentation/bindings/${f.snake}_binding.dart';\n"
        "import '../../features/${f.snake}/presentation/pages/${f.snake}_page.dart';").join('\n');
    final pages = features.map((f) => '    GetPage(\n'
        '      name: AppRoutes.${f.route},\n'
        '      page: () => const ${f.pascal}Page(),\n'
        '      binding: ${f.pascal}Binding(),\n'
        '    ),').join('\n');
    return '''import 'package:get/get.dart';
$imports
import 'app_routes.dart';

/// فهرست صفحه‌های برنامه؛ هر صفحه با binding خودش ساخته می‌شود.
class AppPages {
  static final pages = <GetPage>[
$pages
  ];
}
''';
  }

  String _app(Project project, _Feature initial) => '''import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

/// ریشه‌ی برنامه: تم، مسیر شروع و فهرست صفحه‌ها
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '${_escapeForSingleQuotes(project.name)}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.${initial.route},
      getPages: AppPages.pages,
    );
  }
}
''';

  String _main() => '''import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  runApp(const App());
}
''';

  // --------------------------------------------------------------------------
  // فایل‌های راهنما
  // --------------------------------------------------------------------------

  String _dependenciesFile(Set<String> dependencies) =>
      '# این خطوط را زیر dependencies در pubspec.yaml پروژه‌ی Flutter اضافه کن:\n'
      '${dependencies.map((line) => '  $line').join('\n')}\n'
      '# (Flutter 3.27 یا بالاتر لازم است)\n';

  String _readme(Project project, List<_Feature> features, List<ModelDef> models) {
    final pageList = features.isEmpty
        ? '(این پروژه هنوز صفحه‌ای ندارد)'
        : features.map((f) => '- ${f.snake}  ←  صفحه‌ی «${f.page.name}»').join('\n');
    final modelSection = models.isEmpty
        ? ''
        : '\n## مدل‌های داده\n'
            'کلاس‌های `lib/app/models/` از روی مدل‌های تعریف‌شده در پروژه ساخته شده‌اند '
            '(fromJson / toJson / copyWith). برای import همه: `import \'app/models/models.dart\';`\n'
            '${models.map((model) => '- ${model.name}').join('\n')}\n';
    return '''# ${project.name}

پروژه‌ی تولیدشده با Page Builder (معماری Clean Architecture + GetX).

## اجرا
1. یک پروژه‌ی Flutter بساز: `flutter create my_app`
2. پوشه‌ی `lib` این پروژه را جایگزین `lib` پروژه‌ی خودت کن.
3. خطوط فایل `pubspec_dependencies.yaml` را به `pubspec.yaml` اضافه کن و `flutter pub get` بزن.
4. `flutter run`

## صفحه‌ها
$pageList
$modelSection
## ساختار
```
lib/
├─ main.dart
├─ app/
│   ├─ app.dart                 ریشه‌ی برنامه و مسیر شروع
│   └─ routes/                  app_routes.dart (نام مسیرها) و app_pages.dart (فهرست صفحه‌ها)
└─ features/<صفحه>/
    ├─ domain/repositories/     قرارداد داده (interface)
    ├─ data/repositories/       پیاده‌سازی (API / دیتابیس)
    └─ presentation/
        ├─ pages/               ظاهر صفحه (GetView)
        ├─ controllers/         وضعیت صفحه و کارهای بکند
        └─ bindings/            ساخت وابستگی‌ها هنگام ورود به صفحه
```

## کجا کد بنویسم؟
- کارهای بکند: متدهای `TODO` در `controllers/<صفحه>_controller.dart`
  (با قرارداد `domain/repositories` و پیاده‌سازی `data/repositories`).
- رفتن به صفحه‌ی دیگر: `Get.toNamed(AppRoutes.<نام>)`.
- صفحه‌هایی که «درخواست صفحه» دارند: آدرس و پارامتر در `data/repositories/<صفحه>_repository_impl.dart` است و
  کنترلر هنگام ورود متد `load()` را صدا می‌زند (نتیجه: `data` خام، `items` ردیف‌های لیست، `response` با نوع مدلی که برای پاسخ انتخاب کرده‌ای، `isLoading`، `errorMessage`).
- دکمه‌های ناوبری مقدار را با `Get.toNamed(..., arguments: مقدار)` می‌فرستند؛ در صفحه‌ی مقصد `controller.args`.
''';
  }
}
