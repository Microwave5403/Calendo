import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import 'package:calendo/event.dart';

class CachedEventsController extends DefaultEventsController<Event> {
  CachedEventsController() {
    // 控制器被创建时，自动加载事件
    // loadEvents();
  }


  // 从文件加载事件
  Future<void> loadEvents(List<dynamic> jsonList) async {
    try {
      final loadedEvents = jsonList.map((json) {
        // 反序列化 CalendarEvent
        var data;
        if (Event.fromJson(json['data']) == null) {
          data = Event();
        }
        else{
          data = Event.fromJson(json['data']);
        }
        return CalendarEvent<Event>(
          dateTimeRange: DateTimeRange(
            start: DateTime.parse(json['start']),
            end: DateTime.parse(json['end']),
          ),
          data: data,
        );
      }).toList();

      // 将加载的事件添加到控制器中
      addEvents(loadedEvents);
      debugPrint('日历事件已从本地加载: ${loadedEvents.length} 条');
    } catch (e) {
      debugPrint('加载日历事件失败: $e');
    }
  }

  // 重写会修改事件列表的方法，并在修改后自动保存
  @override
  int addEvent(CalendarEvent<Event> event) {
    //super.addEvent(event);
    final id = dateMap.addNewEvent(event);
    notifyListeners();
    return id;
  }

  @override
  List<int> addEvents(List<CalendarEvent<Event>> events) {
    final ids = events.map(dateMap.addNewEvent).toList();
    notifyListeners();
    return ids;
  }

  @override
  void removeEvent(CalendarEvent<Event> event) {
    super.removeEvent(event);
  }

  @override
  void updateEvent({
    required CalendarEvent<Event> event,
    required CalendarEvent<Event> updatedEvent,
  }) {
    super.updateEvent(event: event, updatedEvent: updatedEvent);
  }
}