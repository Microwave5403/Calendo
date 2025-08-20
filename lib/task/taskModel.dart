
class TaskModel {
  String content;
  bool isDone;
  int? duration;
  String id;

  TaskModel({
    this.content = '',
    this.isDone = false,
    this.duration,
  }) : id = DateTime.now().toString();

  // 从 Map (JSON 对象) 创建 TaskModel 实例
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      content: json['content'] as String,
      isDone: json['isDone'] as bool,
    );
  }

  // 将 TaskModel 实例转换为 Map (JSON 对象)
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isDone': isDone,
    };
  }
}

