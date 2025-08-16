import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Running',
      theme: ThemeData(
        // 使用白色作为基色的配色方案
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
          primary: Colors.white,
          onPrimary: Colors.black87,
          secondary: Colors.grey.shade100,
          onSecondary: Colors.black87,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.white,
          onBackground: Colors.black87,
          error: Colors.red.shade400,
          onError: Colors.white,
        ),
        useMaterial3: true,

        // 应用栏主题
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // 卡片主题
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // 导航栏主题
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.grey.shade100,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Colors.black87);
            }
            return IconThemeData(color: Colors.grey.shade600);
          }),
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 文本按钮主题
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
        ),

        // 图标主题
        iconTheme: const IconThemeData(color: Colors.black87),

        // 文本主题
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.grey),
        ),

        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black87),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
        ),

        // 对话框主题
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // 底部导航栏主题
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      home: const HomePage(),
    );
  }
}
