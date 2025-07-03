import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constant/constants.dart';
import '../../features/providers/loading_provider.dart';
import '../../features/providers/wizard_provider.dart';
import 'package:provider/provider.dart';
import '../routing/router.dart';
import '../theme/light_theme.dart';

class KaliApp extends StatelessWidget {
  const KaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(Constants.screenW, Constants.screenH),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => WizardProvider(totalScreens: 18),
          ),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: PopScope(
          canPop: Platform.isIOS,
          child: MaterialApp.router(
            title: 'Kali',
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),
            theme: lightTheme,
            // EasyLocalization configuration
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );
  }
}
