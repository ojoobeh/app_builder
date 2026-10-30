import 'package:get/get.dart';
import '../features/builder/data/datasources/hive_local_datasource.dart';
import '../features/builder/data/repositories/page_repository_impl.dart';
import '../features/builder/data/repositories/template_repository_impl.dart';
import '../features/builder/domain/codegen/dart_code_generator.dart';
import '../features/builder/domain/repositories/page_repository.dart';
import '../features/builder/domain/repositories/template_repository.dart';
import '../features/builder/domain/usecases/page_usecases.dart';
import '../features/builder/domain/usecases/template_usecases.dart';
import '../features/builder/presentation/controllers/editor_controller.dart';
import '../features/builder/presentation/controllers/home_controller.dart';
import '../features/builder/presentation/controllers/templates_controller.dart';

/// تنها جایی که لایه‌ها به هم وصل می‌شوند (Dependency Injection).
/// data → domain (interface) → presentation
Future<void> setupDependencies() async {
  // data
  final ds = HiveLocalDataSource();
  await ds.init();
  final PageRepository pages = PageRepositoryImpl(ds);
  final TemplateRepository templates = TemplateRepositoryImpl(ds);

  // domain services
  Get.put(const DartCodeGenerator());

  // presentation controllers (usecaseها از همین‌جا تزریق می‌شوند)
  Get.put(HomeController(GetPages(pages), CreatePage(pages), DeletePage(pages)));
  Get.put(TemplatesController(
    GetTemplates(templates),
    SaveTemplate(templates),
    DeleteTemplate(templates),
    ExportTemplates(templates),
    ImportTemplates(templates),
  ));
  Get.put(EditorController(savePage: SavePage(pages)));
}
