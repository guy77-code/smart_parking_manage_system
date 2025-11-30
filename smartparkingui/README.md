# 智能停车系统 - Qt6 前端应用

基于 Qt6.8.0 开发的跨平台智能停车系统前端应用，支持 Linux 和 Windows 平台。

## 功能特性

### 用户功能
- 用户注册和登录（支持密码登录和验证码登录）
- 停车状态查看和管理（停车、离开）
- 车位预订（创建、查看、取消）
- 订单历史查看和支付
- 违规记录查看和罚款支付

### 管理员功能
- 系统管理员：停车场管理、违规分析、数据统计
- 停车场管理员：车位管理、使用率分析、报表生成

### 其他功能
- 车位可视化界面
- 模拟支付页面
- 实时数据更新

## 系统要求

### Linux
- Qt6.8.0 或更高版本
- CMake 3.21 或更高版本
- C++17 编译器（GCC 7+ 或 Clang 5+）
- Qt6 模块：
  - Qt6::Core
  - Qt6::Network
  - Qt6::Quick
  - Qt6::QuickControls2

### Windows
- Qt6.8.0 或更高版本
- CMake 3.21 或更高版本
- Visual Studio 2019 或更高版本（或 MinGW）
- Qt6 模块（同上）

## 构建步骤

### Linux

1. **安装 Qt6**
   ```bash
   # 使用包管理器安装（Ubuntu/Debian）
   sudo apt-get install qt6-base-dev qt6-declarative-dev qt6-quickcontrols2-dev

   # 或从 Qt 官网下载安装器
   ```

2. **配置环境变量**
   ```bash
   export Qt6_DIR=/path/to/qt6/lib/cmake/Qt6
   ```

3. **构建项目**
   ```bash
   cd smartparkingui
   mkdir build
   cd build
   cmake ..
   make
   ```

4. **运行**
   ```bash
   ./SmartParkingUI
   ```

### Windows

1. **安装 Qt6**
   - 从 [Qt 官网](https://www.qt.io/download) 下载并安装 Qt6.8.0
   - 确保安装时选择了以下组件：
     - Qt 6.8.0
     - Qt Quick
     - Qt Quick Controls 2

2. **配置环境变量**
   ```cmd
   set Qt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6
   ```

3. **使用 CMake GUI 或命令行构建**
   ```cmd
   cd smartparkingui
   mkdir build
   cd build
   cmake .. -G "Visual Studio 16 2019" -A x64
   cmake --build . --config Release
   ```

4. **运行**
   ```cmd
   Release\SmartParkingUI.exe
   ```

## 配置

### API 服务器地址

默认 API 服务器地址为 `http://127.0.0.1:8080`。

如需修改，可以在 `src/apiclient.cpp` 中修改 `m_baseUrl` 的默认值，或在运行时通过 QML 调用 `apiClient.setBaseUrl()` 方法。

## 项目结构

```
smartparkingui/
├── CMakeLists.txt          # CMake 构建配置
├── README.md               # 本文件
├── src/                    # C++ 源文件
│   ├── main.cpp           # 主程序入口
│   ├── apiclient.cpp      # API 客户端实现
│   ├── authmanager.cpp    # 认证管理器实现
│   ├── models/            # 数据模型实现
│   └── utils/             # 工具类实现
├── include/                # C++ 头文件
│   ├── apiclient.h
│   ├── authmanager.h
│   ├── models/            # 数据模型头文件
│   └── utils/             # 工具类头文件
├── ui/                     # QML 界面文件
│   ├── main.qml           # 主界面
│   ├── LoginPage.qml      # 登录页面
│   ├── UserMainPage.qml   # 用户主页面
│   ├── AdminMainPage.qml  # 管理员主页面
│   ├── BookingPage.qml    # 预订页面
│   ├── ParkingVisualizationPage.qml  # 车位可视化页面
│   ├── PaymentPage.qml    # 支付页面
│   ├── ViolationPage.qml  # 违规记录页面
│   ├── OrderHistoryPage.qml  # 订单历史页面
│   └── AdminDataPage.qml  # 管理员数据页面
└── resources/              # 资源文件
    └── resources.qrc      # Qt 资源文件
```

## 使用说明

### 用户登录
1. 启动应用后，进入登录页面
2. 选择"用户"或"管理员"登录模式
3. 输入手机号和密码（或验证码）进行登录
4. 新用户可点击"注册新用户"进行注册

### 停车操作
1. 登录后进入用户主页面
2. 在"停车状态"标签页查看当前停车状态
3. 点击"停车"按钮选择停车场并完成停车
4. 点击"离开"按钮完成出场并支付费用

### 预订车位
1. 在用户主页面点击"预订信息"标签页
2. 点击"新建预订"按钮
3. 选择停车场、车辆、时间等信息
4. 提交预订

### 查看订单和支付
1. 在"订单历史"标签页查看所有订单
2. 点击"支付"按钮完成待支付订单
3. 选择支付方式（支付宝/微信）并确认支付

### 管理员功能
- **系统管理员**：可管理所有停车场、查看违规分析、生成报表
- **停车场管理员**：可管理指定停车场的车位、查看使用率分析

## 开发说明

### API 客户端
`ApiClient` 类封装了所有后端 API 调用，使用 Qt Network 模块进行 HTTP 请求。

### 数据模型
所有数据模型类继承自 `QObject`，使用 Qt 属性系统，可在 QML 中直接使用。

### 认证管理
`AuthManager` 类管理用户认证状态，使用 QSettings 持久化存储 token。

## 故障排除

### 编译错误
- 确保已安装所有必需的 Qt6 模块
- 检查 CMake 版本是否符合要求
- 确保 C++ 编译器支持 C++17

### 运行时错误
- 确保后端服务器正在运行（默认地址：http://127.0.0.1:8080）
- 检查网络连接
- 查看控制台输出的错误信息

### 跨平台问题
- Linux 和 Windows 的路径分隔符不同，代码中已使用 Qt 的路径处理函数
- 确保 Qt6 安装路径正确配置

## 许可证

本项目为智能停车系统的一部分，请遵循项目整体许可证。

## 联系方式

如有问题或建议，请联系开发团队。

