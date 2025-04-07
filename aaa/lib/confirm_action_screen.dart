import 'package:flutter/material.dart';

class ConfirmActionScreen extends StatelessWidget {
  final String cabinetCode;
  final String action;

  const ConfirmActionScreen({
    super.key,
    required this.cabinetCode,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Подтверждение действия")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Вы действительно хотите ${action.toLowerCase()} ключ от кабинета $cabinetCode?",
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true); // Подтверждение
                  },
                  child: const Text("Да"),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false); // Отмена
                  },
                  child: const Text("Нет"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
