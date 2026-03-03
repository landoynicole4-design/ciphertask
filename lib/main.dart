import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'models/todo_model.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/key_storage_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/todo_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TodoModelAdapter());

  // Initialize services
  final keyStorageService = KeyStorageService();
  final encryptionService = EncryptionService(keyStorage: keyStorageService);
  final databaseService = DatabaseService(keyStorage: keyStorageService);
  final sessionService = SessionService();
  final localAuth = LocalAuthentication();

  // Initialize encryption service
  await encryptionService.initialize();

  // Open database
  await databaseService.openDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            localAuth: localAuth,
            keyStorage: keyStorageService,
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TodoViewModel(
            databaseService: databaseService,
            encryptionService: encryptionService,
          ),
        ),
      ],
      child: const CipherTaskApp(),
    ),
  );
}

class CipherTaskApp extends StatelessWidget {
  const CipherTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listen for pointer events to reset session timer on user activity
      onPointerDown: (_) {
        // Get the AuthViewModel and reset session timer if user is logged in
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        if (authVM.isLoggedIn) {
          authVM.onUserActivity();
        }
      },
      child: MaterialApp(
        title: 'CipherTask',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: AppConstants.loginRoute,
        routes: {
          AppConstants.loginRoute: (context) => const LoginView(),
          AppConstants.registerRoute: (context) => const RegisterView(),
          AppConstants.todoListRoute: (context) => const TodoListView(),
        },
      ),
    );
  }
}
