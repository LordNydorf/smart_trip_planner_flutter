import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/system_ui_service.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/pages/sign_in_page.dart';
import 'features/auth/pages/sign_up_page.dart';
import 'features/auth/pages/enter_name_page.dart';
import 'features/home/home_page.dart';
import 'features/itinerary/generated_itinerary_page.dart';
import 'features/chat/follow_up_chat_page.dart';
import 'features/profile/profile_page.dart';
import 'features/splash/splash_screen.dart';
import 'models/itinerary_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI using our service
  SystemUIService.setLightSystemUI();
  SystemUIService.setEdgeToEdgeMode();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ItineraryAdapter());
  Hive.registerAdapter(ItineraryDayAdapter());
  Hive.registerAdapter(ItineraryItemAdapter());

  // Open Hive boxes
  await Hive.openBox('savedTrips');
  await Hive.openBox('userStats');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Itinera AI',
      theme: AppTheme.lightTheme,
      home: const SplashWrapper(),
      routes: {
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/enter-name': (context) => const EnterNamePage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/generate-itinerary':
            final prompt = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) =>
                  GeneratedItineraryPage(originalPrompt: prompt),
            );
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => FollowUpChatPage(
                originalPrompt: args['originalPrompt'],
                currentItinerary: args['itinerary'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    // Show loading while checking auth state
    if (user == null) {
      return const SignInPage();
    }

    // User is signed in
    return const HomePage();
  }
}
