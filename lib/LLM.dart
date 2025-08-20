import 'package:intl/intl.dart';
import 'package:kalender/kalender.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:calendo/event.dart';
import 'package:flutter/material.dart';
import 'package:calendo/cache_eventscontroller.dart';


class LLM
{
  final CachedEventsController eventsController;

  LLM({
    required this.eventsController
  });
  String _key = "";
  final url = Uri.parse('https://api.moonshot.cn/v1/chat/completions');
  final model = 'kimi-k2-0711-preview';
  
  void setKey(String key) {
    _key = key;
  }
  String getKey() {
    return _key;
  }
  
  String getHistoryEvents(){
    final events = eventsController.events;
    String res = "";
    int cnt = 1;
    for (var event in events) {
      res += "$cnt. 任务名称：${event.data?.title ?? '未知任务'}\n";
      res += "开始时间：${event.dateTimeRange.start}\n";
      res += "持续时间：${event.dateTimeRange.duration.inHours}小时\n";
      res += "--------------------\n";
      cnt++;
    }
    debugPrint("历史事件：\n$res");
    return res;
  }

  Future<CalendarEvent> getPlannedCalendarEvent(
    final String user_message
  ) async {

    String system_prompt = """
    你是月之暗面（Kimi）人工智能助手，你擅长根据用户的待办清单，综合当前的时间，为用户规划时间。
    现在的时间是${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}。
    你应当遵循以下规则：
    1. 任务的开始时间应当在当前时间之后。
    2. 任务应当放在工作时间中，尽量避免安排在晚上或凌晨。
    3. 合理衡量该任务的持续时间，通常为1-2小时。
    4. 下面是用户已经规划好的任务列表，请根据这些任务来规划新的任务时间。注意不要与现有任务冲突。

    ${getHistoryEvents()}

    请使用如下 JSON 格式输出你的回复：
    
    {
        "start": "任务开始的时间，示例：2024-05-16 14:00",
        "duration": "任务持续的时间，单位为小事，示例：1"，这里应为数字格式，而并非字符串,
        "content": "任务的名称，示例：完成报告"
    }

    注意，请将任务的开始时间放在 `start` 字段中，将任务持续的时间放在 `duration` 字段中，将任务的名称放在 `content` 字段中。
    """;

    String history = getHistoryEvents();

    // 3. 请求头和请求体
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_key',
    };
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': system_prompt},
        {'role': 'user', 'content': user_message}
      ],
      'max_tokens': 1024,
      'temperature': 0.6,
      'stream': false,
      'response_format': {"type": "json_object"}
    });

    // 4. 发送 POST 请求
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      // 5. 处理响应
      if (response.statusCode == 200) {
        // 使用 utf8.decode 来正确处理中文字符
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final contentJson = data['choices'][0]['message']['content'] as String;
        final content = jsonDecode(contentJson) as Map<String, dynamic>;

        debugPrint('响应内容: $content');
        debugPrint('Type of start: ${content['start'].runtimeType}');
        debugPrint('Type of duration: ${content['duration'].runtimeType}');
        debugPrint('Type of content: ${content['content'].runtimeType}');

        // --- 开始健壮性解析 ---

        // 1. 安全解析 duration (double, int, String)
        final rawDuration = content['duration'];
        double durationInHours = 1.0; // 默认值为1小时
        if (rawDuration is double) {
          durationInHours = rawDuration;
        } else if (rawDuration is int) {
          durationInHours = rawDuration.toDouble();
        } else if (rawDuration is String) {
          durationInHours = double.tryParse(rawDuration) ?? 1.0;
        }
        // 将小时转换为分钟的整数
        final durationInMinutes = (durationInHours * 60).round();

        // 2. 安全解析 start 时间
        DateTime startTime;
        try {
          startTime = DateTime.parse(content['start'] as String);
        } catch (e) {
          // 如果解析失败，则使用当前时间作为备用
          startTime = DateTime.now();
          
          debugPrint('解析开始时间失败，使用当前时间: $e');
        }

        return CalendarEvent(
          dateTimeRange: DateTimeRange(
            start: startTime,
            end: startTime.add(Duration(minutes: durationInMinutes)),
          ),
          data: Event(
            title: content['content'],
            color: Colors.orange.withOpacity(0.8),
          ),
        );
      } else {
        debugPrint('请求失败，状态码: ${response.statusCode}');
        debugPrint('响应内容: ${response.body}');
        throw Exception('Failed to get planned calendar event');
      }
    } catch (e) {
      debugPrint('发生异常: $e');
      throw Exception('Failed to get planned calendar event: $e');
    }

  }
}
