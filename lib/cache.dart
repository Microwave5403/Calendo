import 'dart:convert';
import 'dart:io';
import 'package:calendo/event.dart';
import 'package:calendo/task/taskModel.dart';
import 'package:flutter/foundation.dart';
import 'package:kalender/kalender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:calendo/task/taskProvider.dart';
import 'package:calendo/cache_eventscontroller.dart';

class AppDataCache {

  CachedEventsController eventsController = CachedEventsController();
  TaskProvider taskProvider = TaskProvider();

  AppDataCache({
    required this.eventsController,
    required this.taskProvider,
  }) {
    // 初始化时加载所有数据
  }

  // 获取缓存文件
  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/Calendo_data.json');
  }

  // 加载所有数据
  Future<bool> loadAllData() async {
    bool res = true;
    Map<String, dynamic> data = {'tasks': [], 'events': []};
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          data = jsonDecode(contents) as Map<String, dynamic>;
        }
      }
      else{res = false;}
    } catch (e) {
      debugPrint('加载统一缓存失败: $e');
      res = false;
    }

    //event
    List<dynamic> event_jsonList = data['events'] as List<dynamic>;
    //task
    List<dynamic> task_jsonList = data['tasks'] as List<dynamic>;

    // 将加载的事件添加到控制器中
    eventsController.loadEvents(event_jsonList);
    taskProvider.loadEvents(task_jsonList);

    return res;
  }

  // 保存所有数据
  Future<bool> saveAllData() async {
    bool res = true;
    List<TaskModel> tasks = taskProvider.tasks;
    List<CalendarEvent<Event>> events = eventsController.events.toList();
    try {
      final file = await _getCacheFile();
      final Map<String, dynamic> data = {
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'events': events.map((calEvent) {
          return {
            'start': calEvent.dateTimeRange.start.toIso8601String(),
            'end': calEvent.dateTimeRange.end.toIso8601String(),
            'data': calEvent.data?.toJson(),
          };
        }).toList(),
      };
      await file.writeAsString(jsonEncode(data));
      debugPrint('统一缓存已保存');
    } catch (e) {
      res = false;
      debugPrint('保存统一缓存失败: $e');
    }
    return res;
  }

  Future<void> clear() async {
    eventsController.clearEvents();
    taskProvider.clearTasks();
  }

  
}