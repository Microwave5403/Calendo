# Calendo - 智能日历与任务管理应用

Calendo 是一款使用 Flutter 构建的、面向桌面的智能日历与任务管理应用。它将传统的日历视图与待办事项列表（Todo List）相结合，并集成了 AI 大语言模型（LLM）能力，可以帮助用户自动规划和安排任务。

![Exmaple](docs/exmaple.png)

## ✨ 主要功能

*   **集成视图**: 用户可以在日历视图、任务列表视图以及将二者并排显示的混合视图之间自由切换。
*   **AI 智能日程安排**: 通过集成Kimi大语言模型（LLM），用户可以输入自然语言描述的任务（例如“明天下午写两个小时代码”），Calendo 会自动解析并将其创建为日历事件。
*   **任务管理**:
    *   支持添加、删除、修改和标记完成任务。
    *   通过右键菜单进行快捷操作。
    *   支持拖拽任务（功能已集成）。
*   **日历事件管理**:
    *   在日历上清晰地展示事件。
    *   点击事件可查看详情
*   **本地数据持久化**:
    *   支持将所有任务和日历事件保存到本地文件。
    *   支持从本地文件加载数据，方便数据迁移和备份。
    *   支持一键清空所有数据。
    *   数据文件："Documents\Calendo_data.json"

## 🛠️ 技术栈

*   **框架**: [Flutter](https://flutter.dev/)
*   **状态管理**: [Provider](https://pub.dev/packages/provider) - 用于管理任务列表的状态。
*   **日历组件**: [Kalender](https://pub.dev/packages/kalender) - 一个功能强大且高度可定制的日历视图库。
*   **网络请求**: [http](https://pub.dev/packages/http) - 用于与大语言模型（LLM）的 API 进行通信。
*   **文件路径**: [path_provider](https://pub.dev/packages/path_provider) - 用于获取应用文档目录以保存数据。

## 🚀 如何运行

### 1. 环境准备
确保您的本地已经安装并配置好了 Flutter SDK。

### 2. 克隆项目
```bash
git clone <your-repository-url>
cd calendo
```

### 3. 安装依赖
在项目根目录下运行：
```bash
flutter pub get
```

### 4. 配置 AI 模型
本应用需要一个兼容 OpenAI API 格式的大语言模型服务（例如 Kimi Moonshot AI）。
1.  运行应用。
2.  在主界面右上角，点击齿轮（⚙️）图标。
3.  在弹出的对话框中，输入您的 API Key。

### 5. 运行应用
```bash
flutter run
```

## 📁 项目结构

```
lib/
├── calender/
│   └── calWidget.dart      # 日历视图的主组件
├── l10n/                   # 国际化与本地化文件
├── task/
│   ├── taskModel.dart      # 任务数据模型
│   └── taskProvider.dart   # 任务状态管理 (Provider)
├── widgets/
│   ├── event_overlay_portal.dart # 事件浮层详情
│   └── taskWidget.dart     # 任务列表的主组件
├── LLM.dart                # 大语言模型 API 交互逻辑
├── cache.dart              # 应用数据加载与保存逻辑
├── cache_eventscontroller.dart # 日历事件控制器扩展
├── event.dart              # 日历事件的数据模型
└── main.dart               # 应用主入口和整体布局
```

## 📝 许可证

本项目仅供“庆园杯”参赛使用，请勿用于商业用途或随意传播。

---