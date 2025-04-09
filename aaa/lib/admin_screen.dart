import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  final List<Map<String, dynamic>> keys = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Главная", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: Icon(Icons.search, size: 24),
                suffixIcon: Icon(Icons.filter_list, size: 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4), // Уменьшено расстояние
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
                          color: key['status'] ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        key['room'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Увеличен размер шрифта
                        ),
                      ),
                      subtitle: Text(
                        "${key['date']}   ${key['time']}",
                        style: TextStyle(fontSize: 16), // Увеличен размер шрифта
                      ),
                      trailing: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            key['status'] ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Главная',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.blue,
                    child: Text(
                      '2',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            label: 'Сообщения',
            backgroundColor: Colors.white,
          ),
        ],
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.blue,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}