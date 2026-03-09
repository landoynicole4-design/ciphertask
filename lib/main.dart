import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'views/widgets/splash_screen.dart';
import 'models/todo_model.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/key_storage_service.dart';
import 'services/session_service.dart';
import 'utils/constants.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/otp_view.dart';
import 'views/register_view.dart';
import 'views/todo_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TodoModelAdapter());

  final keyStorageService = KeyStorageService();
  final encryptionService = EncryptionService(keyStorage: keyStorageService);
  final databaseService = DatabaseService(keyStorage: keyStorageService);
  final sessionService = SessionService();
  final localAuth = LocalAuthentication();

  await encryptionService.initialize();
  await databaseService.openDatabase();

  // Create AuthViewModel first so TodoViewModel can reference the current user
  final authViewModel = AuthViewModel(
    localAuth: localAuth,
    keyStorage: keyStorageService,
    sessionService: sessionService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProxyProvider<AuthViewModel, TodoViewModel>(
          // Initial instance before any login (currentUserId is null)
          create: (_) => TodoViewModel(
            databaseService: databaseService,
            encryptionService: encryptionService,
            currentUserId: null,
          ),
          // Called whenever AuthViewModel notifies (login/logout)
          // Reuses the existing TodoViewModel and updates the userId
          update: (_, auth, previous) {
            final vm = previous ??
                TodoViewModel(
                  databaseService: databaseService,
                  encryptionService: encryptionService,
                );
            vm.setCurrentUser(auth.currentUser?.email);
            return vm;
          },
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
    // Use navigatorKey from AuthViewModel so SessionService can
    // navigate to login on timeout from outside the widget tree.
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return Listener(
      // Reset inactivity timer on every screen touch.
      // This is what keeps active users from being auto-logged out.
      onPointerDown: (_) {
        if (authVM.isLoggedIn) {
          authVM.onUserActivity();
        }
      },
      child: MaterialApp(
        title: 'CipherTask',
        debugShowCheckedModeBanner: false,

        // IMPROVEMENT: Wire navigatorKey from AuthViewModel so that
        // SessionService can push the login route on timeout
        // without needing a BuildContext.
        navigatorKey: authVM.navigatorKey,

        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: AppConstants.splashRoute, // ← was loginRoute
        routes: {
          AppConstants.splashRoute: (context) => const SplashScreen(
              nextRoute: AppConstants.loginRoute), // ← ADD THIS
          AppConstants.loginRoute: (context) => const LoginView(),
          AppConstants.registerRoute: (context) => const RegisterView(),
          AppConstants.otpRoute: (context) => const OtpView(),
          AppConstants.todoListRoute: (context) => const TodoListView(),
        },
      ),
    );
  }
}
