import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Color _selectedColor = Colors.white;
  List<String> _categories = ['All', 'Uncategorized'];

  final List<Color> _availableColors = [
    Colors.red,
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.yellow,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadCategories();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesData = prefs.getString('notes');
    if (notesData != null) {
      setState(() {
        _notes = List<Map<String, dynamic>>.from(
            jsonDecode(notesData).map((note) => Map<String, dynamic>.from(note)));
        _filterNotes(_searchQuery, _selectedCategory);
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notes', jsonEncode(_notes));
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? categoriesData = prefs.getStringList('categories');
    if (categoriesData != null) {
      setState(() {
        _categories = categoriesData;
      });
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('categories', _categories);
  }

  void _addNote() {
    if (_noteController.text.isNotEmpty) {
      setState(() {
        _notes.add({
          'text': _noteController.text,
          'color': _selectedColor.value,
          'category': _selectedCategory == 'All' ? 'Uncategorized' : _selectedCategory,
        });
        _noteController.clear();
        _saveNotes();
        _filterNotes(_searchQuery, _selectedCategory);
      });
    }
  }

  void _editNote(int index) {
    final noteIndex = _notes.indexOf(_filteredNotes[index]);
    _noteController.text = _filteredNotes[index]['text'];
    _selectedColor = Color(_filteredNotes[index]['color']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'Edit your note here'),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 14,
                        child: _selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                _notes[noteIndex]['text'] = _noteController.text;
                _notes[noteIndex]['color'] = _selectedColor.value;
                _saveNotes();
                _filterNotes(_searchQuery, _selectedCategory);
              });
              _noteController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      final noteIndex = _notes.indexOf(_filteredNotes[index]);
      _notes.removeAt(noteIndex);
      _saveNotes();
      _filterNotes(_searchQuery, _selectedCategory);
    });
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty &&
        !_categories.contains(_categoryController.text)) {
      setState(() {
        _categories.add(_categoryController.text);
        _categoryController.clear();
        _saveCategories();
      });
    }
  }

  void _showAddNoteDialog() {
    _noteController.clear();
    _selectedColor = Colors.white;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'Enter your note here'),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 14,
                        child: _selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
              _addNote();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _filterNotes(String query, String category) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = category;
      _filteredNotes = _notes.where((note) {
        final matchesCategory =
            category == 'All' || note['category'] == category;
        final matchesSearchQuery =
            note['text'].toLowerCase().contains(query.toLowerCase());
        return matchesCategory && matchesSearchQuery;
      }).toList();
    });
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(hintText: 'Enter category name'),
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
              _addCategory();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[200]
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            onChanged: (query) => _filterNotes(query, _selectedCategory),
            decoration: const InputDecoration(
              hintText: 'Search Notes',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(10.0),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (value) {
              if (value != null) _filterNotes(_searchQuery, value);
            },
            items: _categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _filteredNotes.isEmpty
          ? const Center(
              child: Text(
                'No notes yet. Tap the "+" button to add one.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return Card(
                  color: Color(note['color']),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(note['text']),
                    subtitle: Text(note['category']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editNote(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteNote(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}