import 'package:flutter/material.dart';
import 'package:recycle_m_mobile/screens/error_screen.dart';

import 'screens/chat_screen.dart';
import 'screens/compose_screen.dart';
import 'screens/congratulations_screen.dart';
import 'screens/content_detail_screen.dart';
import 'screens/content_screen.dart';
import 'screens/expenses_calendar_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/images_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/login_screen.dart';
import 'screens/market_screen.dart';
import 'screens/product_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rate_app_screen.dart';
import 'screens/search_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/upload_photo_screen.dart';
import 'screens/user_options_screen.dart';
import 'screens/waste_collection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycle-M',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const LoginScreen(),
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          String errorMessage = errorDetails.exceptionAsString();
          String stackTrace = '';

          if (errorDetails.stack != null) {
            var lines = errorDetails.stack.toString().split('\n');

            // Find the first line that contains your package name
            int startIndex = lines.indexWhere((line) => line.contains('recycle_m_mobile/'));

            if (startIndex != -1) {
              int endIndex = startIndex + 3 < lines.length ? startIndex + 3 : lines.length;
              stackTrace = lines.sublist(startIndex, endIndex).join('\n');
            } else {
              stackTrace = lines.take(3).join('\n');
            }
          }

          return ErrorScreen(
            title: 'Oops! Something went wrong',
            errorData: '$errorMessage\n\n$stackTrace',
          );
        };
        return widget ?? const SizedBox.shrink();
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/blog_post' || settings.name == '/article') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ContentDetailScreen(
              contentId: args['id'],
              contentType:
                  settings.name == '/article' ? 'article' : 'blog_post',
            ),
          );
        }
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientId: args['recipientId'],
              recipientName: args['recipientName'],
            ),
          );
        }
        if (settings.name == '/congratulations') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CongratulationsScreen(
              title: args['title'],
              message: args['message'],
              primaryActionText: args['primaryActionText'] ?? 'Continue',
              secondaryActionText: args['secondaryActionText'],
              onPrimaryAction: args['onPrimaryAction'],
              onSecondaryAction: args['onSecondaryAction'],
            ),
          );
        }
        return null;
      },
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/feed': (context) => const FeedScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/content': (context) => const ContentScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/rate_app': (context) => const RateAppScreen(),
        '/user_options': (context) => const UserOptionsScreen(),
        '/compose': (context) => const ComposeScreen(),
        '/images': (context) => const ImagesScreen(),
        '/insights': (context) => const InsightsScreen(),
        '/market': (context) => const MarketScreen(),
        '/search': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return SearchScreen(initialQuery: args?['initialQuery'] ?? '');
        },
        '/expenses_calendar': (context) => const ExpensesCalendarScreen(),
        '/waste_collection': (context) => const WasteCollectionScreen(),
        '/content_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || args['id'] == null) {
            // Instead of directly navigating, we'll return an ErrorScreen widget
            return ErrorScreen(
              title: 'Error',
              errorData: 'Invalid content details',
            );
          }
          return ContentDetailScreen(
            contentId: args['id'] as int,
            contentType: args['contentType'] as String? ?? 'Article',
          );
        },
        '/product': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ProductScreen(productId: args['productId']);
        },
        '/upload_photo': (context) => const UploadPhotoScreen(),
        '/error': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ErrorScreen(
            title: args?['title'] ?? 'Error',
            errorData: args?['text'] ?? 'An unexpected error occurred.',
          );
        },
      },
    );
  }
}
