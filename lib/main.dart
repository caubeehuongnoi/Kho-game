import 'package:flutter/material.dart';
import 'package:bac_thay_tri_nho/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:bac_thay_tri_nho/themes/app_themes.dart';
import 'package:bac_thay_tri_nho/providers/theme_provider.dart';
import 'package:bac_thay_tri_nho/providers/sound_provider.dart';
import 'package:bac_thay_tri_nho/providers/history_provider.dart';
import 'package:bac_thay_tri_nho/screens/menu_screen.dart';

void main() {
  runApp(const MemoryCardFlipApp());
}

/// Widget gốc của ứng dụng.
class MemoryCardFlipApp extends StatelessWidget {
  const MemoryCardFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SoundProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Bậc Thầy Trí Nhớ',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final textScale = themeProvider.textScale;
              final mediaQuery = MediaQuery.of(context);

              // Hãy gọi playBackgroundMusic() sau một hành động người dùng (ví dụ sau khi đăng nhập).

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },

            // 👇 mở app thì vào Login trước
            home: const LoginScreen(),
            routes: {
              '/menu': (_) => const MenuScreen(), // 👈 để điều hướng sau login
            },
          );
        },
      ),
    );
  }
}
