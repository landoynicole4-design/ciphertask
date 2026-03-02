import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'models/todo_model.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/key_storage_service.dart';
import 'services/session_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/todo_list_view.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling (for local-only mode)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase not configured - continue in local-only mode
    debugPrint('Firebase not configured: $e');
  }

  await Hive.initFlutter();
  Hive.registerAdapter(TodoModelAdapter());
  final keyStorageService = KeyStorageService();
  final databaseService = DatabaseService(keyStorage: keyStorageService);
  await databaseService.openDatabase();
  final encryptionService = EncryptionService(keyStorage: keyStorageService);
  await encryptionService.initialize();
  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  runApp(CipherTaskApp(
    keyStorageService: keyStorageService,
    databaseService: databaseService,
    encryptionService: encryptionService,
  ));
}

class CipherTaskApp extends StatelessWidget {
  final KeyStorageService keyStorageService;
  final DatabaseService databaseService;
  final EncryptionService encryptionService;

  const CipherTaskApp({
    super.key,
    required this.keyStorageService,
    required this.databaseService,
    required this.encryptionService,
  });

  @override
  Widget build(BuildContext context) {
    // AuthViewModel is created once here and holds its own navigatorKey.
    // The key is passed to MaterialApp below so the ViewModel can navigate
    // without ever needing a BuildContext.
    final authViewModel = AuthViewModel(
      firebaseAuth: FirebaseAuth.instance,
      localAuth: LocalAuthentication(),
      keyStorage: keyStorageService,
      sessionService: SessionService(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider(
          create: (_) => TodoViewModel(
            databaseService: databaseService,
            encryptionService: encryptionService,
          ),
        ),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return Listener(
            // Reset session timer on every user touch.
            onPointerDown: (_) => authVM.onUserActivity(),
            child: MaterialApp(
              title: 'CipherTask',
              debugShowCheckedModeBanner: false,
              // Use the ViewModel's own navigatorKey — this is what allows
              // session timeout to navigate without a BuildContext.
              navigatorKey: authVM.navigatorKey,
              theme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF4ECDC4),
                scaffoldBackgroundColor: const Color(0xFF0A0E1A),
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF4ECDC4),
                  surface: Color(0xFF1A2035),
                ),
              ),
              initialRoute: AppConstants.loginRoute,
              routes: {
                AppConstants.loginRoute: (_) => const LoginView(),
                AppConstants.registerRoute: (_) => const RegisterView(),
                AppConstants.todoListRoute: (_) => const TodoListView(),
              },
            ),
          );
        },
      ),
    );
  }
}
