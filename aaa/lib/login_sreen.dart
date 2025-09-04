import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'home_screen.dart';
import 'admin/admin_home.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isError = false;
  bool isLoading = false;
  String errorMessage = '';

  final String baseUrl = "http://10.250.0.19:3000";

  Future<void> _loginRequest() async {
    setState(() {
      isError = false;
      isLoading = true;
    });

    final url = Uri.parse('$baseUrl/login');
    final body = {
      "user": phoneController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("user_id", data["user_id"] ?? 0);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => data["admin"] == true
                ? const AdminHome()
                : HomeScreen(userId: data["user_id"]),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            isError = true;
            errorMessage = "Данные введены неверно.Попробуйте снова";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isError = true;
          errorMessage = "Ошибка сети: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  final _phoneFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('8')) digits = '7' + digits.substring(1);
    if (!digits.startsWith('7')) digits = '7' + digits;

    String formatted = '+7';
    if (digits.length > 1)
      formatted += ' ${digits.substring(1, min(4, digits.length))}';
    if (digits.length > 4)
      formatted += ' ${digits.substring(4, min(7, digits.length))}';
    if (digits.length > 7)
      formatted += ' ${digits.substring(7, min(9, digits.length))}';
    if (digits.length > 9)
      formatted += ' ${digits.substring(9, min(11, digits.length))}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 200),
            const SizedBox(height: 50),
            const Text(
              "Вход",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              decoration: const InputDecoration(
                labelText: "Телефон",
                hintText: "+7 xxx xxx xx xx",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Код доступа",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (isError)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loginRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Войти",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
