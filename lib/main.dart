import 'package:intl/date_symbol_data_local.dart';
import 'package:calendo/widgets/taskWidget.dart';
import 'package:flutter/material.dart';
import 'package:calendo/task/taskProvider.dart';
import 'package:provider/provider.dart';
import 'package:kalender/kalender.dart';
import 'package:calendo/calender/calWidget.dart';
import 'package:calendo/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:calendo/event.dart';
import 'package:calendo/widgets/event_overlay_portal.dart';
import 'package:calendo/cache_eventscontroller.dart';
import 'package:calendo/cache.dart';
import 'package:calendo/LLM.dart';

void main() async{
  // debugPaintSizeEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  // 只加载中文
  await initializeDateFormatting('zh_CN',null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendo',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // 英文
        Locale('zh'), // 中文
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        iconTheme: const IconThemeData(),
        //fontFamily: 'PuHuiTi',
        fontFamilyFallback: ['PuHuiTi'],
      ),
      home: const MyHomePage(title: 'Calendo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  final MenuController _controller = MenuController();

  late CachedEventsController eventsController;
  late CalendarController<Event> calendarController;
  late AppDataCache appCache;
  late LLM llm;

  @override
  void initState() {
    super.initState();
    eventsController = CachedEventsController();
    calendarController = CalendarController<Event>();
    llm = LLM(
      eventsController: eventsController,
    );
    

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 从 Provider 获取 TaskProvider
      final taskProvider = context.read<TaskProvider>();
      
      // 创建 AppDataCache 实例
      appCache = AppDataCache(
        eventsController: eventsController,
        taskProvider: taskProvider,
      );
      
      // 加载数据
      appCache.loadAllData();
      // 设置数据变化时的保存回调
    });
  }

  @override
  Widget build(BuildContext context) {
      Widget page = CalAndTaskPage(
        eventsController: eventsController,
        calendarController: calendarController,
        llm: llm,
      );
      switch(selectedIndex)
      {
        case 0:
          page = CalAndTaskPage(
            eventsController: eventsController,
            calendarController: calendarController,
            llm: llm,
          );
          break;
        case 1:
          page = const AboutPage();
          break;
        default:
          throw UnimplementedError("no widget for $selectedIndex");


      }

    return LayoutBuilder(
      builder :(context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text("主界面"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.info),
                    label: Text("关于"),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                trailing: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // SizedBox(height: 1,),
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: MenuAnchor(
                          
                          alignmentOffset: Offset(0.0, 1.0),
                          controller: _controller,
                          menuChildren: [
                            SizedBox(
                              height: 50,
                              width: 150,
                              child: MenuItemButton(
                                leadingIcon: Padding(
                                  padding: const EdgeInsets.only(left: 7.0),
                                  child: Icon(Icons.save),
                                ),
                                onPressed: () async {
                                  bool res = await appCache.saveAllData();
                                  String msg = "Data saved successfully to\nMy Documents";
                                  if (!res) msg = "Failed to save data to My Documents";
                                  // ignore: use_build_context_synchronously
                                  notifyUser(context, msg);
                                },
                                
                                child: const Text('Save')
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 150,
                              child: MenuItemButton(
                                leadingIcon: Padding(
                                  padding: const EdgeInsets.only(left: 7.0),
                                  child: Icon(Icons.file_open),
                                ),
                                onPressed: () async {
                                  bool res = await appCache.loadAllData();
                                  String msg = "Data loaded successfully from  My Documents";
                                  if (!res) msg = "Failed to load data from My Documents";
                                  notifyUser(context, msg);
                                },
                                child: const Text('Load')
                              ),
                            ),
                            SizedBox(
                              height: 50,
                              width: 150,
                              child: MenuItemButton(
                                leadingIcon: Padding(
                                  padding: const EdgeInsets.only(left: 7.0),
                                  child: Icon(Icons.delete),
                                ),
                                onPressed: () {
                                  appCache.clear();
                                  notifyUser(context, 'Data cleared successfully');
                                },
                                child: const Text('Clear'),
                              ),
                            )
                          ],
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 45,
                              width: 60,
                              child: FloatingActionButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                
                                // backgroundColor: Color.fromARGB(255, 254, 247, 255),
                                onPressed: () => _controller.open(), // 打开菜单
                                mini: true,
                                elevation: 5,
                                child: const Icon(Icons.menu),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 23,),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                thickness: 1,
                width: 20,
              ),
              SizedBox(width: 5,),
              Expanded(
                child: page)
            ],
          ),
        );
        
      },






    );

  }
  void notifyUser(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
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
  }
}

class CalAndTaskPage extends StatefulWidget
{

  // 创建 [EventsController], 用于管理日历事件
  final CachedEventsController eventsController;

  // 创建 [CalendarController],
  final CalendarController<Event> calendarController;
  
  final LLM llm;

  const CalAndTaskPage({
    super.key,
    required this.eventsController,
    required this.calendarController,
    required this.llm,
  });

  @override
  State<CalAndTaskPage> createState() => _CalAndTaskPageState();

}
//定义视图类型
enum ShowStyles { cal, both, task }

class _CalAndTaskPageState extends State<CalAndTaskPage> {


  late final now = DateTime.now();

  ShowStyles selected = ShowStyles.cal;

  Widget page = Placeholder();

  @override
  void initState(){
    super.initState();
  }

  //在这里可以添加switch切换不同的视图
  @override
  Widget build(BuildContext context) {
    
    switch(selected)
  {
    case ShowStyles.cal:
      page = EventOverlayPortal(
        eventsController: widget.eventsController,
        child: CalWidget(
          now: now,
          eventsController: widget.eventsController,
          calendarController: widget.calendarController,
        )
      );
      break;
    case ShowStyles.both:
      page = Row(
        children: [
          Expanded(
            child: EventOverlayPortal(
              eventsController: widget.eventsController,
              child: CalWidget(
                now: now,
                eventsController: widget.eventsController,
                calendarController: widget.calendarController,
              )
            )
          ),
          const VerticalDivider(width: 1),
          Expanded(child: TaskWidget(
            eventsController: widget.eventsController,
            llm: widget.llm
          )),
        ],
      );
      // page = Placeholder();
      break;
    case ShowStyles.task:
      page = Row(
        children: [
          SizedBox(
            height: 10,
          ),
          Expanded(child: TaskWidget(
            eventsController: widget.eventsController,
            llm: widget.llm
          )),
        ],
      );
      break;
  }
    
    return Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SafeArea(
                child: SegmentedButton<ShowStyles>(
                  segments: [
                    ButtonSegment(
                      value: ShowStyles.cal,
                      label: Text("Cal"),
                    ),
                    ButtonSegment(
                      value: ShowStyles.both,
                     label: Text("Both"),
                    ),
                    ButtonSegment(
                      value: ShowStyles.task,
                      label: Text("Task"),
                    ),
                  ],
                  selected: <ShowStyles>{selected},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selected = newSelection.first;
                    });
                  },
                )
              ),
              Row(
                children: [
                  SafeArea(
                    child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(21.0),
                    ),
                    child: const Icon(Icons.settings),
                    onPressed: () {
                          //设置API key
                          showDialog(
                            context: context,
                            builder: (context) => LLMPage(llm: widget.llm),
                          );
                        },
                      ),
                    ),
                  SizedBox(
                    width: 12,
                  ),
                ]
              ),
              
            ]
          ),
          //这里开始是主界面
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: page,
            ),
          ),
        ]
      )
    ;
  }
}

class LLMPage extends StatelessWidget {
  final LLM llm;

  const LLMPage({
    super.key,
    required this.llm
  });
  
  
  
  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    controller.text = llm.getKey();
    debugPrint("LLM key: ${llm.getKey()}");

    return AlertDialog(
      title: const Text('Set API Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 这里可以添加设置API Key的逻辑
            llm.setKey(controller.text);
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FlutterLogo(size: 100),
          const SizedBox(height: 20),
          const Text(
            'Calendo',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '@Microwave5403',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            '仅供庆园杯参赛使用，请勿传播',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Calendo',
                applicationIcon: const FlutterLogo(),
                children: const [
                  Text('Version 0.1.0-beta.1'),
                  SizedBox(height: 10),
                  Text('感谢使用 Calendo！'),
                  SizedBox(height: 10),
                ],
              );
            },
            child: const Text('查看详细信息'),
          ),
        ],
      ),
    );
  }
}