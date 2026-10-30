import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/builder_controller.dart';
import 'package:untitled/home_screen.dart';
import 'package:untitled/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  Get.put(BuilderController());
  runApp(GetMaterialApp(
    title: 'Page Builder',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const HomeScreen(),
  ));
}
