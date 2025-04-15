import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aaa/components/search_and_filter.dart';
import 'package:aaa/home_screen.dart';
import 'message_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final String baseUrl = "https://backaitu.onrender.com";

  String _searchQuery = '';
  String _selectedFilter = 'all';

  List<dynamic> keysList = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchKeysFromServer();
  }

  Future<void> _fetchKeysFromServer() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/keys');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // data['keys'] – список ключей
          setState(() {
            keysList = data['keys'];  
            errorMessage = '';
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? "Неизвестная ошибка сервера";
          });
        }
      } else {
        setState(() {
          errorMessage = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Ошибка: $e";
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

      bool matchesFilter = _selectedFilter == 'all'
          || (_selectedFilter == 'returned' && !isAvailable)
          || (_selectedFilter == 'received' && isAvailable);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: ['all', 'received', 'returned'].map((filter) {
            String label;
            if (filter == 'all') label = 'Все';
            else if (filter == 'returned') label = 'Не доступен (выдан)';
            else label = 'Доступен';

            return ListTile(
              title: Text(label),
              trailing: _selectedFilter == filter
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _selectedFilter = filter);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // Телефонный вызов
  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  // BottomSheet при тапе на элемент
  void _showCallSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Учитель: Петров П.П', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('+7710504939'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Позвонить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E70E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
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
                      item["key_name"] ?? "",
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      )
                  ],
                ),
              ),
            ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Главная",
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (newIndex) {
          setState(() => _currentIndex = newIndex);
          if (newIndex == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Главная",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
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
                  child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return InkWell(
                      onTap: () => _showCallSheet(context, item["key_name"] ?? ""),
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
}
