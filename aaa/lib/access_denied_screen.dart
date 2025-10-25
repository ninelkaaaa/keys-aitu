import 'package:flutter/material.dart';


class AccessDeniedScreen extends StatelessWidget {
  final String cabinetCode;
  final String action;

  const AccessDeniedScreen({
    super.key,
    required this.cabinetCode,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ошибка доступа")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Вы не можете ${action.toLowerCase()} ключ от кабинета $cabinetCode",
              style: const TextStyle(fontSize: 20, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Вернуться назад"),
            ),
          ],
        ),
      ),
    );
  }
}
