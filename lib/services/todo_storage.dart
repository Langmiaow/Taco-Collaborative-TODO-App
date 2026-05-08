import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TodoStorage {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/todoList.json");
  }

  static Future<Map<String, dynamic>> readTodoList() async {
    final file = await _file();

    if (!await file.exists()) {
      return {"todos": []};
    }

    try {
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return {"todos": []};
      }

      final data = jsonDecode(content);

      if (data is Map<String, dynamic> && data["todos"] is List) {
        return data;
      }

      return {"todos": []};
    } catch (_) {
      return {"todos": []};
    }
  }

  static Future<void> writeAllTodos(List todos) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({"todos": todos}));
  }

  static Future<void> addTodo(
    String content,
    String remark,
    DateTime? ddl,
    bool isDone,
  ) async {
    final data = await readTodoList();
    final List todos = List.from(data["todos"] ?? []);

    todos.add({
      "content": content,
      "remark": remark,
      "ddl": ddl?.millisecondsSinceEpoch,
      "isDone": isDone,
    });

    await writeAllTodos(todos);
  }

  static Future<void> setDone(int index, bool done) async {
    final data = await readTodoList();
    final List todos = List.from(data["todos"] ?? []);

    if (index < 0 || index >= todos.length) return;

    final Map t = Map<String, dynamic>.from(todos[index] as Map);
    t["isDone"] = done;

    if (done) {
      t["doneAt"] = DateTime.now().millisecondsSinceEpoch;
    } else {
      t["doneAt"] = null;
    }

    todos[index] = t;

    await writeAllTodos(todos);
  }

  static Future<void> deleteIndexes(Set<int> indexes) async {
    final data = await readTodoList();
    final List todos = List.from(data["todos"] ?? []);

    final sorted = indexes.toList()..sort((a, b) => b.compareTo(a));

    for (final i in sorted) {
      if (i >= 0 && i < todos.length) {
        todos.removeAt(i);
      }
    }

    await writeAllTodos(todos);
  }
}
