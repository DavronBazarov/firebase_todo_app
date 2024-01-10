import 'package:flutter/material.dart';

import '../model/model.dart';

class TodoInputDialog extends StatelessWidget {
  const TodoInputDialog({super.key});

  @override
  Widget build(BuildContext context) {
    String newTodoTitle = "";

    return AlertDialog(
      title: Text("Add Todo"),
      content: TextField(
        onChanged: (value) {
          newTodoTitle = value;
        },
        decoration: InputDecoration(labelText: "Todo Title"),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(newTodoTitle);
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class TodoEditDialog extends StatefulWidget {
  final Todo todo;

  TodoEditDialog({required this.todo});

  @override
  _TodoEditDialogState createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Todo"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: "Todo Title"),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            widget.todo.title = _controller.text;
            Navigator.of(context).pop(true);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
