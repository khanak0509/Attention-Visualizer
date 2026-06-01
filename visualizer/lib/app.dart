import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'main_shell.dart';
import 'typography.dart';

class AttentionVisualizerApp extends StatelessWidget {
  const AttentionVisualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLM Attention Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: AppColors.background,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        tooltipTheme: TooltipThemeData(
          textStyle: interText(12, color: AppColors.textPrimary),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}
