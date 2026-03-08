import 'package:flutter/material.dart';
import '../eden_ui.dart';
import 'screens/home_screen.dart';

/// Dev catalog app for previewing Eden UI components.
class EdenDevApp extends StatefulWidget {
  const EdenDevApp({super.key});

  @override
  State<EdenDevApp> createState() => _EdenDevAppState();
}

class _EdenDevAppState extends State<EdenDevApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  MaterialColor _brandColor = EdenColors.gold;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _setBrandColor(MaterialColor color) {
    setState(() {
      _brandColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eden UI — Dev Catalog',
      debugShowCheckedModeBanner: false,
      theme: EdenTheme.light(brand: _brandColor),
      darkTheme: EdenTheme.dark(brand: _brandColor),
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        brandColor: _brandColor,
        onToggleTheme: _toggleTheme,
        onBrandColorChanged: _setBrandColor,
      ),
    );
  }
}
