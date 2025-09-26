import 'package:aaa/login_sreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aaa/components/search_and_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  final String baseUrl = "http://10.250.0.19:5000";

  // Значения по умолчанию
  static const String _defaultTeacherPhone = '+7710504939';
  static const String _defaultTeacherName = 'Петров П.П';

  String _searchQuery = '';
  String _selectedFilter = 'all';

  List<dynamic> keysList = [];
  bool isLoading = false;
  String errorMessage = '';

  // Контактная информация с сервера
  String teacherPhone = '';
  String teacherName = '';

  @override
  void initState() {
    super.initState();
    _fetchKeysFromServer();
  }

  Future<void> _fetchKeysFromServer() async {
    setState(() => isLoading = true);
    try {
      // Получаем ключи (основные данные)
      final keysUrl = Uri.parse('$baseUrl/keys');
      final keysResponse = await http.get(keysUrl);

      // Получаем контактную информацию
      final contactUrl = Uri.parse('$baseUrl/contact-info');
      final contactResponse = await http.get(contactUrl);

      if (keysResponse.statusCode == 200) {
        final keyData = jsonDecode(keysResponse.body);
        print('Server response: $keyData'); // Отладка
        if (keyData['status'] == 'success') {
          setState(() {
            keysList = keyData['keys'];
            errorMessage = '';
          });
          print('Keys loaded: ${keysList.length} items'); // Отладка
        } else {
          setState(() {
            errorMessage = keyData['message'] ?? "Неизвестная ошибка сервера";
          });
        }
      } else {
        print('HTTP Error: ${keysResponse.statusCode}'); // Отладка
        setState(() {
          errorMessage = 'Ошибка сервера: ${keysResponse.statusCode}';
        });
      }

      // Обрабатываем контактную информацию
      if (contactResponse.statusCode == 200) {
        final contactData = jsonDecode(contactResponse.body);
        if (contactData['status'] == 'success') {
          setState(() {
            teacherPhone =
                contactData['phone'] ?? _defaultTeacherPhone; // fallback
            teacherName =
                contactData['teacher_name'] ?? _defaultTeacherName; // fallback
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Ошибка: $e";
        // Устанавливаем значения по умолчанию при ошибке
        teacherPhone = _defaultTeacherPhone;
        teacherName = _defaultTeacherName;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get _filteredItems {
    return keysList.where((item) {
      final title = (item["key_name"] ?? "").toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase());

      bool isAvailable = item["available"] == true;

      bool matchesFilter =
          _selectedFilter == 'all' ||
          (_selectedFilter == 'returned' && !isAvailable) ||
          (_selectedFilter == 'received' && isAvailable);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Не удалось запустить вызов: $phoneNumber';
    }
  }

  void _showCallDialog(
    BuildContext context,
    String title,
    String teacherName,
    String phoneNumber,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Call Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Учитель: $teacherName',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(phoneNumber),
                      icon: const Icon(Icons.phone),
                      label: Text('$phoneNumber'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E70E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9F9F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final options = {
          'all': 'Все',
          'received': 'Доступен',
          'returned': 'Не доступен (выдан)',
        };

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Фильтр по статусу',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),
              ...options.entries.map((entry) {
                final isSelected = _selectedFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => _selectedFilter = entry.key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE3EFFE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF1D5DCC)
                                    : const Color(0xFF3C3C3C),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF1D5DCC),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemCard(dynamic item) {
    bool isAvailable = item["available"] == true;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 75,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isAvailable ? Colors.grey : Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["key_name"] ?? "Без названия",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isAvailable)
                      Text(
                        "Выдан: ${item['last_user'] ?? 'Неизвестно'}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      )
                    else
                      Text(
                        "Доступен",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

            // Кнопка звонка, если ключ выдан
            if (!isAvailable)
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue),
                onPressed: () {
                  final teacherName = item['last_user'] ?? 'Неизвестно';
                  final phoneNumber = item['phone'] ?? '+77000000000';
                  _showCallDialog(
                    context,
                    item["key_name"] ?? "",
                    teacherName,
                    phoneNumber,
                  );
                },
              ),

            // Индикатор доступности
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text("Управление ключами"),
       actions: [
         IconButton(
           icon: const Icon(Icons.logout),
           tooltip: "Выйти",
           onPressed: () => _confirmLogout(context),
         ),
       ],
     ),
     bottomNavigationBar: BottomNavigationBar(
       currentIndex: _currentIndex,
       onTap: (index) {
         setState(() => _currentIndex = index);
         if (index == 1) {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (_) => const MessagePage()),
           );
         }
       },
       items: const [
         BottomNavigationBarItem(
           icon: Icon(Icons.home_outlined),
           activeIcon: Icon(Icons.home),
           label: "Главная",
         ),
         BottomNavigationBarItem(
           icon: Icon(Icons.mail_outline),
           activeIcon: Icon(Icons.mail),
           label: "Сообщения",
         ),
       ],
     ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            SearchAndFilter(
              searchQuery: _searchQuery,
              onSearchChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onFilterPressed: _showFilterSheet,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    print('Item contents: $item');
                    return InkWell(
                      onTap: () {
                        final teacherName = item['last_user'] ?? 'Неизвестно';
                        final phoneNumber = item['phone'] ?? '+77000000000';
                        _showCallDialog(
                          context,
                          item["key_name"] ?? "",
                          teacherName,
                          phoneNumber,
                        );
                      },
                      child: _buildItemCard(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Подтвердите выход",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                "Вы действительно хотите выйти из аккаунта?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Отмена"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Выйти"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("user_id");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}
