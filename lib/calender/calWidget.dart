import 'dart:io';
import 'package:calendo/event.dart';
import 'package:calendo/task/taskModel.dart';
import 'package:flutter/material.dart';
import 'package:kalender/kalender.dart';
import 'package:calendo/widgets/event_overlay_portal.dart';


class CalWidget extends StatefulWidget {

  final DateTime now;

  final DefaultEventsController<Event> eventsController;

  final CalendarController<Event> calendarController;

  CalWidget({
    super.key,
    required this.now,
    required this.eventsController,
    required this.calendarController,
  });

  @override
  State<CalWidget> createState() => _CalWidgetState();
}

class _CalWidgetState extends State<CalWidget> {

  
  //tile 文字样式
  final TextStyle tileTextStyle = const TextStyle(
    fontSize: 14,
    fontFamily: 'PuHuiTi',
    color: Color.fromARGB(255, 0, 0, 0),
  );


  late final displayRange = DateTimeRange(start: widget.now.subtractDays(363), end: widget.now.addDays(365));

  //设置日历视图
  late final viewConfigurations = <ViewConfiguration>[
    MultiDayViewConfiguration.week(displayRange: displayRange, firstDayOfWeek: 1),
    MultiDayViewConfiguration.singleDay(displayRange: displayRange),
    MultiDayViewConfiguration.workWeek(displayRange: displayRange),
    MultiDayViewConfiguration.custom(numberOfDays: 3, displayRange: displayRange),
    MonthViewConfiguration.singleMonth(),
    MultiDayViewConfiguration.freeScroll(displayRange: displayRange, numberOfDays: 4, name: "Free Scroll (WIP)"),
  ];

    /// 设置初始viewConfigurations
  late ViewConfiguration viewConfiguration = viewConfigurations[0];

    // 添加状态变量
  TaskModel? _pendingExternalTask;
  bool _isExternalDragMode = false;

    @override
  Widget build(BuildContext context) {
    return DragTarget<TaskModel>(
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty || _isExternalDragMode;
        return Container(
          decoration: BoxDecoration(
            border: isHovering 
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, 
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  )
                : null,
            color: isHovering 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : null,
          ),
          child: CalendarView<Event>(
            eventsController: widget.eventsController,
            calendarController: widget.calendarController,
            viewConfiguration: viewConfiguration,
            //处理日历中用户的回调操作
            callbacks: CalendarCallbacks<Event>(
              onEventTapped: (event, renderBox) => EventOverlayPortal.createEventOverlay(context, event, renderBox),
              onEventCreate: (event)
              {
                debugPrint('onEventCreate 被调用，接收到的事件: ${event.data?.title}');
                return event;
              },
              onEventCreated: (event) 
              {
                widget.eventsController.addEvent(event);
              } 
              
            ),
            components: CalendarComponents<Event>(
              multiDayComponents: MultiDayComponents(),
              multiDayComponentStyles: MultiDayComponentStyles(),
              monthComponents: MonthComponents(),
              monthComponentStyles: MonthComponentStyles(),
              scheduleComponents: ScheduleComponents(),
              scheduleComponentStyles: const ScheduleComponentStyles(),
            ),
            header: Material(
              color: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              elevation: 2,
              child: Column(
                children: [
                  _calendarToolbar(),
                  CalendarHeader<Event>(multiDayTileComponents: tileComponents(body: false)),
                ],
              ),
            ),
            body: CalendarBody<Event>(
              
              multiDayTileComponents: tileComponents(),
              monthTileComponents: tileComponents(body: false),
              scheduleTileComponents: ScheduleTileComponents.defaultComponents(),
              multiDayBodyConfiguration: MultiDayBodyConfiguration(showMultiDayEvents: false),
              monthBodyConfiguration: MultiDayHeaderConfiguration(),
              scheduleBodyConfiguration: ScheduleBodyConfiguration(),
            ),
          ),
        );
      },
      onWillAccept: (data) {
        return data is TaskModel;
      },
      // 当拖拽悬停时
      onMove: (details) {
        // 可以在这里添加实时的位置反馈
        if (_pendingExternalTask != null) {
          // 可以显示一个跟随鼠标的提示
        }
      },
      onAccept: (details) {

        final TaskModel draggedTask = details;
        debugPrint('收到拖拽任务: ${draggedTask.content}');
        
        // 立即在当前时间创建事件，然后让用户拖拽调整
        late DateTime now = DateTime.now();
        // 创建在下一个整点时间的事件
        
        final tempEvent = CalendarEvent<Event>(
          dateTimeRange: DateTimeRange(
            start: now,
            end: now.add(const Duration(hours: 1)),
          ),
          data: Event(
            title: draggedTask.content,
            color: Colors.orange.withOpacity(0.8),
          ),
        );
        
        // 立即添加事件
        widget.eventsController.addEvent(tempEvent);
        debugPrint('测试事件已添加');
        // 显示指引
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('任务"${draggedTask.content}"已添加到 ${now.hour}:00\n您可以拖拽该事件到合适的时间')),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color.fromARGB(218, 50, 47, 53),
            padding: const EdgeInsets.all(16.0),
            behavior: SnackBarBehavior.floating,
            width: 300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      },
      // 当拖拽离开时
      onLeave: (data) {
        // 如果需要，可以在这里清理状态
      },
    );
  }


  Color get color => Theme.of(context).colorScheme.primaryContainer;
  BorderRadius get radius => BorderRadius.circular(8);

  TileComponents<Event> tileComponents({bool body = true}) {
    return TileComponents<Event>(
      tileBuilder: (event, tileRange) {
        return Card(
          margin: body ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 1),
          color: color,

          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(event.data?.title ?? "",
              style: tileTextStyle,
              ),
          ),
        );
      },
      //拖动时日历上显示的边框
      dropTargetTile: (event) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(80), width: 2),
          borderRadius: radius,
        ),
      ),
      feedbackTileBuilder: (event, dropTargetWidgetSize) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: dropTargetWidgetSize.width * 0.8,
        height: dropTargetWidgetSize.height,
        decoration: BoxDecoration(color: color.withAlpha(100), borderRadius: radius),
      ),
      tileWhenDraggingBuilder: (event) => Container(
        decoration: BoxDecoration(color: color.withAlpha(80), borderRadius: radius),
        //child: Text('tileWhenDraggingBuilder')
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
    );
  }

  Widget _calendarToolbar() {
    final calendarController = widget.calendarController;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: calendarController.visibleDateTimeRangeUtc,
                  builder: (context, value, child) {
                    final String month;
                    final int year;

                    if (viewConfiguration is MonthViewConfiguration) {
                      // 因为月视图返回的可见 DateTimeRange 不一定从月初开始，
                      // 如果第二周在同一个月内，则使用第二周的月份和年份
                      final secondWeek = value.start.addDays(7);
                      year = secondWeek.year;
                      month = secondWeek.monthNameLocalized();
                    } else {
                      year = value.start.year;
                      month = value.start.monthNameLocalized();
                    }
                    return FilledButton.tonal(
                      onPressed: () {},
                      style: FilledButton.styleFrom(minimumSize: const Size(160, kMinInteractiveDimension)),
                      child: Text('$month $year'),
                    );
                  },
                ),
              ],
            ),
          ),
          if (!Platform.isAndroid && !Platform.isIOS)
            IconButton.filledTonal(
              onPressed: () => calendarController.animateToPreviousPage(),
              icon: const Icon(Icons.chevron_left),
            ),
          if (!Platform.isAndroid && !Platform.isIOS)
            IconButton.filledTonal(
              onPressed: () => calendarController.animateToNextPage(),
              icon: const Icon(Icons.chevron_right),
            ),
          IconButton.filledTonal(
            onPressed: () => calendarController.animateToDate(DateTime.now()),
            icon: const Icon(Icons.today),
          ),
          SizedBox(
            width: 120,
            child: DropdownMenu(
              dropdownMenuEntries: viewConfigurations.map((e) => DropdownMenuEntry(value: e, label: e.name)).toList(),
              initialSelection: viewConfiguration,
              onSelected: (value) {
                if (value == null) return;
                setState(() => viewConfiguration = value);
              },
            ),
          ),
        ],
      ),
    );
  }

}

  