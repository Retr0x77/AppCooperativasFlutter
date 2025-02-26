import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'cooperative_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/cooperatives_screen.dart';
import 'screens/create_cooperative_screen.dart';
import 'screens/join_cooperative_screen.dart';
import 'screens/cooperative_detail_screen.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    databaseFactory = databaseFactory;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final authService = AuthService();
  await authService.syncWithServer();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => CooperativeService()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/cooperatives': (context) => CooperativesScreen(),
          '/create_cooperative': (context) => CreateCooperativeScreen(),
          '/join_cooperative': (context) => JoinCooperativeScreen(
                cooperativeId:
                    ModalRoute.of(context)!.settings.arguments as String,
              ),
          '/cooperative_detail': (context) => CooperativeDetailScreen(
                cooperativeId:
                    ModalRoute.of(context)!.settings.arguments as String,
              ),
        },
      ),
    ),
  );
}
