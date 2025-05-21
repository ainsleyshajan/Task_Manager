import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskmanager/Screens/addtask.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> tasks = [];
  late int userid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFBA68C8), Color(0xFF64B5F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              Color statusColor = _getStatusColor(tasks[index]['status']!);

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    tasks[index]['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tasks[index]['status']!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Navigate to TaskDetailsScreen and await the result
                    await Navigator.pushNamed(
                      context,
                      '/taskdetail',
                      arguments: tasks[index]['id'],
                    );
                    // Re-fetch tasks after returning from TaskDetailsScreen
                    fetchTasks();
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddTaskScreen and await the result
          bool? taskAdded = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => AddTask()));

          if (taskAdded != null && taskAdded) {
            // If a new task was added, refresh the task list
            fetchTasks();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Future<void> fetchTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userid = prefs.getInt('user_id') ?? 0;
    String url =
        'https://localhost:7035/api/Task/GetTaskByUserid?userId=$userid';
    print('url$url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          List<dynamic> data = json.decode(response.body);

          setState(() {
            tasks =
                data.map((task) {
                  return {
                    'id': task['taskId'] ?? task['id'] ?? 0,
                    'title': task['title'] ?? task['Title'] ?? '',
                    'status': task['status'] ?? task['Status'] ?? '',
                  };
                }).toList();
          });
        } catch (e) {
          print('Error parsing response: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error parsing response: $e')));
        }
      } else {
        print('Failed to load tasks, Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load tasks')));
      }
    } catch (e) {
      print('Error during API call: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // Helper function to determine status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return Colors.red;
      case 'In Progress':
        return Colors.yellow;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
