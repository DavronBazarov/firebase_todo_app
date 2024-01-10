import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/model.dart';
import '../widgets/widgets.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> todos = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    loading = true;
    final response = await http.get(Uri.parse(
        'https://online-shopp-provider-default-rtdb.firebaseio.com/todos.json'));
    if (response.statusCode == 200) {
      log(response.body.toString());

      if (response.body.isNotEmpty) {
        Map<String, dynamic> todoData = json.decode(response.body);
        // Convert the map values to a list of todos
        List<Todo> fetchedTodos = todoData.entries
            .map((entry) => Todo.fromJson({
                  'id': entry.key, // Use the key as the ID
                  ...entry.value, // Include other properties
                }))
            .toList();
        setState(() {
          todos = fetchedTodos;
          loading = false;
        });
      } else {
        // If the response body is empty, set todos to an empty list
        setState(() {
          todos = [];
        });
      }
    } else {
      log(response.body.toString());
      throw Exception('Failed to load todos');
    }
  }

  Future<void> addTodo(String title) async {
    setState(() {
      loading = true;
    });
    final response = await http.post(
      Uri.parse(
          'https://online-shopp-provider-default-rtdb.firebaseio.com/todos.json'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': title,
        'completed': false,
      }),
    );

    if (response.statusCode == 200) {
      final id = (jsonDecode(response.body) as Map<String, dynamic>)['name'];
      Todo newTodo = Todo(id: id, title: title, completed: false);

      setState(() {
        todos.add(newTodo);
        loading = false;
      });
    } else {
      log(response.body.toString());
      throw Exception('Failed to add todo');
    }
  }

  Future<void> deleteTodo(String id) async {
    log(id.toString());
    setState(() {
      loading = true;
    });
    final response = await http.delete(
      Uri.parse(
          'https://online-shopp-provider-default-rtdb.firebaseio.com/todos/$id.json'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      log(response.body.toString());
      setState(() {
        todos.removeWhere((todo) => todo.id == id);

        loading = false;
      });
    } else {
      log(response.body.toString());
      throw Exception('Failed to delete todo');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    setState(() {
      loading = true;
    });
    final response = await http.put(
      Uri.parse(
          'https://online-shopp-provider-default-rtdb.firebaseio.com/todos/${todo.id}.json'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode == 200) {
      setState(() {
        // Updating the local copy with the updated todo from the server
        int index = todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          todos[index] = todo;
        }
        loading = false;
      });
    } else {
      log(response.body.toString());
      throw Exception('Failed to update todo');
    }
  }

  Future<void> toggleTodoCompletion(String id, bool completed) async {
    loading = true;
    final response = await http.patch(
      Uri.parse(
          'https://online-shopp-provider-default-rtdb.firebaseio.com/todos/$id.json'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'completed': completed,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        todos.firstWhere((todo) => todo.id == id).completed = completed;
        loading = false;
      });
    } else {
      throw Exception('Failed to toggle todo completion');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO List'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : todos.isNotEmpty
              ? ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Checkbox(
                          value: todos[index].completed,
                          onChanged: (bool? value) async {
                            if (value != null) {
                              await toggleTodoCompletion(
                                  todos[index].id, value);
                            }
                          },
                        ),
                        title: Text(todos[index].title),
                        subtitle: Text(
                            'Completed: ${todos[index].completed.toString()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                bool result = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      TodoEditDialog(todo: todos[index]),
                                );
                                if (result != null && result) {
                                  // If the user saves the changes in the dialog, update the todo
                                  updateTodo(todos[index]);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await deleteTodo(todos[index].id);
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          bool result = await showDialog(
                            context: context,
                            builder: (context) =>
                                TodoEditDialog(todo: todos[index]),
                          );
                          if (result != null && result) {
                            // If the user saves the changes in the dialog, update the todo
                            updateTodo(todos[index]);
                          }
                        },
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text("Todo mavjud emas"),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String newTodoTitle = await showDialog(
            context: context,
            builder: (context) => TodoInputDialog(),
          );

          if (newTodoTitle != null && newTodoTitle.isNotEmpty) {
            // If the user enters a non-empty title, add the todo
            addTodo(newTodoTitle);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

