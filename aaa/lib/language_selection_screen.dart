import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  void _selectLanguage(BuildContext context, Locale locale) {
    context.setLocale(locale);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Colors.blue;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 180),
              const SizedBox(height: 40),
              Text(
                tr('language_select'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _selectLanguage(context, const Locale('kk')),
                  icon: const Icon(Icons.language),
                  label: const Text('Қазақ тілі'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _selectLanguage(context, const Locale('ru')),
                  icon: const Icon(Icons.language),
                  label: const Text('Русский язык'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}