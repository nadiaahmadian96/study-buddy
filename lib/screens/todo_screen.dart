import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  final TextEditingController _taskController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksData = prefs.getString('tasks');
    if (tasksData != null && tasksData.isNotEmpty) {
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(
          jsonDecode(tasksData).map((task) => Map<String, dynamic>.from(task)),
        );
        _filteredTasks = List.from(_tasks);
      });
    } else {
      setState(() {
        _tasks = [];
        _filteredTasks = [];
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks', jsonEncode(_tasks));
  }

  void _addTask(String priority, String category, DateTime dueDate) {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add({
          'title': _taskController.text,
          'isDone': false,
          'priority': priority,
          'category': category,
          'dueDate': dueDate.toIso8601String(),
        });
        _taskController.clear();
        _saveTasks();
        _filterTasks(_searchQuery, _selectedCategory);
      });
    }
  }

  void _editTask(int index) {
    _taskController.text = _tasks[index]['title'] ?? '';
    DateTime selectedDate = DateTime.parse(_tasks[index]['dueDate'] ?? DateTime.now().toIso8601String());
    String selectedPriority = _tasks[index]['priority'] ?? 'Medium';
    String selectedCategory = _tasks[index]['category'] ?? 'Work';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(hintText: 'Edit your task'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: ['High', 'Medium', 'Low'].map((priority) {
                    return ChoiceChip(
                      label: Text(priority),
                      selected: selectedPriority == priority,
                      onSelected: (isSelected) {
                        setDialogState(() {
                          selectedPriority = priority;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                  items: ['Work', 'Personal', 'School']
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date: '),
                    Text(
                      '${selectedDate.toLocal()}'.split(' ')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _tasks[index] = {
                      'title': _taskController.text,
                      'isDone': _tasks[index]['isDone'] ?? false,
                      'priority': selectedPriority,
                      'category': selectedCategory,
                      'dueDate': selectedDate.toIso8601String(),
                    };
                    _saveTasks();
                    _filterTasks(_searchQuery, _selectedCategory);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _saveTasks();
      _filterTasks(_searchQuery, _selectedCategory);
    });
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['isDone'] = !_tasks[index]['isDone'];
      _saveTasks();
      _filterTasks(_searchQuery, _selectedCategory);
    });
  }

  void _filterTasks(String query, String category) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = category;
      _filteredTasks = _tasks.where((task) {
        final matchesCategory = category == 'All' || task['category'] == category;
        final matchesSearchQuery = task['title'].toLowerCase().contains(query.toLowerCase());
        return matchesCategory && matchesSearchQuery;
      }).toList();
    });
  }

  void _showAddTaskDialog() {
    _taskController.clear();
    String selectedPriority = 'Medium';
    String selectedCategory = 'Work';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(hintText: 'Enter your task here'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: ['High', 'Medium', 'Low'].map((priority) {
                      return ChoiceChip(
                        label: Text(priority),
                        selected: selectedPriority == priority,
                        onSelected: (isSelected) {
                          setDialogState(() {
                            selectedPriority = priority;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: ['Work', 'Personal', 'School']
                        .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Due Date: '),
                      Text(
                        '${selectedDate.toLocal()}'.split(' ')[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addTask(selectedPriority, selectedCategory, selectedDate);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (query) => _filterTasks(query, _selectedCategory),
          decoration: InputDecoration(
            hintText: 'Search Tasks',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (value) {
              _filterTasks(_searchQuery, value!);
            },
            dropdownColor: isDarkTheme ? Colors.grey[800] : Colors.white,
            items: ['All', 'Work', 'Personal', 'School']
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
          ),
        ],
      ),
      body: _filteredTasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet. Tap the "+" button to add one.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(
                      task['title'] ?? '',
                      style: TextStyle(
                        decoration: (task['isDone'] ?? false) ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priority: ${task['priority'] ?? 'Medium'}'),
                        Text('Category: ${task['category'] ?? 'Work'}'),
                        Text(
                          'Due Date: ${DateTime.tryParse(task['dueDate'] ?? '')?.toLocal().toIso8601String().split('T')[0] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    leading: Checkbox(
                      value: task['isDone'] ?? false,
                      onChanged: (value) {
                        _toggleTask(index);
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editTask(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}