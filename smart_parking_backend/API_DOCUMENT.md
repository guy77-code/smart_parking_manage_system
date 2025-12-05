## 智能停车后端接口文档（基于 smart_parking_backend）

> 说明：本文件根据 `smart_parking_backend` 目录下现有 Go 代码整理，主要服务于 **QT6 前端开发**。  
> 文档按路由分组，统一列出：**URL、HTTP 方法、鉴权要求、请求参数、响应结构、典型业务流程说明**。  
> 所有返回均为 JSON，除明确说明外，HTTP 200 一般表示业务成功，其它状态码通常为 4xx/5xx 错误。

---

## 一、统一约定

- **基础 URL**
  - 用户基础接口：`/api/v1`
  - 停车场 & 车位接口：`/api/v2`、`/api/v3`
  - 预订模块：`/api/v4/booking`
  - 停车流程模块：`/api/parking`
  - 违规模块：`/api/violations`
  - 支付模块：`/api/payment`
  - 管理端：`/admin`

- **返回结构（常见形式）**
  - Booking / Payment 等模块常用：
    ```json
    {
      "code": 0,
      "message": "success 或错误原因",
      "data": { ... }   // 具体数据，可为空
    }
    ```
  - 其它 controller 多直接返回自由结构，例如：
    ```json
    { "message": "...", "data": ... }
    ```

- **时间格式**
  - 预订模块允许多种时间字符串：
    - `RFC3339`：`2025-01-02T15:04:05Z`
    - `"2006-01-02 15:04:05"`
    - `"2006/01/02 15:04:05"`
  - 管理端统计接口通常要求 `RFC3339`。

- **管理员鉴权**
  - 管理端 `/admin` 下部分接口需要 `AdminAuthMiddleware`：
    - 请求头：`Authorization: Bearer {admin_jwt_token}`
  - JWT 的 `admin_id`、`role`、`lot_id` 从 Token 中解析并写入 Gin Context。

---

## 二、用户模块（/api/v1）

### 1. 用户注册

- **URL**：`POST /api/v1/register`
- **鉴权**：不需要
- **处理函数**：`controller.Register`
- **请求体（JSON）**：
  ```json
  {
    "users_list": {
      "username": "string, 必填，3-50 字符",
      "password": "string, 必填，>=6 字符",
      "phone": "string, 必填",
      "email": "string, 可选",
      "real_name": "string, 可选"
    },
    "vehicles": [
      {
        "license_plate": "string, 必填",
        "brand": "string, 可选",
        "model": "string, 可选",
        "color": "string, 可选"
      }
      // 至少 1 条
    ]
  }
  ```
- **响应示例**：
  ```json
  {
    "message": "用户注册成功",
    "user_id": 1,
    "vehicles_registered": 2
  }
  ```
- **说明**：
  - 支持一次注册绑定多辆车。
  - 密码会进行 bcrypt 加密存储。

### 2. 发送登录验证码

- **URL**：`POST /api/v1/send_code`
- **鉴权**：不需要
- **处理函数**：`controller.SendLoginCode`
- **请求体**：
  ```json
  { "phone": "string, 必填" }
  ```
- **响应示例**（开发环境会返回验证码）：
  ```json
  {
    "message": "验证码已发送至您的手机",
    "expires_in": 300,
    "code": "123456",
    "resend_after": 60
  }
  ```
- **说明**：
  - 内部做了手机号格式校验与发送频率限制（60s 内只能发一次）。
  - 真实生产环境应移除 `code` 字段，仅通过短信发送。

### 3. 用户登录（密码 / 验证码）

- **URL**：`POST /api/v1/login`
- **鉴权**：不需要
- **处理函数**：`controller.Login`
- **请求体**：
  ```json
  {
    "phone": "string, 必填",
    "password": "string, 可选",
    "code": "string, 可选"
  }
  ```
  - 登录模式：
    - `phone + password`：密码登录
    - `phone + code`：短信验证码登录
- **响应示例**：
  ```json
  {
    "message": "Login success",
    "user": {
      "id": 1,
      "username": "test",
      "phone": "13800000000",
      "email": "xx@xx.com"
    },
    "token": "jwt-token-string"
  }
  ```
- **说明**：
  - 登录成功更新用户 `last_login`。
  - `token` 为用户 JWT，后续业务可以通过中间件解析并把 `user_id` 写入 Context（当前项目中部分接口已假设存在此中间件）。

### 4. 获取用户支付记录

- **URL**：`GET /api/v1/getpaymentinfo`
- **鉴权**：需要用户 JWT（需在上游中间件把 `user_id` 放入 Gin Context）
- **处理函数**：`controller.GetUserPaymentRecords`
- **查询参数**：
  - `page`：页码，默认 `1`
  - `page_size`：每页数量，默认 `10`
- **响应示例**：
  ```json
  {
    "total": 20,
    "page": 1,
    "page_size": 10,
    "records": [
      {
        "payment_id": 1001,
        "order_id": 1,
        "amount": 10.5,
        "method": "wechat",
        "payment_status": 1,
        "pay_time": "2025-01-02T10:00:00Z",
        "order": {
          "order_id": 1,
          "reservation_cod": "R202501020001",
          "...": "..."
        },
        "order_type": "parking",
        "order_details": {
          "record_id": 1,
          "entry_time": "2025-01-02T10:00:00Z",
          "exit_time": "2025-01-02T12:30:00Z",
          "duration_minute": 150,
          "fee_calculated": 10.5,
          "lot": {
            "lot_id": 1,
            "name": "智慧城市中心停车场",
            "address": "北京市朝阳区建国路100号"
          },
          "vehicle": {
            "vehicle_id": 1,
            "license_plate": "粤A12345",
            "brand": "特斯拉",
            "model": "Model 3",
            "color": "白色"
          }
        }
      }
    ]
  }
  ```
- **响应字段说明**：
  - `order_type`：订单类型，可能的值：
    - `"reservation"`：预订订单
    - `"parking"`：停车订单
    - `"violation"`：违规订单
  - `order_details`：订单详细信息，根据 `order_type` 不同而不同：
    - **预订订单** (`order_type="reservation"`)：
      - `order_id`：预订订单ID
      - `reservation_cod`：预订编号
      - `start_time`：预订开始时间
      - `end_time`：预订结束时间
      - `status`：预订状态（**重要**）
        - `0`：已取消
        - `1`：已预订
        - `2`：使用中（车辆已进场）
        - `3`：已完成（车辆已离场）
      - `entry_time`：入场时间（当状态为使用中或已完成时存在）
      - `exit_time`：离场时间（当状态为已完成时存在）
      - `duration_minute`：停车时长（分钟，当状态为使用中或已完成时存在）
    - **停车订单** (`order_type="parking"`)：
      - `record_id`：停车记录ID
      - `entry_time`：入场时间
      - `exit_time`：离场时间（如果已离场）
      - `duration_minute`：停车时长（分钟）
      - `fee_calculated`：计算出的费用
      - `lot`：停车场信息（`lot_id`, `name`, `address`）
      - `vehicle`：车辆信息（`vehicle_id`, `license_plate`, `brand`, `model`, `color`）
    - **违规订单** (`order_type="violation"`)：
      - `violation_id`：违规记录ID
      - `violation_type`：违规类型
      - `violation_time`：违规时间
      - `description`：违规描述
      - `fine_amount`：罚款金额
      - `status`：违规处理状态（0-未处理，1-已处理）
      - `vehicle`：车辆信息
    - `"violation"`：违规订单
  - `order_details`：订单详细信息，根据订单类型不同包含不同字段：
    - **停车订单（parking）**：
      - `record_id`：停车记录ID
      - `entry_time`：入场时间
      - `exit_time`：出场时间（可能为null）
      - `duration_minute`：停车时长（分钟）
      - `fee_calculated`：计算停车费
      - `lot`：停车场信息（`lot_id`、`name`、`address`）
      - `vehicle`：车辆信息（`vehicle_id`、`license_plate`、`brand`、`model`、`color`）
    - **违规订单（violation）**：
      - `violation_id`：违规记录ID
      - `violation_type`：违规类型
      - `violation_time`：违规时间
      - `description`：违规事件描述
      - `fine_amount`：罚款金额
      - `status`：处理状态（0=未处理，1=已处理）
      - `vehicle`：车辆信息（`vehicle_id`、`license_plate`、`brand`、`model`、`color`）
    - **预订订单（reservation）**：
      - `order_id`：预订订单ID
      - `reservation_cod`：预订编号
      - `start_time`：预订开始时间
      - `end_time`：预订结束时间
      - `status`：订单状态
- **说明**：
  - 只返回当前用户（从 Token 提取的 `user_id`）相关的支付记录。
  - 接口会根据支付记录的 `transaction_no` 字段和关联的订单记录自动判断订单类型，并查询对应的详细信息。
  - **预订状态更新**：
    - 当用户车辆在预订时间内进场时，预订状态会自动更新为 `2`（使用中）
    - 当用户车辆离开停车场后，预订状态会自动更新为 `3`（已完成）
    - 前端刷新订单列表时，会获取到最新的预订状态
  - **订单类型识别**：
    - 预订订单优先识别：如果支付记录关联了 `ReservationOrder`，即使该预订已进场或已完成，仍然识别为 `"reservation"` 类型
    - 停车订单：仅当支付记录直接关联停车记录（无预订订单）时，识别为 `"parking"` 类型
    - 违规订单：通过 `transaction_no` 前缀 `PENDING_VIO_` 识别
  - **刷新功能**：前端可通过重新调用此接口实现订单记录刷新，建议保持当前分页参数（`page` 和 `page_size`）以维持用户浏览状态。

### 5. 获取当前登录用户的车辆列表

- **URL**：`GET /api/v1/vehicles`
- **鉴权**：需要用户 JWT（`UserAuthMiddleware`，从 Token 中解析 `user_id`）
- **处理函数**：`controller.GetUserVehicles`
- **请求参数**：无（从 Token 中获取用户 ID）
- **请求头**：
  - `Authorization: Bearer {user_jwt_token}`
- **响应示例**：
  ```json
  {
    "total": 2,
    "data": [
      {
        "vehicle_id": 1,
        "license_plate": "粤A12345",
        "brand": "特斯拉",
        "model": "Model 3",
        "color": "白色"
      },
      {
        "vehicle_id": 2,
        "license_plate": "粤B54321",
        "brand": "比亚迪",
        "model": "汉",
        "color": "黑色"
      }
    ]
  }
  ```
- **说明**：
  - 返回当前登录用户在 `vehicle` 表中的所有车辆。
  - 字段命名与登录接口中返回的 `user.vehicles` 保持一致（`vehicle_id` / `license_plate` 等），方便前端统一处理。

### 6. 为当前用户添加车辆

- **URL**：`POST /api/v1/vehicles`
- **鉴权**：需要用户 JWT
- **处理函数**：`controller.AddUserVehicle`
- **请求体**：
  ```json
  {
    "license_plate": "string, 必填，车牌号，需唯一",
    "brand": "string, 可选，品牌",
    "model": "string, 可选，车型",
    "color": "string, 可选，颜色"
  }
  ```
- **响应示例**：
  ```json
  {
    "message": "车辆添加成功",
    "vehicle": {
      "vehicle_id": 3,
      "license_plate": "粤C00001",
      "brand": "丰田",
      "model": "卡罗拉",
      "color": "银色"
    }
  }
  ```
- **说明**：
  - `user_id` 从 Token 中获取，无需前端传递。
  - 若车牌号在 `vehicle` 表中已存在，将因唯一约束导致插入失败，后端会返回 `"添加车辆失败: ..."` 错误信息。

### 7. 删除当前用户的一辆车辆

- **URL**：`DELETE /api/v1/vehicles/:id`
- **鉴权**：需要用户 JWT
- **处理函数**：`controller.DeleteUserVehicle`
- **路径参数**：
  - `id`：车辆 ID（`vehicle_id`）
- **响应示例**：
  ```json
  {
    "message": "车辆删除成功",
    "vehicle_id": 3
  }
  ```
- **错误情况**：
  - `401 未授权`：未携带或携带无效 Token。
  - `404 未找到`：该 `vehicle_id` 不存在，或不属于当前用户。
  - `500 内部错误`：数据库删除失败等。
- **说明**：
  - 使用外键级联（`OnDelete:CASCADE`）自动处理与该车辆相关的预约、停车记录、违规记录等数据。
  - 建议前端在删除前提醒用户该操作可能会清理相关历史记录。

---

## 三、管理员模块（/admin）

### 1. 管理员注册

- **URL**：`POST /admin/register`
- **鉴权**：不需要
- **处理函数**：`controller.AdminRegisterController`
- **请求体**：
  ```json
  {
    "phone": "string, 必填",
    "password": "string, 必填, 6-20 字符",
    "lot_id": 1,        // 可选，对应停车场 ID
    "role": "system"    // 可选，"system" 或 "lot_admin"，默认 "lot_admin"
  }
  ```
- **响应示例**：
  ```json
  {
    "message": "注册成功",
    "admin": {
      "admin_id": 1,
      "username": "13800000000",
      "role": "lot_admin",
      "lot_id": 1,
      "status": 1,
      "create_time": "2025-01-02T10:00:00Z"
    }
  }
  ```

### 2. 管理员登录

- **URL**：`POST /admin/login`
- **鉴权**：不需要
- **处理函数**：`controller.AdminLoginController`
- **请求体**：
  ```json
  {
    "phone": "string, 必填",
    "password": "string, 必填"
  }
  ```
- **响应示例（系统管理员）**：
  ```json
  {
    "message": "系统管理员登录成功",
    "role": "system",
    "token": "admin-jwt-token",
    "admin_info": { ... }
  }
  ```
- **响应示例（停车场管理员）**：
  ```json
  {
    "message": "停车场管理员登录成功",
    "role": "lot_admin",
    "token": "admin-jwt-token",
    "admin_info": { ... },
    "lot_id": 1
  }
  ```
- **说明**：
  - 登录成功后，前端需要在后续管理端接口中携带 `Authorization: Bearer {token}`。

### 3. 车位使用率分析（管理员）

- **URL**：`GET /admin/occupancy`
- **鉴权**：需要管理员 JWT（`AdminAuthMiddleware`）
- **处理函数**：`controller.ParkingSpaceOccupancyAnalysis`
- **查询参数**：
  - `start_time`: `RFC3339` 起始时间
  - `end_time`: `RFC3339` 结束时间
- **响应示例**：
  ```json
  {
    "message": "停车场分析成功",
    "data": {
      "total_spaces": 200,
      "occupied_spaces": 120,
      "reserved_spaces": 30,
      "occupancy_rate": 60.0,
      "total_income": 12000.5,
      "avg_daily_income": 800.3,
      "avg_parking_hours": 2.5
    },
    "metadata": {
      "lot_id": 1,
      "start_time": "2025-01-01T00:00:00Z",
      "end_time": "2025-01-07T00:00:00Z",
      "time_range_days": 6.99
    }
  }
  ```

### 4. 违规行为分析（管理员）

- **URL**：`GET /admin/violations`
- **鉴权**：需要管理员 JWT
- **处理函数**：`controller.ViolationAnalysis`
- **查询参数**：
  - `year`：年份，可选，默认当前年
  - `month`：月份（1-12），可选，默认当前月
- **响应结构（简要）**：
  ```json
  {
    "message": "违规分析成功",
    "data": {
      "total_violations": 30,
      "violations_by_type": [
        { "violation_type": "预订未使用", "count": 10 },
        { "violation_type": "超时停车", "count": 20 }
      ],
      "violations_by_status": [
        { "status": 0, "count": 5 },
        { "status": 1, "count": 25 }
      ],
      "total_fines": 5000.0,
      "collected_fines": 4000.0,
      "monthly_trend": [
        {
          "year_month": "2025-01",
          "total_violations": 30,
          "processed_count": 25,
          "processing_rate": 83.3,
          "total_fines": 5000.0
        }
      ]
    },
    "metadata": {
      "lot_id": 1,
      "year": 2025,
      "month": 1,
      "start_time": "...",
      "end_time": "..."
    }
  }
  ```

### 5. 报表生成（管理员）

- **URL**：`GET /admin/report`
- **鉴权**：需要管理员 JWT
- **处理函数**：`controller.GenerateReport`
- **查询参数**：
  - `type`：`"monthly"` 或 `"annual"`，必填
  - `year`：年份，可选，默认当前年
  - `month`：月份（1-12），仅当 `type=monthly` 时生效
- **响应结构（简要）**：
  ```json
  {
    "message": "报告生成成功",
    "report": {
      "report_type": "monthly",
      "period": "2025-01-01 至 2025-01-31",
      "generated_at": "2025-02-01T10:00:00Z",
      "parking_statistics": { ... },
      "violation_statistics": { ... },
      "revenue_statistics": { ... },
      "occupancy_statistics": { ... },
      "peak_hours_analysis": [ ... ]
    },
    "metadata": {
      "lot_id": 1,
      "report_type": "monthly",
      "year": 2025,
      "month": "1",
      "start_time": "...",
      "end_time": "..."
    }
  }
  ```

---

## 四、停车场与车位管理（/api/v2, /api/v3）

> `/api/v2` 与 `/api/v3` 中车位相关接口基本重复，QT 前端可统一封装。

### 1. 添加停车场

- **URL**：`POST /api/v2/addparkinglot`
- **鉴权**：建议仅管理员使用（当前代码未强制校验）
- **处理函数**：`controller.AddParkingLot`
- **请求体（`model.ParkingLot` 字段）**：
  ```json
  {
    "name": "停车场名称, 必填",
    "address": "详细地址, 必填",
    "total_levels": 3,
    "total_spaces": 200,
    "hourly_rate": 5.0,
    "status": 1,
    "description": "说明..."
  }
  ```
- **响应**：
  ```json
  {
    "message": "停车场添加成功",
    "data": { "lot_id": 1, "...": "..." }
  }
  ```

### 2. 获取所有停车场

- **URL**：`GET /api/v2/getparkinglots`
- **处理函数**：`controller.GetAllParkingLots`
- **请求参数**：无
- **响应**：
  ```json
  {
    "message": "查询成功",
    "data": [
      {
        "lot_id": 1,
        "name": "...",
        "spaces": [ { "space_id": 1, "...": "..." } ]
      }
    ]
  }
  ```

### 3. 获取指定停车场详情

- **URL**：`GET /api/v2/getparkinglot/:id`
- **处理函数**：`controller.GetParkingLotByID`
- **路径参数**：
  - `id`：停车场 ID

### 4. 新增车位

- **URL**：
  - `POST /api/v2/addparkingspace`
  - `POST /api/v3/addparkingspace`
- **处理函数**：`controller.AddParkingSpace`
- **请求体（`model.ParkingSpace` 结构）**：
  ```json
  {
    "lot_id": 1,
    "level": 1,
    "space_number": "A-001",
    "space_type": "普通",   // 如：普通、充电桩、残疾人、VIP
    "status": 1
  }
  ```
- **响应**：
  ```json
  {
    "message": "车位添加成功",
    "data": {
      "space_id": 1,
      "lot": { "lot_id": 1, "name": "..." },
      "...": "..."
    }
  }
  ```

### 5. 更新车位状态

- **URL**：
  - `PATCH /api/v2/updatespacestatus/:id`
  - `PATCH /api/v3/updatespacestatus/:id`
- **处理函数**：`controller.UpdateSpaceStatus`
- **路径参数**：
  - `id`：车位 ID
- **请求体（部分字段，可选）**：
  ```json
  {
    "status": 1,       // 0-禁用, 1-可用
    "is_occupied": 0,  // 0-未占用, 1-占用
    "is_reserved": 0   // 0-未预订, 1-已预订
  }
  ```
- **响应**：
  ```json
  {
    "message": "车位状态更新成功",
    "data": { "...": "更新后的 ParkingSpace 对象" }
  }
  ```

### 6. 获取指定停车场下所有车位

- **URL**：
  - `GET /api/v2/getspacesbylotid/:lot_id`
  - `GET /api/v3/getspacesbylotid/:lot_id`
- **处理函数**：`controller.GetSpacesByLotID`
- **路径参数**：
  - `lot_id`：停车场 ID
- **响应**：
  ```json
  {
    "message": "查询成功",
    "count": 20,
    "data": [ { "space_id": 1, "space_number": "A-001", "...": "..." } ]
  }
  ```

> 另外在 `user_parking.go` 中还有一个更简单版本的车位列表接口：
>
> - **URL**：`GET /api/parking/lots/:lot_id/spaces`
> - **处理函数**：`controller.GetParkingLotSpaces`
> - **响应**：直接返回 `[]ParkingSpace`。

---

## 五、预订模块（/api/v4/booking）

所有接口由 `booking.BookingRoutes` 注册，使用统一响应结构：

```json
{
  "code": 0,
  "message": "success 或错误原因",
  "data": ...
}
```

### 1. 创建预订

- **URL**：`POST /api/v4/booking/create`
- **处理函数**：`booking.Handler.CreateBooking`
- **请求体**：
  ```json
  {
    "user_id": 1,
    "vehicle_id": 10,
    "lot_id": 2,
    "start_time": "2025-01-02T10:00:00Z",
    "end_time": "2025-01-02T12:00:00Z",
    "space_type": "普通"
  }
  ```
- **请求参数说明**：
  - `user_id`：用户ID（必填）
  - `vehicle_id`：车辆ID（必填）
  - `lot_id`：停车场ID（必填）
  - `start_time`：预订开始时间（必填，RFC3339格式）
  - `end_time`：预订结束时间（必填，RFC3339格式）
  - `space_type`：车位类型（可选，默认为"普通"），可选值：普通、充电桩等
- **响应**：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": {
      "order_id": 100,
      "reservation_cod": "R2025...",
      "...": "ReservationOrder 字段"
    }
  }
  ```

### 2. 取消预订

- **URL**：`DELETE /api/v4/booking/cancel/:id`
- **处理函数**：`booking.Handler.CancelBooking`
- **路径参数**：
  - `id`：预订订单 ID
- **响应**：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": { "message": "预订取消成功" }
  }
  ```

### 3. 获取用户的预订列表

- **URL**：`GET /api/v4/booking/user`
- **处理函数**：`booking.Handler.GetUserBookings`
- **查询参数**：
  - `user_id`: 用户 ID，必填
- **响应**：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": [
      { "order_id": 100, "...": "ReservationOrder 字段" }
    ]
  }
  ```
- **说明**：
  - **刷新功能**：前端可通过重新调用此接口实现预订信息刷新，获取最新的预订列表。

### 4. 获取预订详情

- **URL**：`GET /api/v4/booking/detail/:id`
- **处理函数**：`booking.Handler.GetBookingDetail`
- **路径参数**：
  - `id`：预订订单 ID
- **响应**：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": { "order_id": 100, "...": "ReservationOrder 字段" }
  }
  ```

### 5. 检查并更新超时预订

- **URL**：`POST /api/v4/booking/check-expired`
- **处理函数**：`booking.Handler.CheckAndUpdateExpiredBookings`
- **鉴权**：不需要（建议前端定期调用或后端定时任务调用）
- **请求体**：无
- **响应**：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": {
      "updated_count": 5,
      "message": "已更新 5 条超时预订记录"
    }
  }
  ```
- **业务说明**：
  - 检查所有已超过结束时间（`end_time < 当前时间`）且状态为"已预订"（status=1）或"使用中"（status=2）的预订记录
  - 将这些预订的状态更新为"已取消"（status=0）
  - 设置 `actual_end_time` 为当前时间
  - 释放关联的车位（将车位的 `is_reserved` 设为 0）
  - 返回更新的记录数量
- **使用场景**：
  - 前端可以在用户查看预订列表时调用此接口，确保显示最新的预订状态
  - 后端可以设置定时任务定期调用此接口，自动清理超时的预订记录
- **说明**：
  - 此接口会批量处理所有超时的预订记录，建议不要频繁调用（如每分钟调用一次）
  - 建议在用户主动刷新预订列表时调用，或由后端定时任务（如每小时）调用

---

## 六、停车流程模块（/api/parking）

### 1. 获取可用车位类型

- **URL**：`GET /api/parking/space-types`
- **处理函数**：`controller.GetParkingSpaceTypes`
- **请求参数**：无
- **响应**：
  ```json
  ["普通", "残疾人", "充电桩", "VIP"]
  ```
  或来自数据库的实际类型列表。

### 2. 获取指定停车场的车位信息（简化版）

- **URL**：`GET /api/parking/lots/:lot_id/spaces`
- **处理函数**：`controller.GetParkingLotSpaces`
- **路径参数**：
  - `lot_id`：停车场 ID
- **响应**：`[]ParkingSpace`

### 3. 获取用户当前在场停车记录

- **URL**：`GET /api/parking/:user_id/active-parking`
- **处理函数**：`controller.GetUserActiveParkingRecords`
- **路径参数**：
  - `user_id`：用户 ID（必填）
- **响应**（成功，HTTP 200）：
  - **有记录时**：返回停车记录数组
  ```json
  [
    {
      "record_id": 1,
      "user_id": 1,
      "vehicle_id": 10,
      "vehicle": {
        "vehicle_id": 10,
        "license_plate": "粤A12345",
        "brand": "测试品牌",
        "model": "测试型号",
        "color": "白色"
      },
      "space_id": 10,
      "space": {
        "space_id": 10,
        "space_number": "A-010",
        "space_type": "普通",
        "is_occupied": 1,
        "is_reserved": 0
      },
      "lot_id": 1,
      "lot": {
        "lot_id": 1,
        "name": "智慧城市中心停车场",
        "address": "北京市朝阳区建国路100号",
        "hourly_rate": 8.0
      },
      "entry_time": "2025-01-02T10:00:00Z",
      "exit_time": null,
      "duration_minute": 0,
      "fee_calculated": 0.0,
      "fee_paid": 0.0,
      "payment_status": 0,
      "is_violation": 0,
      "violation_reason": "",
      "record_status": 1,
      "create_time": "2025-01-02T10:00:00Z"
    }
  ]
  ```
  - **无记录时**：返回空数组 `[]`
- **错误响应**：
  - HTTP 400：用户ID为空或无效
  - HTTP 500：查询停车记录失败
- **说明**：
  - 返回指定用户所有状态为"在场"（record_status=1）的停车记录
  - 记录包含完整的车辆、车位、停车场信息
  - 如果用户没有在场停车记录，返回HTTP 200和空数组`[]`（这是RESTful API的最佳实践，404应该用于资源不存在，而不是查询结果为空）

### 4. 获取停车场车位占用情况（实时概览）

- **URL**：`GET /api/parking/getparkinglotoccupancy/:lot_id`
- **处理函数**：`controller.GetParkingLotOccupancy`
- **响应**：
  ```json
  {
    "lot_id": "1",
    "occupancy": [
      {
        "space_type": "普通",
        "total": 100,
        "occupied": 60,
        "available": 40
      }
    ]
  }
  ```

### 5. 根据车牌号获取车辆及用户信息

- **URL**：`GET /api/parking/getlicense/:license_plate`
- **处理函数**：`controller.GetVehicleByLicensePlate`
- **响应**：`model.Vehicle` 对象（包含 `User` 信息）

### 6. 车辆入场

- **URL**：`POST /api/parking/entry`
- **处理函数**：`controller.VehicleEntry`
- **请求体**：
  ```json
  {
    "license_plate": "粤A12345",
    "space_type": "普通"   // 可选，不填则最终可能降级为普通车位
  }
  ```
- **响应**：
  ```json
  {
    "record_id": 1,
    "space_id": 10,
    "space_number": "A-010",
    "level": 1,
    "lot_name": "xx 停车场",
    "entry_time": "2025-01-02T10:00:00Z",
    "reservation_id": 100   // 若是由预约转入，则有此字段
  }
  ```
- **业务说明**：
  - 根据车牌号查找车辆和用户。
  - 若当前时间段有有效预约（状态为已预订，且在预订时间段内，允许提前30分钟入场），优先使用该预约车位并将预约状态置为“使用中”（status=2）。
  - 若无预约则分配一个空闲车位。
  - 创建 `ParkingRecord` 并将车位状态置为占用。
  - **预订状态更新**：如果车辆入场时使用了预订车位，预订状态会自动更新为"使用中"（status=2），前端可通过刷新预订列表获取最新状态。

### 7. 车辆出场

- **URL**：`POST /api/parking/exit`
- **处理函数**：`controller.VehicleExit`
- **请求体**：
  ```json
  {
    "license_plate": "粤A12345"  // 必填，车牌号
  }
  ```
- **响应**（成功，HTTP 200）：
  ```json
  {
    "record_id": 1,
    "space_id": 10,
    "space_number": "A-010",
    "lot_name": "智慧城市中心停车场",
    "entry_time": "2025-01-02T10:00:00Z",
    "exit_time": "2025-01-02T12:30:00Z",
    "duration_hours": 2.5,
    "total_fee": 30.0,          // 停车费 + 违规罚款
    "is_violation": true,       // 是否有违规
    "violation_fee": 10.0,      // 违规罚款金额
    "payment_url": "http://127.0.0.1:8081/simulate_payment?provider=alipay&payment_id=2001"
  }
  ```
- **错误响应**：
  - HTTP 400：无效的请求参数（车牌号为空）
  - HTTP 404：未找到在场停车记录
  - HTTP 500：查询停车记录失败、更新停车记录失败、释放车位失败、事务提交失败、支付服务未初始化
- **业务说明**：
  1. **查找记录**：根据车牌号查找状态为"在场"（record_status=1）的停车记录
  2. **计算费用**：
     - 计算停车时长（从入场时间到当前时间）
     - 根据停车时长和停车场费率计算停车费用
     - 检查是否有未处理的违规记录，计算违规罚款
     - 总费用 = 停车费 + 违规罚款
  3. **更新记录**（在事务内完成）：
     - 更新停车记录的出场时间、停车时长、计算费用
     - 更新记录状态为"已出场"（record_status=2）
     - 如果有违规，设置 is_violation=1
  4. **释放车位**：
     - 将车位状态更新为未占用（is_occupied=0）
  5. **处理预约**：
     - 如果该停车记录关联了预约（通过车辆ID和入场时间匹配），将预约状态更新为"已完成"（status=3），并设置 `actual_end_time` 为当前时间
     - **预订状态更新**：车辆离场后，关联的预订状态会自动更新为"已完成"（status=3），前端可通过刷新预订列表获取最新状态
  6. **生成支付**：
     - 调用统一支付服务创建支付单（类型为"parking"）
     - 生成模拟支付链接返回前端
- **注意事项**：
  - 所有数据库操作在事务内完成，确保数据一致性
  - 如果任何步骤失败，整个事务会回滚
  - 支付链接格式：`http://127.0.0.1:8081/simulate_payment?provider={method}&payment_id={payment_id}`

---

## 七、违规模块（/api/violations）

### 1. 检查并生成违规记录（批处理）

- **URL**：`POST /api/violations/check`
- **处理函数**：`controller.CheckViolations`
- **请求体**：
  ```json
  {
    "check_type": 1   // 1=预订未使用, 2=超时停车, 3=未支付停车费, 4=未支付罚款
  }
  ```
- **响应**：
  ```json
  { "violation_count": 5 }
  ```
- **业务说明**：
  - 内部根据类型扫描数据库，生成 `ViolationRecord` 并可能更新预约/停车记录状态。
  - 主要给定时任务或运维入口使用，普通前端一般不直接调用。

### 2. 用户查询自己的违规记录（精简）

- **URL**：`GET /api/violations/checkmyself/:user_id`
- **处理函数**：`controller.GetUserViolationHistory`
- **路径参数**：
  - `user_id`：用户 ID
- **查询参数**：
  - 无（已废弃status参数，默认返回所有违规记录）
- **响应**：
  ```json
  {
    "total": 3,
    "data": [
      {
        "violation_id": 1,
        "violation_type": "超时停车",
        "fine_amount": 50.0,
        "status": 0,
        "record": { ... },
        "vehicle": { ... },
        "user": { ... }
      }
    ]
  }
  ```
- **说明**：
  - **刷新功能**：前端可通过重新调用此接口实现违规记录刷新，获取最新的违规记录列表（包括支付状态更新后的记录）。

> 备注：`controller.GetUserViolations` 提供了一个类似的接口，但当前未在路由中注册，QT 前端不必使用。

### 3. 支付罚款（为某条违规记录创建支付）

- **URL**：`POST /api/violations/:violation_id/pay`
- **处理函数**：`controller.PayViolationFine`
- **路径参数**：
  - `violation_id`：违规记录 ID
- **请求体**：无（内部使用统一支付服务创建支付）
- **响应**：
  ```json
  {
    "violation_id": 1,
    "payment_id": 2001,
    "payment_url": "http://.../mock-payment?payment_id=2001"
  }
  ```
- **业务说明**：
  - 内部调用 `PaymentService.CreatePayment(order_id=violation_id, type="violation")`。
  - 前端在浏览器 / WebView 中打开 `payment_url` 即可完成模拟支付。

---

## 八、支付模块（/api/payment）

> 支付模块提供统一的支付接口，支持三种订单类型：预订（reservation）、停车（parking）、违规（violation）

### 1. 创建支付（统一入口）

- **URL**：`POST /api/payment/create`
- **处理函数**：`payment.Handler.CreatePaymentRedirectHandler`
- **请求体**：
  ```json
  {
    "order_id": 1,             // 必填，对应 reservation / parking / violation 的主键
                                // reservation: ReservationOrder.OrderID
                                // parking: ParkingRecord.RecordID
                                // violation: ViolationRecord.ViolationID
    "type": "reservation",      // 必填，"reservation" | "parking" | "violation"
    "method": "alipay",         // 必填，"alipay" | "wechat"
    "amount": 30.0              // 可选，不传则使用后端计算的应付金额
  }
  ```
- **响应**（成功，HTTP 200）：
  ```json
  {
    "code": 0,
    "message": "ok",
    "data": {
      "redirect_url": "http://127.0.0.1:8081/simulate_payment?provider=alipay&payment_id=2001"
    },
    "payment_id": 2001
  }
  ```
- **错误响应**（HTTP 400）：
  ```json
  {
    "code": 400,
    "message": "参数错误: ..."  // 或具体业务错误信息
  }
  ```
- **业务逻辑说明**：
  
  **预订支付（type="reservation"）**：
  - 验证订单存在、未支付、未取消
  - 金额：优先使用传入的 `amount`，否则使用订单的 `total_fee`
  - 如果金额为0，返回错误
  - 通过 `bookingSvc.CreatePendingPayment` 创建支付记录
  
  **停车支付（type="parking"）**：
  - 验证停车记录存在
  - 金额：优先使用传入的 `amount`，否则使用记录的 `fee_calculated`
  - 如果金额为0或未计算，使用默认金额10.0元（实际应根据停车时长计算）
  - 使用原生SQL插入支付记录（临时禁用外键检查，因为OrderID是ParkingRecord的ID而非ReservationOrder的ID）
  - TransactionNo使用临时唯一值：`PENDING_{record_id}_{timestamp}`
  
  **违规支付（type="violation"）**：
  - 验证违规记录存在且未处理
  - 金额：优先使用传入的 `amount`，否则使用违规记录的 `fine_amount`
  - 如果金额为0，返回错误
  - 使用原生SQL插入支付记录（临时禁用外键检查）
  - TransactionNo使用临时唯一值：`PENDING_VIO_{violation_id}_{timestamp}`（与普通支付区分）
  
- **错误信息**：
  - `"参数错误: ..."`：请求参数验证失败
  - `"不支持的支付方式"`：method不是alipay或wechat
  - `"未知的订单类型"`：type不是reservation/parking/violation
  - `"订单不存在"` / `"停车记录不存在"` / `"违规记录不存在"`：对应的业务记录不存在
  - `"订单已支付"`：预订订单已支付
  - `"订单已取消"`：预订订单已取消
  - `"罚款已处理"`：违规记录已处理
  - `"订单金额为0，请确认金额"` / `"停车费用为0，请确认金额"` / `"罚款金额为0，请确认金额"`：金额无效
  - `"创建支付记录失败"`：数据库操作失败

### 2. 模拟支付回调

- **URL**：`POST /api/payment/notify`
- **处理函数**：`payment.Handler.NotifyHandler`
- **请求体**：
  ```json
  {
    "payment_id": 2001,        // 必填，支付记录ID
    "amount": 30.0,             // 必填，支付金额
    "transaction_no": "202501020001",  // 必填，第三方支付平台交易号
    "provider": "alipay"        // 必填，"alipay" | "wechat"
  }
  ```
- **响应**（成功，HTTP 200）：
  ```json
  {
    "code": 0,
    "message": "success",
    "payment_id": 2001
  }
  ```
- **错误响应**（HTTP 400）：
  ```json
  {
    "code": 400,
    "message": "参数错误: ..."  // 或具体业务错误信息
  }
  ```
- **业务逻辑说明**：
  1. **查找支付记录**：根据 `payment_id` 查找支付记录
  2. **检查状态**：如果支付记录已支付（payment_status=1），直接返回成功
  3. **验证交易号**：检查 `transaction_no` 是否已存在（避免重复支付）
  4. **更新支付记录**：
     - 设置 payment_status=1（已支付）
     - 更新 transaction_no、method、amount
     - 设置 pay_time 为当前时间
  5. **更新业务记录**（根据TransactionNo前缀判断支付类型）：
     - **违规支付**（TransactionNo前缀为`PENDING_VIO_`）：优先查找ViolationRecord，更新违规记录的 status=1（已处理）
     - **预订支付**：查找ReservationOrder，调用 `bookingSvc.PayBooking` 更新订单状态
     - **停车支付**：查找ParkingRecord，更新停车记录的 payment_status=1 和 fee_paid
     - **兜底查找**：如果通过前缀无法判断，按顺序查找：ReservationOrder → ParkingRecord → ViolationRecord
  6. **返回结果**：即使未找到任何关联业务记录，只要支付记录已更新为已支付状态，仍然返回成功（支付已完成，不应阻止支付流程）
- **错误信息**：
  - `"参数错误: ..."`：请求参数验证失败
  - `"支付记录不存在"`：payment_id 对应的支付记录不存在
  - `"查询支付记录失败"`：数据库查询失败
  - `"交易号已存在"`：transaction_no 已被其他支付记录使用
  - `"更新支付记录失败"`：支付记录更新失败
  - `"更新停车记录失败"`：停车记录更新失败
  - `"支付记录已更新，但订单更新失败: ..."`：支付记录已更新，但预订订单更新失败
  - 注意：如果未找到关联的业务记录，支付记录仍然会更新为已支付状态，接口返回成功（支付已完成）
- **说明**：
  - 一般由模拟支付页面调用，实际生产环境由第三方支付平台回调
  - 内部会更新 `payment_record` 状态以及关联订单的支付状态
  - 如果支付记录已支付，直接返回成功（幂等性保证）
  - 业务记录查找顺序：ParkingRecord → ReservationOrder → ViolationRecord

---

## 九、模型字段（简要参考）

> 以下仅列出 QT6 前端可能经常用到的几个核心结构字段，完整定义请参考 `internal/model/models.go`。

- **User（Users_list）**
  - `user_id`，`username`，`phone`，`email`，`real_name`，`status`

- **Vehicle**
  - `vehicle_id`，`user_id`，`license_plate`，`brand`，`model`，`color`

- **ParkingLot**
  - `lot_id`，`name`，`address`，`total_levels`，`total_spaces`，`hourly_rate`，`status`

- **ParkingSpace**
  - `space_id`，`lot_id`，`level`，`space_number`，`space_type`，`is_occupied`，`is_reserved`，`status`

- **ReservationOrder**
  - `order_id`，`user_id`，`vehicle_id`，`space_id`，`lot_id`，
  - `start_time`，`end_time`，`status`（0 已取消 / 1 已预订 / 2 使用中 / 3 已完成），
  - `total_fee`，`paid_fee`，`payment_status`（0 未支付 / 1 已支付），`reservation_cod`

- **ParkingRecord**
  - `record_id`，`user_id`，`vehicle_id`，`space_id`，`lot_id`，
  - `entry_time`，`exit_time`，`duration_minute`，
  - `fee_calculated`，`fee_paid`，`payment_status`，`record_status`（1 在场 / 2 已出场），
  - `is_violation`，`violation_reason`

- **ViolationRecord**
  - `violation_id`，`record_id`，`user_id`，`vehicle_id`，
  - `violation_type`，`violation_time`，`description`，`fine_amount`，`status`

- **PaymentRecord**
  - `payment_id`，`order_id`，`user_id`，`amount`，`method`，`transaction_no`，
  - `payment_status`，`pay_time`，`refund_time`

---

## 十、QT6 前端集成建议

- **统一 API 封装**
  - 建议在 QT6 中封装一个 `ApiClient`，对上层提供：`login/register/booking/parking/payment/violation` 等高层方法。
- **错误处理**
  - 注意区分 HTTP 状态码与 JSON 内的 `code` 字段（例如 booking/payment 模块）。
- **鉴权 Token 管理**
  - 普通用户与管理员使用不同的 JWT（不同的签名 secret），前端需分别保存与携带。
- **时间处理**
  - QT 前端建议统一使用 UTC 或带时区时间字符串与后端交互，避免本地时区引起的偏差。


