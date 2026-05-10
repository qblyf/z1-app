import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: Z1App(),
    ),
  );
}

class Z1App extends StatelessWidget {
  const Z1App({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: '掌上高远',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        barBackgroundColor: CupertinoColors.systemBackground,
      ),
      routerConfig: appRouter,
    );
  }
}
