import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoListProvider(),
      child: MaterialApp(
        title: 'Todo List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
        home: const TodoListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class Todo {
  String title;
  bool isCompleted;

  Todo({required this.title, this.isCompleted = false});
}

class TodoListProvider extends ChangeNotifier {
  List<Todo> _todos = [];

  List<Todo> get todos => _todos;

  TodoListProvider() {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todoStrings = prefs.getStringList('todos') ?? [];
    _todos = todoStrings.map((str) {
      final parts = str.split('||');
      return Todo(title: parts[0], isCompleted: parts[1] == 'true');
    }).toList();
    notifyListeners();
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todoStrings = _todos.map((todo) => '${todo.title}||${todo.isCompleted}').toList();
    await prefs.setStringList('todos', todoStrings);
  }

  void addTodo(String title) {
    _todos.add(Todo(title: title));
    _saveTodos();
    notifyListeners();
  }

  void toggleTodo(int index) {
    _todos[index].isCompleted = !_todos[index].isCompleted;
    _saveTodos();
    notifyListeners();
  }

  void deleteTodo(int index) {
    _todos.removeAt(index);
    _saveTodos();
    notifyListeners();
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Add a todo',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTodo(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _addTodo,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<TodoListProvider>(
                    builder: (context, provider, child) {
                      return ListView.builder(
                        itemCount: provider.todos.length,
                        itemBuilder: (context, index) {
                          final todo = provider.todos[index];
                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: todo.isCompleted,
                                onChanged: (_) => provider.toggleTodo(index),
                              ),
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => provider.deleteTodo(index),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addTodo() {
    final title = _textController.text.trim();
    if (title.isNotEmpty) {
      Provider.of<TodoListProvider>(context, listen: false).addTodo(title);
      _textController.clear();
    }
  }
}