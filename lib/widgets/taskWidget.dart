import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import 'package:provider/provider.dart';
import 'package:calendo/task/taskProvider.dart';
import 'package:calendo/task/taskModel.dart';
import 'package:calendo/cache_eventscontroller.dart';
import 'package:calendo/LLM.dart';
import 'package:calendo/event.dart';

class TaskWidget extends StatelessWidget {

  final CachedEventsController eventsController;
  final LLM llm;

  const TaskWidget({
    super.key,
    required this.eventsController,
    required this.llm
  });

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<TaskProvider>();
    final taskList = provider.tasks;

    return Stack(
      children: [
        ListView.builder(
          key: ValueKey(taskList.hashCode),
          itemCount: taskList.length,
          itemBuilder: (context, index) {
            final task = taskList[index];
            return taskPiece(
              key: ValueKey(task.id),
              task: task,
              eventsController: eventsController,
              llm: llm,
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () {
                  final newTask = TaskModel(content: '', isDone: false);
                  provider.addTask(newTask);
                  debugPrint("添加新任务: ${newTask.content}");
                },
                mini: true,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ]
    );
  }
}

class taskPiece extends StatelessWidget {
  final TaskModel task;
  final CachedEventsController eventsController;
  final LLM llm;
  
  const taskPiece({
    super.key,
    required this.task,
    required this.eventsController,
    required this.llm
  });

  // 显示右键菜单
  void _showContextMenu(BuildContext context, Offset position) {
    final provider = context.read<TaskProvider>();
    final index = provider.tasks.indexOf(task);
    debugPrint("任务内容: ${task.content} 任务索引: $index");
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_above',
          height: 40,
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 8),
              Text('Add Above'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'add_below',
          height: 40,
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 8),
              Text('Add Below'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'schedule_task',
          height: 40,
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 8),
              Text('Auto Schedule Task'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        final index = provider.tasks.indexOf(task);
        if (index < 0) return; // 如果任务不存在则不执行任何操作

        debugPrint("任务内容: ${task.content} 任务索引: $index");
        switch (value) {
          case 'add_above':
            debugPrint("在上方添加索引 任务内容：${task.content} 任务索引: $index");
            provider.insertTask(index, TaskModel(content: '', isDone: false));
            break;
          case 'add_below':
            debugPrint("在下方添加索引 任务内容：${task.content} 任务索引: $index");
            provider.insertTask(index + 1, TaskModel(content: '', isDone: false));
            break;
          case 'schedule_task':
            // 显示加载提示
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('正在为 "${task.content}" 安排日程...')),
            );
            
            llm.getPlannedCalendarEvent(task.content).then((genericCalEvent) {
              // genericCalEvent 的类型是 CalendarEvent<Object?>

              // 1. 使用任务内容创建一个类型正确的 Event 对象
              final Event eventData = Event(title: task.content);

              // 2. 使用 LLM 返回的时间范围和我们新创建的 Event 对象，
              //    来构建一个类型为 CalendarEvent<Event> 的新事件。
              final CalendarEvent<Event> correctlyTypedEvent = CalendarEvent<Event>(
                dateTimeRange: genericCalEvent.dateTimeRange,
                data: eventData,
              );

              // 3. 将这个类型正确的事件添加到控制器
              eventsController.addEvent(correctlyTypedEvent);

              // 隐藏加载提示并显示成功消息
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日程已成功添加!')),
              );

            }).catchError((error) {
              // 错误处理
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('安排失败: $error'), backgroundColor: Colors.red),
              );
            });
            break;
          case 'delete':
            debugPrint("删除任务 任务内容：${task.content} 任务索引: $index");
            provider.removeTask(task);
            break;
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 右键点击事件
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          // 添加悬停效果
          color: Colors.transparent,
        ),
        child: Draggable<TaskModel>(
          data: task,
          onDragStarted: () {
            debugPrint('拖拽开始: ${task.content}');
          },
          onDragEnd: (details) {
            debugPrint('拖拽结束: wasAccepted=${details.wasAccepted}, velocity=${details.velocity}');
          },
          onDraggableCanceled: (velocity, offset) {
            debugPrint('拖拽取消: velocity=$velocity, offset=$offset');
          },
          feedback: Material(
            elevation: 4.0,
            child: Container(
              width: 250, // 给一个固定宽度
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(value: task.isDone, onChanged: null),
                  Expanded(child: Text(task.content, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          childWhenDragging: taskPiece_mini(task: task),
          child: taskPiece_mini(task: task),
        )
      ),
    );
  }
}

class taskPiece_mini extends StatelessWidget {
  const taskPiece_mini({
    super.key,
    required this.task,
  });

  final TaskModel task;

  @override
  Widget build(BuildContext context) {

    final index = context.read<TaskProvider>().tasks.indexOf(task);
    return Row(
      children: [
        Checkbox(
          value: task.isDone,
          onChanged: (_) {
            context.read<TaskProvider>().toggle(index);
          }
        ),
        Flexible(
          fit: FlexFit.loose,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600, // 减去按钮宽度和边距
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: TextFormField(
                key: ValueKey('tf_${task.id}'),
                maxLines: 1,
                initialValue: task.content,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(), 
                  labelText: 'Todo'
                ),
                onChanged: (value) 
                {
                  context.read<TaskProvider>().updateTask(value, index);
                },
                  
              ),
            ),
          ),
        )
      ],
    );
  }
}