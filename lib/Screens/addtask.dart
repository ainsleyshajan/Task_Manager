import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(titleController, "Title"),
              const SizedBox(height: 16),
              _buildTextField(descriptionController, "Description"),
              const SizedBox(height: 16),
              _buildTextField(statusController, "Status"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deadline == null
                          ? "Select Deadline"
                          : "Deadline: ${deadline!.toLocal()}".split(' ')[0],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectDeadline,
                    child: const Text("Pick Date"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildButton("Submit Task", _submitTask),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        deadline = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    final String title = titleController.text.trim();
    final String descriptions = descriptionController.text.trim();
    final String status = statusController.text.trim();

    if (title.isEmpty ||
        descriptions.isEmpty ||
        status.isEmpty ||
        deadline == null) {
      _showDialog("Validation Error", "Please fill all fields");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) {
      _showDialog("Error", "User not logged in");
      return;
    }

    final url = Uri.parse(
      'https://localhost:7035/api/Task/Create?userid=$userId&title=$title&descriptions=$descriptions&status=$status&deadline=$deadline',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'descriptions': descriptions,
        'status': status,
        'deadline': deadline!.toIso8601String(),
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showDialog("Success", "Task added successfully!");
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // go back
      });
    } else {
      _showDialog("Error", "Failed to add task: ${response.body}");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
