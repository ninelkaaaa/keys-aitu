import 'package:flutter/material.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> keyHistory = [
    {
      'room': 'C1.3.240',
      'date': '12.01.2024',
      'time': '13:00',
      'status': false, // не сдан (красный)
    },
    {
      'room': 'C1.3.240',
      'date': '12.01.2024',
      'time': '13:00',
      'status': false,
    },
    {
      'room': 'C1.3.245',
      'date': '12.01.2024',
      'time': '13:00',
      'status': true, // сдан (зелёный)
    },
  ];

  void _openScanner(BuildContext context, String action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScannerScreen(action: action),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title:
                    const Text('Получить ключ', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "получить");
                },
              ),
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Сдать ключ', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "сдать");
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Передать ключ другому пользователю',
                    style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _openScanner(context, "передать");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История ключей'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: keyHistory.length,
              itemBuilder: (context, index) {
                final item = keyHistory[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4), // Уменьшено расстояние
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                        leading: Container(
                        width: 6,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: item['status'] ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        'Номер аудитории: ${item['room']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Увеличен размер шрифта
                        ),
                      ),
                      subtitle: Text(
                        'Дата: ${item['date']} \nВремя: ${item['time']}',
                        style: const TextStyle(fontSize: 16), // Увеличен размер шрифта
                      ),
                      trailing: CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            item['status'] ? Colors.green : Colors.red,
                      ),
                      onTap: () {
                        print("Нажатие на ${item['room']}");
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

