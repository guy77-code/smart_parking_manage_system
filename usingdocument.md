# 智能停车系统使用文档

## 目录
1. [环境配置](#环境配置)
2. [IP地址和端口配置](#ip地址和端口配置)
3. [软件功能使用说明](#软件功能使用说明)
   - [用户功能](#用户功能)
   - [管理员功能](#管理员功能)

---

## 环境配置

### 后端环境要求

#### 1. Go 环境
- **版本要求**：Go 1.24.0 或更高版本
- **Linux 安装方法**：
  ```bash
  # 下载并安装 Go
  wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  ```
- **Windows 安装方法**：
  1. 访问 Go 官网下载页面：https://go.dev/dl/
  2. 下载 Windows 安装包（如：`go1.24.0.windows-amd64.msi`）
  3. 双击运行安装程序，按照向导完成安装
  4. 默认安装路径：`C:\Program Files\Go`
  5. 安装完成后，打开命令提示符（CMD）或 PowerShell，验证安装：
     ```cmd
     go version
     ```
  6. 如果提示找不到命令，需要手动添加环境变量：
     - 右键"此电脑" → "属性" → "高级系统设置" → "环境变量"
     - 在"系统变量"中找到 `Path`，点击"编辑"
     - 添加：`C:\Program Files\Go\bin`
     - 点击"确定"保存
  7. 重新打开命令提示符，再次验证安装

#### 2. MySQL 数据库
- **版本要求**：MySQL 5.7 或更高版本（推荐 MySQL 8.0+）
- **Linux 安装方法**：
  ```bash
  # Ubuntu/Debian
  sudo apt-get update
  sudo apt-get install mysql-server
  
  # 启动 MySQL 服务
  sudo systemctl start mysql
  sudo systemctl enable mysql
  ```
- **Windows 安装方法**：
  1. 访问 MySQL 官网下载页面：https://dev.mysql.com/downloads/installer/
  2. 下载 MySQL Installer for Windows（推荐下载完整版）
  3. 运行安装程序，选择"Developer Default"或"Server only"
  4. 按照向导完成安装，记住设置的 root 密码
  5. 安装完成后，MySQL 服务会自动启动
  6. 可以通过"服务"管理器（services.msc）查看和管理 MySQL 服务
  7. 使用 MySQL Command Line Client 或 MySQL Workbench 连接数据库
- **数据库配置**：
  - 创建数据库：`CREATE DATABASE smart_parking CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
  - 创建用户并授权（或使用 root 用户）
  - 修改配置文件 `smart_parking_backend/config/config.yaml` 中的数据库连接信息
  **数据库建表和插入数据**：
  - 建表：buildSQL.md
  - 插入：SQLdata.md
  - 生成和插入更多测试数据：运行smart_parking_backend/generate_test_data.sh即可(或许需要些许改动)。

#### 3. Redis
- **版本要求**：Redis 5.0 或更高版本
- **Linux 安装方法**：
  ```bash
  # Ubuntu/Debian
  sudo apt-get install redis-server
  
  # 启动 Redis 服务
  sudo systemctl start redis-server
  sudo systemctl enable redis-server
  ```
- **Windows 安装方法**：
  1. **方法一：使用 WSL（推荐）**
     - 安装 Windows Subsystem for Linux (WSL)
     - 在 WSL 中安装 Redis（参考 Linux 安装方法）
  
  2. **方法二：使用 Memurai（Windows 原生 Redis）**
     - 访问 Memurai 官网：https://www.memurai.com/
     - 下载并安装 Memurai（Redis 的 Windows 版本）
     - 安装后会自动作为 Windows 服务运行
  
  3. **方法三：使用 Docker**
     - 安装 Docker Desktop for Windows
     - 运行 Redis 容器：
       ```cmd
       docker run -d -p 6379:6379 --name redis redis:latest
       ```
  
  4. **验证 Redis 运行**：
     - 打开命令提示符，测试连接：
       ```cmd
       redis-cli ping
       ```
     - 如果使用 Docker，需要先进入容器：
       ```cmd
       docker exec -it redis redis-cli ping
       ```
- **配置**：修改 `smart_parking_backend/config/config.yaml` 中的 Redis 连接信息

#### 4. 后端依赖安装
```bash
cd smart_parking_backend
go mod download
```

### 前端环境要求

#### 1. Qt6
- **版本要求**：Qt 6.8.0 或更高版本

**Linux 安装方法**：
  ```bash
  # Ubuntu/Debian
  sudo apt-get install qt6-base-dev qt6-declarative-dev qt6-quickcontrols2-dev
  
  # 或从 Qt 官网下载安装器
  # https://www.qt.io/download
  ```

**Windows 安装方法**：
1. **下载 Qt 安装器**：
   - 访问 Qt 官网：https://www.qt.io/download
   - 点击"Download Qt"按钮
   - 选择"Open Source"（开源版本）或"Commercial"（商业版本）
   - 下载 Qt Online Installer for Windows（推荐）或 Offline Installer

2. **运行安装器**：
   - 双击下载的安装程序（如：`qt-unified-windows-x64-online.exe`）
   - 如果提示需要登录，可以创建免费的 Qt 账号（开源版本）
   - 按照安装向导进行安装

3. **选择安装路径和组件**：
   - **安装路径**：建议使用默认路径 `C:\Qt`，或选择其他路径（记住此路径，后续需要配置）
   - **选择 Qt 版本**：选择 Qt 6.8.0 或更高版本
   - **选择编译器**：
     - **Visual Studio 2019/2022**：如果已安装 Visual Studio，选择对应的版本（如 MSVC 2019 64-bit）
     - **MinGW**：如果没有 Visual Studio，选择 MinGW 版本
   - **必选组件**：
     - ✅ Qt 6.8.0（或更高版本）
     - ✅ Qt Quick
     - ✅ Qt Quick Controls 2
     - ✅ Qt Network
     - ✅ CMake（如果系统未安装）
   - **可选组件**：
     - Qt Creator（IDE，推荐安装，方便开发）
     - Qt Debug Information Files（调试信息，推荐安装）

4. **完成安装**：
   - 点击"安装"按钮，等待安装完成（可能需要较长时间，取决于网络速度）
   - 安装完成后，点击"完成"

5. **验证安装**：
   - 打开命令提示符（CMD）或 PowerShell
   - 运行以下命令验证 Qt 安装：
     ```cmd
     qmake --version
     ```
   - 如果提示找不到命令，需要手动添加到环境变量（见下方配置环境变量部分）

#### 2. CMake
- **版本要求**：CMake 3.21 或更高版本

**Linux 安装方法**：
  ```bash
  # Ubuntu/Debian
  sudo apt-get install cmake
  ```

**Windows 安装方法**：
1. **下载 CMake**：
   - 访问 CMake 官网：https://cmake.org/download/
   - 下载 Windows x64 Installer（如：`cmake-3.28.0-windows-x86_64.msi`）
   - 选择"Latest Release"版本

2. **运行安装程序**：
   - 双击下载的 `.msi` 文件
   - 按照安装向导进行安装
   - **重要**：在"选择组件"页面，勾选：
     - ✅ "Add CMake to the system PATH for all users"（推荐）
     - ✅ "Add CMake to the system PATH for current user"（如果无法选择所有用户）
   - 选择安装路径（建议使用默认路径）

3. **完成安装**：
   - 点击"安装"，等待安装完成
   - 点击"完成"

4. **验证安装**：
   - 打开新的命令提示符（需要重新打开以加载环境变量）
   - 运行以下命令验证：
     ```cmd
     cmake --version
     ```
   - 应该显示 CMake 版本信息（如：cmake version 3.28.0）

#### 3. C++ 编译器

**Linux**：GCC 7+ 或 Clang 5+

**Windows**：Visual Studio 2019+ 或 MinGW

**Windows 安装方法**：

**方法一：使用 Visual Studio（推荐）**
1. **下载 Visual Studio**：
   - 访问 Visual Studio 官网：https://visualstudio.microsoft.com/
   - 下载 Visual Studio Community（免费版本）

2. **安装 Visual Studio**：
   - 运行安装程序
   - 在"工作负载"页面，选择：
     - ✅ "使用 C++ 的桌面开发"
   - 在"单个组件"页面，确保包含：
     - ✅ MSVC v142 或更高版本的 C++ 生成工具
     - ✅ Windows 10/11 SDK（最新版本）
     - ✅ CMake 工具（可选，如果已单独安装 CMake）
   - 点击"安装"，等待安装完成

3. **验证安装**：
   - 打开"Developer Command Prompt for VS"（在开始菜单中搜索）
   - 运行：`cl`，应该显示编译器版本信息

**方法二：使用 MinGW（如果不想安装 Visual Studio）**
1. **下载 MinGW-w64**：
   - 访问：https://www.mingw-w64.org/downloads/
   - 或使用 MSYS2：https://www.msys2.org/
   - 推荐使用 MSYS2，因为它包含包管理器

2. **安装 MSYS2**：
   - 下载并运行 MSYS2 安装程序
   - 安装完成后，打开 MSYS2 终端
   - 运行以下命令安装 MinGW-w64：
     ```bash
     pacman -S mingw-w64-x86_64-gcc
     pacman -S mingw-w64-x86_64-cmake
     pacman -S mingw-w64-x86_64-ninja
     ```

3. **配置环境变量**：
   - 将 MinGW-w64 的 bin 目录添加到系统 PATH
   - 例如：`C:\msys64\mingw64\bin`

---

## IP地址和端口配置

### 后端配置

#### 方法一：修改代码（推荐用于开发环境）

1. **修改服务器端口**：
   - 打开文件：`smart_parking_backend/main.go`
   - 找到第 56 行：
     ```go
     port := ":8080"
     ```
   - 修改为您需要的端口，例如：
     ```go
     port := ":9090"  // 修改为 9090 端口
     ```

2. **修改配置文件**（可选）：
   - 打开文件：`smart_parking_backend/config/config.yaml`
   - 修改服务器端口：
     ```yaml
     server:
       port: 8080  # 修改为您需要的端口
     ```
   - 注意：当前代码中 `main.go` 直接使用硬编码的端口，配置文件中的端口设置可能不会生效，建议直接修改 `main.go`

3. **修改数据库和 Redis 连接地址**：
   - 打开文件：`smart_parking_backend/config/config.yaml`
   - 修改数据库连接：
     ```yaml
     database:
       host: "127.0.0.1"  # 修改为数据库服务器IP地址
       port: 3306         # 修改为数据库端口
       user: "root"       # 修改为数据库用户名
       password: "12345"  # 修改为数据库密码
       name: "smart_parking"  # 数据库名称
     ```
   - 修改 Redis 连接：
     ```yaml
     redis:
       addr: "127.0.0.1:6379"  # 修改为 Redis 服务器地址和端口
       password: "12345"       # 修改为 Redis 密码（如果没有密码可留空）
       db: 0
     ```

#### 方法二：使用环境变量（推荐用于生产环境）

后端代码支持通过环境变量配置，但当前版本主要使用配置文件方式。

### 前端配置

#### 修改 API 服务器地址

1. **修改默认 API 地址**：
   - 打开文件：`smartparkingui/src/apiclient.cpp`
   - 找到第 13 行：
     ```cpp
     m_baseUrl("http://127.0.0.1:8080")
     ```
   - 修改为您需要的后端服务器地址和端口，例如：
     ```cpp
     m_baseUrl("http://192.168.1.100:8080")  // 修改为实际的后端服务器地址
     ```

2. **运行时修改**（可选）：
   - 前端支持在运行时通过 QML 调用 `apiClient.setBaseUrl("http://新地址:端口")` 来修改 API 地址
   - 但需要修改 QML 代码来实现此功能

#### 注意事项

- 确保前端配置的 API 地址与后端实际运行的地址和端口一致
- 如果后端运行在不同机器上，需要确保防火墙允许相应端口的访问
- 修改配置后，需要重新编译和运行程序才能生效

---

## 软件功能使用说明

### 用户功能

#### 1. 用户注册

**使用步骤**：
1. 启动前端应用程序
2. 在登录页面点击"注册新用户"按钮
3. 填写注册信息：
   - **用户名**：3-50 个字符
   - **密码**：至少 6 个字符
   - **手机号**：必填
   - **邮箱**：可选
   - **真实姓名**：可选
4. 添加至少一辆车辆信息：
   - **车牌号**：必填，需唯一
   - **品牌**：可选
   - **车型**：可选
   - **颜色**：可选
5. 点击"提交注册"完成注册

**注意事项**：
- 注册时至少需要添加一辆车辆
- 车牌号在系统中必须唯一
- 密码会进行加密存储

#### 2. 用户登录

**使用步骤**：
1. 在登录页面选择"用户"登录模式
2. 输入手机号
3. 选择登录方式：
   - **密码登录**：输入注册时设置的密码
   - **验证码登录**：
     - 点击"获取验证码"按钮
     - 等待验证码发送（开发环境会在响应中显示验证码）
     - 输入收到的验证码
4. 点击"登录"按钮

**注意事项**：
- 验证码有效期为 5 分钟
- 60 秒内只能发送一次验证码
- 登录成功后会自动跳转到用户主页面

#### 3. 车辆管理

**查看车辆列表**：
- 登录后，在用户主页面可以查看已绑定的所有车辆

**添加车辆**：
1. 在车辆管理页面点击"添加车辆"按钮
2. 填写车辆信息（车牌号必填）
3. 点击"提交"完成添加

**删除车辆**：
1. 在车辆列表中找到要删除的车辆
2. 点击"删除"按钮
3. 确认删除操作

**注意事项**：
- 删除车辆会同时删除与该车辆相关的所有历史记录（预订、停车记录、违规记录等）
- 车牌号在系统中必须唯一

#### 4. 停车操作

**查看停车状态**：
1. 登录后进入用户主页面
2. 点击"停车状态"标签页
3. 查看当前是否有在场停车记录

**车辆入场**：
1. 在"停车状态"标签页点击"停车"按钮
2. 选择停车场
3. 选择车辆（车牌号）
4. 选择车位类型（普通、充电桩、残疾人、VIP 等）
5. 系统会自动检查是否有有效预订：
   - 如果有有效预订，会优先使用预订车位
   - 如果没有预订，系统会分配一个空闲车位
6. 点击"确认入场"完成停车

**车辆离场**：
1. 在"停车状态"标签页找到当前停车记录
2. 点击"离开"按钮
3. 系统会自动计算停车费用：
   - 根据停车时长和停车场费率计算停车费
   - 检查是否有违规记录，计算违规罚款
   - 总费用 = 停车费 + 违规罚款
4. 系统会生成支付链接，点击"支付"按钮进行支付
5. 支付完成后，车辆离场成功

**注意事项**：
- 如果有有效预订，车辆入场时会优先使用预订车位
- 预订允许提前 30 分钟入场
- 离场时会自动检查违规行为并计算罚款

#### 5. 车位预订

**创建预订**：
1. 在用户主页面点击"预订信息"标签页
2. 点击"新建预订"按钮
3. 填写预订信息：
   - **选择停车场**：从下拉列表中选择
   - **选择车辆**：选择要预订的车牌号
   - **开始时间**：选择预订开始时间
   - **结束时间**：选择预订结束时间（必须晚于开始时间）
   - **车位类型**：选择需要的车位类型（普通、充电桩等）
4. 点击"提交预订"完成创建

**查看预订列表**：
- 在"预订信息"标签页可以查看所有预订记录
- 预订状态包括：
  - **已预订**：预订已创建但未使用
  - **使用中**：车辆已入场
  - **已完成**：车辆已离场
  - **已取消**：预订已取消

**取消预订**：
1. 在预订列表中找到要取消的预订
2. 点击"取消预订"按钮
3. 确认取消操作

**注意事项**：
- 预订时间不能早于当前时间
- 预订允许提前 30 分钟入场
- 如果预订时间已过且未使用，系统会自动取消预订
- 预订创建后需要支付预订费用

#### 6. 订单历史与支付

**查看订单历史**：
1. 在用户主页面点击"订单历史"标签页
2. 查看所有订单记录，包括：
   - **预订订单**：车位预订订单
   - **停车订单**：停车费用订单
   - **违规订单**：违规罚款订单
3. 每个订单显示：
   - 订单类型
   - 订单金额
   - 支付状态
   - 订单详情（停车场、车辆、时间等）

**支付订单**：
1. 在订单列表中找到待支付的订单
2. 点击"支付"按钮
3. 选择支付方式（支付宝/微信）
4. 在支付页面完成支付
5. 支付成功后，订单状态会自动更新

**刷新订单列表**：
- 点击"刷新"按钮可以获取最新的订单状态

**注意事项**：
- 订单类型包括预订、停车、违规三种
- 支付完成后，订单状态会自动更新
- 可以查看订单的详细信息，包括停车时长、违规原因等

#### 7. 违规记录查询与支付

**查看违规记录**：
1. 在用户主页面点击"违规记录"标签页
2. 查看所有违规记录，包括：
   - **超时停车**：停车时间超过预订时间
   - **预订未使用**：预订了车位但未在预订时间内使用
   - **未支付停车费**：停车后未支付费用
3. 每条记录显示：
   - 违规类型
   - 违规时间
   - 罚款金额
   - 处理状态（未处理/已处理）

**支付罚款**：
1. 在违规记录列表中找到未处理的违规记录
2. 点击"支付罚款"按钮
3. 选择支付方式（支付宝/微信）
4. 在支付页面完成支付
5. 支付成功后，违规记录状态会自动更新为"已处理"

**刷新违规记录**：
- 点击"刷新"按钮可以获取最新的违规记录状态

**注意事项**：
- 违规记录需要及时处理，否则可能影响后续停车
- 支付完成后，违规状态会自动更新

#### 8. 车位可视化

**查看车位状态**：
1. 在用户主页面点击"车位可视化"按钮
2. 选择要查看的停车场
3. 查看停车场的车位分布和占用情况：
   - 不同颜色表示不同的车位状态
   - 可以查看每个车位的详细信息

**注意事项**：
- 车位可视化功能可以帮助用户快速了解停车场的使用情况
- 实时显示车位的占用和预订状态

---

### 管理员功能

#### 1. 管理员登录

**使用步骤**：
1. 在登录页面选择"管理员"登录模式
2. 输入管理员手机号和密码
3. 点击"登录"按钮

**管理员类型**：
- **系统管理员**：可以管理所有停车场，查看所有数据
- **停车场管理员**：只能管理指定停车场的数据

#### 2. 停车场管理

**添加停车场**：
1. 登录管理员账号后，进入管理员主页面
2. 点击"停车场管理"功能
3. 点击"添加停车场"按钮
4. 填写停车场信息：
   - **名称**：停车场名称
   - **地址**：详细地址
   - **总层数**：停车场的楼层数
   - **总车位数**：停车场的总车位数量
   - **小时费率**：每小时停车费用
   - **状态**：启用/禁用
   - **描述**：停车场说明
5. 点击"提交"完成添加

**查看停车场列表**：
- 在停车场管理页面可以查看所有停车场
- 显示停车场的基本信息和状态

**删除停车场**：
1. 在停车场列表中找到要删除的停车场
2. 点击"删除"按钮
3. 确认删除操作

**注意事项**：
- 系统管理员可以管理所有停车场
- 停车场管理员只能查看和管理自己负责的停车场
- 删除停车场会同时删除该停车场下的所有车位和相关记录

#### 3. 车位管理

**添加车位**：
1. 在管理员主页面点击"车位管理"功能
2. 选择要管理的停车场
3. 点击"添加车位"按钮
4. 填写车位信息：
   - **停车场**：选择所属停车场
   - **楼层**：车位所在楼层
   - **车位编号**：车位的编号（如 A-001）
   - **车位类型**：普通、充电桩、残疾人、VIP 等
   - **状态**：可用/禁用
5. 点击"提交"完成添加

**查看车位列表**：
- 在车位管理页面可以查看指定停车场下的所有车位
- 显示车位的基本信息、占用状态、预订状态等

**更新车位状态**：
1. 在车位列表中找到要更新的车位
2. 点击"编辑"或"更新状态"按钮
3. 可以修改：
   - **状态**：可用/禁用
   - **占用状态**：已占用/未占用
   - **预订状态**：已预订/未预订
4. 点击"保存"完成更新

**删除车位**：
1. 在车位列表中找到要删除的车位
2. 点击"删除"按钮
3. 确认删除操作

**注意事项**：
- 车位类型包括：普通、充电桩、残疾人、VIP 等
- 车位状态包括：可用（status=1）、禁用（status=0）
- 占用状态和预订状态由系统自动管理，管理员可以手动调整

#### 4. 数据统计分析

**车位使用率分析**：
1. 在管理员主页面点击"数据分析"功能
2. 选择"车位使用率分析"
3. 设置分析时间范围：
   - **开始时间**：选择分析的起始时间
   - **结束时间**：选择分析的结束时间
4. 点击"查询"按钮
5. 查看分析结果：
   - 总车位数和已占用车位数
   - 使用率百分比
   - 总收入、日均收入
   - 平均停车时长
   - 按车位类型分组的详细统计

**违规行为分析**：
1. 在数据分析页面选择"违规行为分析"
2. 选择分析时间：
   - **年份**：选择要分析的年份
   - **月份**：选择要分析的月份（可选）
3. 点击"查询"按钮
4. 查看分析结果：
   - 违规总数统计
   - 按违规类型分组统计（超时停车、预订未使用、未支付停车费）
   - 按处理状态分组统计（未处理、已处理）
   - 罚款总额和已收罚款
   - 月度趋势分析

**报表生成**：
1. 在数据分析页面选择"报表生成"
2. 选择报表类型：
   - **月度报表**：生成指定月份的详细报表
   - **年度报表**：生成指定年份的汇总报表
3. 选择时间：
   - 对于月度报表：选择年份和月份
   - 对于年度报表：选择年份
4. 点击"生成报表"按钮
5. 查看报表内容：
   - 停车统计信息
   - 违规统计信息
   - 收入统计信息
   - 使用率统计信息
   - 高峰时段分析

**注意事项**：
- 系统管理员可以查看所有停车场的数据
- 停车场管理员只能查看自己负责的停车场数据
- 分析结果以图表和表格形式展示，便于理解

#### 5. 管理员注册

**注册新管理员**：
1. 系统管理员可以通过后端 API 注册新的管理员账号
2. 注册时需要提供：
   - **手机号**：管理员登录账号
   - **密码**：6-20 个字符
   - **停车场ID**：可选，停车场管理员需要指定负责的停车场
   - **角色**：system（系统管理员）或 lot_admin（停车场管理员）

**注意事项**：
- 管理员注册功能通常由系统管理员或开发人员使用
- 普通用户无法通过前端界面注册管理员账号

---

## 启动和运行

### 后端启动

#### 1. 准备工作
- 确保 MySQL 和 Redis 服务已启动
- 确保数据库已创建并配置正确
- 检查配置文件 `smart_parking_backend/config/config.yaml` 中的连接信息

#### 2. 启动步骤
```bash
# 进入后端目录
cd smart_parking_backend

# 安装依赖（首次运行）
go mod download

# 编译并运行
go run main.go

# 或先编译再运行
go build -o smart_parking_server
./smart_parking_server
```

#### 3. 验证启动
- 查看控制台输出，确认服务器已成功启动
- 默认情况下，服务器运行在 `http://127.0.0.1:8080`
- 可以通过浏览器访问 `http://127.0.0.1:8080` 测试连接（如果后端有健康检查接口）

### 前端启动

#### 1. 准备工作
- 确保后端服务已启动
- 确保前端 API 地址配置正确（`smartparkingui/src/apiclient.cpp`）

#### 2. 编译步骤（Linux）
```bash
# 进入前端目录
cd smartparkingui

# 创建构建目录
mkdir -p build
cd build

# 使用 CMake 配置
cmake ..

# 编译
make

# 运行
./SmartParkingUI
```

#### 3. 编译步骤（Windows）

**准备工作**：
1. **配置环境变量**（如果 Qt 未自动添加到 PATH）：
   - 右键"此电脑" → "属性" → "高级系统设置" → "环境变量"
   - 在"系统变量"中找到 `Path`，点击"编辑"
   - 添加 Qt 的 bin 目录，例如：
     - `C:\Qt\6.8.0\msvc2019_64\bin`（Visual Studio 版本）
     - 或 `C:\Qt\6.8.0\mingw_64\bin`（MinGW 版本）
   - 点击"确定"保存
   - **重要**：需要重新打开命令提示符才能生效

2. **设置 Qt6_DIR 环境变量**（推荐方法）：
   - 在命令提示符中设置（临时，仅当前会话有效）：
     ```cmd
     set Qt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6
     ```
   - 或添加到系统环境变量（永久）：
     - 在"系统变量"中点击"新建"
     - 变量名：`Qt6_DIR`
     - 变量值：`C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6`（根据实际安装路径调整）
     - 点击"确定"保存

**使用 Visual Studio 编译**：
```cmd
# 1. 打开 "Developer Command Prompt for VS" 或 "x64 Native Tools Command Prompt for VS"
# （在开始菜单中搜索，选择对应 Visual Studio 版本的命令提示符）

# 2. 进入前端目录
cd C:\path\to\smartparkingproject\smartparkingui

# 3. 创建构建目录
mkdir build
cd build

# 4. 使用 CMake 配置（根据 Visual Studio 版本选择）
# Visual Studio 2019:
cmake .. -G "Visual Studio 16 2019" -A x64
# Visual Studio 2022:
cmake .. -G "Visual Studio 17 2022" -A x64

# 如果 CMake 找不到 Qt6，可以手动指定：
cmake .. -G "Visual Studio 16 2019" -A x64 -DQt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6

# 5. 编译（Release 版本）
cmake --build . --config Release

# 6. 运行
Release\SmartParkingUI.exe
```

**使用 MinGW 编译**：
```cmd
# 1. 打开 MSYS2 MinGW 64-bit 终端
# （在开始菜单中搜索 "MSYS2 MinGW 64-bit"）

# 2. 进入前端目录（注意：Windows 路径需要使用 /c/ 格式）
cd /c/path/to/smartparkingproject/smartparkingui

# 3. 创建构建目录
mkdir build
cd build

# 4. 使用 CMake 配置
cmake .. -G "MinGW Makefiles" -DQt6_DIR=C:/Qt/6.8.0/mingw_64/lib/cmake/Qt6

# 5. 编译
cmake --build . --config Release
# 或使用 make
mingw32-make

# 6. 运行
./SmartParkingUI.exe
```

**使用 Qt Creator（推荐，图形界面方式）**：
1. **打开 Qt Creator**：
   - 在开始菜单中找到并打开 Qt Creator

2. **打开项目**：
   - 点击"文件" → "打开文件或项目"
   - 导航到 `smartparkingui` 目录
   - 选择 `CMakeLists.txt` 文件
   - 点击"打开"

3. **配置项目**：
   - Qt Creator 会自动检测 CMake 和 Qt 版本
   - 如果检测不到 Qt，点击"配置项目"
   - 在"Qt 版本"中选择已安装的 Qt 6.8.0
   - 在"构建套件"中选择对应的编译器（MSVC 或 MinGW）

4. **构建项目**：
   - 点击左下角的"构建"按钮（锤子图标）
   - 或按快捷键 `Ctrl+B`
   - 等待编译完成

5. **运行项目**：
   - 点击左下角的"运行"按钮（绿色播放图标）
   - 或按快捷键 `Ctrl+R`
   - 应用程序会自动启动

#### 4. 验证启动
- 前端应用启动后，会显示登录页面
- 确保可以正常连接到后端服务器

---

## 常见问题

### 后端问题

**问题1：数据库连接失败**
- **原因**：数据库服务未启动、连接信息配置错误、网络问题
- **解决方法**：
  1. 检查 MySQL 服务是否运行：`sudo systemctl status mysql`
  2. 检查配置文件中的数据库连接信息是否正确
  3. 测试数据库连接：`mysql -h 127.0.0.1 -u root -p`

**问题2：Redis 连接失败**
- **原因**：Redis 服务未启动、连接信息配置错误
- **解决方法**：
  1. 检查 Redis 服务是否运行：`sudo systemctl status redis-server`
  2. 检查配置文件中的 Redis 连接信息是否正确
  3. 测试 Redis 连接：`redis-cli ping`

**问题3：端口被占用**
- **原因**：8080 端口已被其他程序使用
- **解决方法**：
  1. 查找占用端口的进程：`lsof -i :8080`（Linux）或 `netstat -ano | findstr :8080`（Windows）
  2. 修改 `main.go` 中的端口号
  3. 同时修改前端 `apiclient.cpp` 中的 API 地址

**问题4：Go 模块下载失败**
- **原因**：网络问题、代理设置问题
- **解决方法**：
  1. 设置 Go 代理：`go env -w GOPROXY=https://goproxy.cn,direct`
  2. 检查网络连接
  3. 手动下载依赖：`go mod download`

### 前端问题

**问题1：无法连接到后端**
- **原因**：后端未启动、API 地址配置错误、防火墙阻止
- **解决方法**：
  1. 确认后端服务已启动
  2. 检查 `apiclient.cpp` 中的 API 地址是否正确
  3. 检查防火墙设置，确保端口可访问
  4. 测试后端连接：`curl http://127.0.0.1:8080`

**问题2：Qt6 模块找不到**
- **原因**：Qt6 未正确安装、环境变量未配置
- **解决方法（Linux）**：
  1. 确认 Qt6 已正确安装
  2. 设置 Qt6_DIR 环境变量：`export Qt6_DIR=/path/to/qt6/lib/cmake/Qt6`
  3. 在 CMakeLists.txt 中指定 Qt6 路径

- **解决方法（Windows）**：
  1. **确认 Qt6 安装路径**：
     - 默认路径通常是：`C:\Qt\6.8.0\msvc2019_64` 或 `C:\Qt\6.8.0\mingw_64`
     - 检查该路径下是否存在 `lib\cmake\Qt6` 目录

  2. **设置环境变量**：
     - 方法一：在命令提示符中临时设置（仅当前会话有效）：
       ```cmd
       set Qt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6
       ```
     - 方法二：添加到系统环境变量（永久）：
       - 右键"此电脑" → "属性" → "高级系统设置" → "环境变量"
       - 在"系统变量"中点击"新建"
       - 变量名：`Qt6_DIR`
       - 变量值：`C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6`（根据实际路径调整）
       - 点击"确定"，**重新打开命令提示符**

  3. **在 CMake 命令中指定**：
     ```cmd
     cmake .. -DQt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6
     ```

  4. **使用 Qt Creator**：
     - 在 Qt Creator 中，点击"工具" → "选项" → "Kits"
     - 检查"Qt 版本"是否正确配置
     - 如果没有，点击"添加"，选择 Qt 安装目录下的 `bin\qmake.exe`

**问题3：编译错误**
- **原因**：缺少依赖、编译器版本不兼容、CMake 版本过低
- **解决方法（Linux）**：
  1. 检查所有依赖是否已安装
  2. 确认编译器版本符合要求（GCC 7+ 或 Clang 5+）
  3. 升级 CMake 到 3.21 或更高版本

- **解决方法（Windows）**：
  1. **检查编译器**：
     - Visual Studio：确认已安装"使用 C++ 的桌面开发"工作负载
     - MinGW：确认已正确安装并添加到 PATH
     - 在命令提示符中运行 `cl`（Visual Studio）或 `gcc --version`（MinGW）验证

  2. **检查 CMake 版本**：
     ```cmd
     cmake --version
     ```
     - 如果版本低于 3.21，需要升级 CMake

  3. **清理构建目录**：
     ```cmd
     cd smartparkingui\build
     # 删除所有文件，重新配置
     rmdir /s /q *
     cmake .. -DQt6_DIR=C:\Qt\6.8.0\msvc2019_64\lib\cmake\Qt6
     ```

  4. **检查错误信息**：
     - 仔细阅读 CMake 配置阶段的错误信息
     - 常见错误：
       - "Could not find Qt6"：Qt6_DIR 未正确设置
       - "No CMAKE_CXX_COMPILER could be found"：编译器未找到，检查 Visual Studio 或 MinGW 安装
       - "CMake Error: CMAKE_CXX_COMPILER not set"：需要在正确的命令提示符中运行（Developer Command Prompt）

  5. **使用 Qt Creator 调试**：
     - Qt Creator 会显示详细的编译错误信息
     - 在"问题"面板中查看具体错误
     - 点击错误可以跳转到对应的代码行

**问题4：运行时崩溃**
- **原因**：缺少动态库、权限问题、数据格式错误
- **解决方法（Linux）**：
  1. 检查动态库是否在系统路径中
  2. 检查文件权限
  3. 查看错误日志，定位具体问题

- **解决方法（Windows）**：
  1. **缺少 DLL 文件**：
     - 错误信息通常为："无法启动此应用程序，因为计算机中丢失 Qt6Core.dll"
     - 解决方法：
       - 将 Qt 的 bin 目录添加到 PATH 环境变量
       - 或复制所需的 DLL 文件到可执行文件所在目录
       - 所需 DLL 通常在：`C:\Qt\6.8.0\msvc2019_64\bin` 或 `C:\Qt\6.8.0\mingw_64\bin`
       - 主要 DLL 文件：
         - `Qt6Core.dll`
         - `Qt6Gui.dll`
         - `Qt6Qml.dll`
         - `Qt6Quick.dll`
         - `Qt6QuickControls2.dll`
         - `Qt6Network.dll`
         - 以及对应的 `.dll` 文件

  2. **使用 windeployqt 工具（推荐）**：
     - Qt 提供了自动部署工具，可以自动复制所需的 DLL
     - 在命令提示符中运行：
       ```cmd
       cd smartparkingui\build\Release
       C:\Qt\6.8.0\msvc2019_64\bin\windeployqt.exe SmartParkingUI.exe
       ```
     - 这会自动复制所有必需的 DLL 和资源文件到 Release 目录

  3. **Visual C++ 运行时库**：
     - 如果提示缺少 `MSVCP140.dll` 或 `VCRUNTIME140.dll`
     - 下载并安装 Visual C++ Redistributable：
       - Visual Studio 2019：https://aka.ms/vs/16/release/vc_redist.x64.exe
       - Visual Studio 2022：https://aka.ms/vs/17/release/vc_redist.x64.exe

  4. **查看详细错误信息**：
     - 使用 Visual Studio 调试器：
       - 在 Visual Studio 中打开项目
       - 按 F5 运行调试
       - 查看"输出"窗口和"调用堆栈"窗口
     - 使用事件查看器：
       - 打开"事件查看器"（eventvwr.msc）
       - 查看"Windows 日志" → "应用程序"
       - 查找应用程序崩溃的错误记录

  5. **检查后端连接**：
     - 确认后端服务已启动
     - 检查 `apiclient.cpp` 中的 API 地址是否正确
     - 测试后端连接：在浏览器中访问 `http://127.0.0.1:8080`

### 功能使用问题

**问题1：登录失败**
- **原因**：账号密码错误、验证码过期、网络问题
- **解决方法**：
  1. 确认账号密码正确
  2. 验证码有效期为 5 分钟，过期需重新获取
  3. 检查网络连接

**问题2：预订失败**
- **原因**：时间选择错误、车位不足、订单冲突
- **解决方法**：
  1. 确保预订时间不早于当前时间
  2. 检查是否有可用车位
  3. 避免时间冲突

**问题3：支付失败**
- **原因**：支付服务未初始化、订单状态错误、网络问题
- **解决方法**：
  1. 确认后端支付服务已正确配置
  2. 检查订单状态
  3. 重试支付操作

**问题4：车位分配失败**
- **原因**：车位不足、车位类型不匹配、系统错误
- **解决方法**：
  1. 选择其他停车场或车位类型
  2. 稍后重试
  3. 联系管理员

---

## 技术支持

### 日志查看

**后端日志**：
- 日志文件位置：`smart_parking_backend/server.log`
- 查看日志：`tail -f smart_parking_backend/server.log`

**前端日志**：
- 前端日志输出到控制台
- 在终端运行前端程序可以查看详细日志

### 数据库维护

**备份数据库**：
```bash
mysqldump -u root -p smart_parking > backup.sql
```

**恢复数据库**：
```bash
mysql -u root -p smart_parking < backup.sql
```

### 测试数据生成

系统提供了测试数据生成脚本，可以快速生成测试数据：

```bash
cd smart_parking_backend
./generate_test_data.sh
```

或使用 Go 脚本：
```bash
go run generate_test_data.go
```

---

## 附录

### 默认配置

- **后端端口**：8080
- **数据库端口**：3306
- **Redis 端口**：6379
- **前端 API 地址**：http://127.0.0.1:8080

### 重要文件路径

- **后端主程序**：`smart_parking_backend/main.go`
- **后端配置文件**：`smart_parking_backend/config/config.yaml`
- **前端 API 客户端**：`smartparkingui/src/apiclient.cpp`
- **前端主界面**：`smartparkingui/ui/main.qml`

### 相关文档

- **API 接口文档**：`smart_parking_backend/API_DOCUMENT.md`
- **前端 README**：`smartparkingui/README.md`
