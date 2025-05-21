import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Map<String, dynamic>? task;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int taskId = ModalRoute.of(context)!.settings.arguments as int;
    fetchTaskDetails(taskId);
  }

  Future<void> fetchTaskDetails(int taskId) async {
    try {
      final url = 'https://localhost:7035/api/Task/GetTaskById?taskId=$taskId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          task = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load task details')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this task?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final url =
          'https://localhost:7035/api/Task/Delete?id=${task!['taskId']}';

      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(context, true); // Return to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${response.body}')),
        );
      }
    }
  }

  void _showEditDialog() {
    final titleCtrl = TextEditingController(text: task!['title']);
    final descCtrl = TextEditingController(text: task!['descriptions']);
    final deadlineCtrl = TextEditingController(text: task!['deadline']);

    String status = (task!['status'] ?? '').toString().trim();
    switch (status.toLowerCase()) {
      case 'pending':
        status = 'Pending';
        break;
      case 'in progress':
        status = 'In Progress';
        break;
      case 'completed':
        status = 'Completed';
        break;
      default:
        status = 'Pending';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Task"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descriptions',
                    ),
                  ),
                  DropdownButton<String>(
                    value: status,
                    items:
                        ['Pending', 'In Progress', 'Completed'].map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                    onChanged: (val) => setState(() => status = val!),
                  ),
                  TextField(
                    controller: deadlineCtrl,
                    decoration: const InputDecoration(labelText: 'Deadline'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Save"),
                onPressed: () {
                  Navigator.pop(context);
                  _updateTask(
                    titleCtrl.text,
                    descCtrl.text,
                    status,
                    deadlineCtrl.text,
                  );
                },
              ),
            ],
          ),
    );
  }

  void _updateTask(
    String title,
    String descriptions,
    String status,
    String deadline,
  ) async {
    final url =
        'https://localhost:7035/api/Task/Update?taskId=${task!['taskId']}&userId=${task!['userId']}&title=$title&descriptions=$descriptions&status=$status&deadline=$deadline';

    final response = await http.post(Uri.parse(url));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated')));
      fetchTaskDetails(task!['taskId']); // Reload task
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: ${response.body}')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.yellow.shade700;
      case 'completed':
        return Colors.green;
      case 'to do':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
        backgroundColor: Colors.purple[400],
      ),
      body:
          task == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task!['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(task!['status'] ?? ''),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                task!['status'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Descriptions:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(task!['descriptions'] ?? ''),
                        const SizedBox(height: 16),
                        const Text(
                          "Deadline:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(task!['deadline'] ?? ''),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _showEditDialog(); // Edit logic
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _confirmDelete(); // Delete logic
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text("Delete"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
