import 'package:flutter/material.dart';

class Event {
  final String title;
  final Color? color;

  Event({
    this.title = '',
    this.color = Colors.blue,
  });

  Event copyWith({String? title, Color? color}) {
    return Event(title: this.title, color: this.color);
  }

  // 从 Map (JSON 对象) 创建 Event 实例
  factory Event.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Event();
    }
    return Event(
      title: json['title'] as String,
      // 从整数值恢复 Color
      color: Color(json['color'] as int),
    );
  }

  // 将 Event 实例转换为 Map (JSON 对象)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      // 保存 Color 的整数值
      'color': color?.value,
    };
  }
}