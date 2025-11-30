# 头文件包含路径修复说明

## 问题描述
构建时出现错误：
```
error: parkingrecord.h: No such file or directory
error: authmanager.h: No such file or directory
...
```

## 原因分析
1. 源文件使用相对路径包含头文件（如 `#include "parkingrecord.h"`）
2. 头文件实际在 `include/models/` 目录下
3. CMakeLists.txt 没有正确设置 include 目录

## 解决方案

### 1. 修改源文件中的 include 路径
将所有源文件中的头文件包含路径改为相对于 `include/` 目录的路径：

**修改前：**
```cpp
#include "parkingrecord.h"
#include "user.h"
#include "jsonhelper.h"
```

**修改后：**
```cpp
#include "models/parkingrecord.h"
#include "models/user.h"
#include "utils/jsonhelper.h"
```

### 2. 在 CMakeLists.txt 中添加 include 目录
```cmake
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/models
    ${CMAKE_CURRENT_SOURCE_DIR}/include/utils
)
```

## 修改的文件列表

### 源文件
- `src/models/user.cpp`
- `src/models/vehicle.cpp`
- `src/models/parkingrecord.cpp`
- `src/models/paymentrecord.cpp`
- `src/models/reservationorder.cpp`
- `src/models/violationrecord.cpp`
- `src/utils/jsonhelper.cpp`

### 配置文件
- `CMakeLists.txt` - 添加了 include 目录设置

## 验证修复

1. **清理构建目录**
   ```bash
   rm -rf build/
   ```

2. **在Qt Creator中重新配置项目**
   - 菜单：构建 → 运行 CMake

3. **重新构建**
   - 按 `Ctrl+B` 或点击构建按钮
   - 应该能成功构建，没有头文件找不到的错误

## 文件结构

```
smartparkingui/
├── include/              # 头文件目录
│   ├── apiclient.h
│   ├── authmanager.h
│   ├── models/          # 模型头文件
│   │   ├── user.h
│   │   ├── vehicle.h
│   │   └── ...
│   └── utils/           # 工具类头文件
│       └── jsonhelper.h
├── src/                 # 源文件目录
│   ├── models/          # 模型实现
│   │   ├── user.cpp     # #include "models/user.h"
│   │   └── ...
│   └── utils/           # 工具类实现
│       └── jsonhelper.cpp  # #include "utils/jsonhelper.h"
└── CMakeLists.txt       # 已添加include目录
```

## 注意事项

- 头文件包含路径是相对于 `include/` 目录的
- `apiclient.h` 和 `authmanager.h` 直接在 `include/` 下，所以使用 `#include "apiclient.h"`
- 模型类在 `include/models/` 下，所以使用 `#include "models/user.h"`
- 工具类在 `include/utils/` 下，所以使用 `#include "utils/jsonhelper.h"`

