import 'package:flutter/material.dart';
import 'package:calendo/task/taskModel.dart';

class TaskProvider with ChangeNotifier {
  List<TaskModel> _tasks = [
    TaskModel(content: '', isDone: false),
  ];

  List<TaskModel> get tasks => _tasks;

  int findIndex(TaskModel task) {
    return _tasks.indexOf(task);
  }

  void addTask(TaskModel task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(TaskModel task) {
    _tasks.remove(task);
    notifyListeners();
  }

  //如果在界面中对task进行修改，在provider中同步
  void updateTask(String value, int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index].content = value;
      debugPrint("任务索引：$index 更新任务内容: ${_tasks[index].content}");
      notifyListeners();
    }
  }

  void toggle(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index].isDone = !_tasks[index].isDone;
      notifyListeners();
    }
    else
    {
      throw Exception("Task not found in the list");
    }
  }

  // 从统一缓存数据中加载任务
  Future<void> loadEvents(List<dynamic> taskData) async {
    try {
      _tasks.clear(); // 清空现有任务
      _tasks.addAll(
        taskData.map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
      );
      notifyListeners();
      debugPrint('任务已从统一缓存加载: ${_tasks.length} 条');
    } catch (e) {
      debugPrint("从统一缓存加载任务失败: $e");
    }
  }

  void insertTask(int index, TaskModel task) {
    if (index >= 0 && index <= _tasks.length) {
      _tasks.insert(index, task);
      notifyListeners();
    }
  }

  void clearTasks() {
    _tasks.clear();
    notifyListeners();
  }
}