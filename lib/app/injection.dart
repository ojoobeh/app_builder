import 'package:get/get.dart';
import '../features/builder/data/datasources/hive_local_datasource.dart';
import '../features/builder/data/migrations/legacy_pages_migration.dart';
import '../features/builder/data/repositories/model_repository_impl.dart';
import '../features/builder/data/repositories/page_repository_impl.dart';
import '../features/builder/data/repositories/project_repository_impl.dart';
import '../features/builder/data/repositories/template_repository_impl.dart';
import '../features/builder/data/services/zip_project_archiver.dart';
import '../features/builder/domain/codegen/dart_code_generator.dart';
import '../features/builder/domain/codegen/project_code_generator.dart';
import '../features/builder/domain/repositories/model_repository.dart';
import '../features/builder/domain/repositories/page_repository.dart';
import '../features/builder/domain/repositories/project_repository.dart';
import '../features/builder/domain/repositories/template_repository.dart';
import '../features/builder/domain/usecases/model_usecases.dart';
import '../features/builder/domain/usecases/page_usecases.dart';
import '../features/builder/domain/usecases/project_usecases.dart';
import '../features/builder/domain/usecases/template_usecases.dart';
import '../features/builder/presentation/controllers/editor_controller.dart';
import '../features/builder/presentation/controllers/models_controller.dart';
import '../features/builder/presentation/controllers/project_detail_controller.dart';
import '../features/builder/presentation/controllers/projects_controller.dart';
import '../features/builder/presentation/controllers/templates_controller.dart';

/// تنها جایی که لایه‌ها به هم وصل می‌شوند (Dependency Injection).
/// data → domain (interface) → presentation
Future<void> setupDependencies() async {
  // data
  final dataSource = HiveLocalDataSource();
  await dataSource.init();
  await LegacyPagesMigration(dataSource).run(); // صفحه‌های نسخه‌ی قبلی را داخل یک پروژه می‌گذارد
  final ProjectRepository projects = ProjectRepositoryImpl(dataSource);
  final PageRepository pages = PageRepositoryImpl(dataSource);
  final TemplateRepository templates = TemplateRepositoryImpl(dataSource);
  final ModelRepository models = ModelRepositoryImpl(dataSource);

  // domain services
  const pageGenerator = DartCodeGenerator();
  Get.put(pageGenerator);
  const projectGenerator = ProjectCodeGenerator(pageGenerator);

  // presentation controllers (usecaseها از همین‌جا تزریق می‌شوند)
  Get.put(ProjectsController(GetProjects(projects), CreateProject(projects), DeleteProject(projects, pages, models)));
  Get.put(ProjectDetailController(
    GetProjectPages(pages),
    CreatePage(pages),
    DeletePage(pages),
    ExportProjectZip(pages, projectGenerator, ZipProjectArchiver(), models),
  ));
  Get.put(TemplatesController(
    GetTemplates(templates),
    SaveTemplate(templates),
    DeleteTemplate(templates),
    ExportTemplates(templates),
    ImportTemplates(templates),
  ));
  Get.put(ModelsController(GetProjectModels(models), SaveModel(models), DeleteModel(models), ParseFieldSpec(models)));
  Get.put(EditorController(savePage: SavePage(pages)));
}
