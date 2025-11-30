> 本文档说明各功能模块的前端逻辑及对应的后端接口调用。所有接口详情请参考 `API_DOCUMENT.md`。

---

## 一、登录界面

### 1. 用户登录
**功能描述**：停车场用户、系统管理员、停车场管理员输入电话号码和密码进行登录。

**接口调用**：
- 普通用户登录：`POST /api/v1/login`
  - 请求体：`{ "phone": "手机号", "password": "密码" }` 或 `{ "phone": "手机号", "code": "验证码" }`
  - 响应包含：`user` 对象、`token`（JWT）
- 管理员登录：`POST /admin/login`
  - 请求体：`{ "phone": "手机号", "password": "密码" }`
  - 响应包含：`role`（"system" 或 "lot_admin"）、`token`、`admin_info`

**逻辑流程**：
1. 用户输入手机号和密码，点击登录按钮
2. 前端根据用户类型调用对应接口（用户用 `/api/v1/login`，管理员用 `/admin/login`）
3. 根据响应中的 `role` 字段判断用户角色：
   - 普通用户：跳转到用户界面
   - `role: "system"`：跳转到系统管理员界面
   - `role: "lot_admin"`：跳转到停车场管理员界面
4. 保存 `token` 到本地存储，后续请求在请求头中携带 `Authorization: Bearer {token}`

### 2. 用户注册
**功能描述**：停车场用户进行注册（系统管理员已预设，停车场管理员由系统管理员添加）。

**接口调用**：
- 用户注册：`POST /api/v1/register`
  - 请求体：`{ "users_list": { "username", "password", "phone", "email", "real_name" }, "vehicles": [{ "license_plate", "brand", "model", "color" }] }`
  - 说明：支持一次注册绑定多辆车

**逻辑流程**：
1. 用户点击注册按钮，跳转到注册页面
2. 用户填写用户名、密码、手机号、邮箱、真实姓名等信息
3. 至少添加一辆车辆信息（车牌号必填，品牌、型号、颜色可选）
4. 点击提交，调用注册接口
5. 注册成功后返回登录页面或直接登录

### 3. 发送验证码（可选）
**功能描述**：用户忘记密码时可通过验证码登录。

**接口调用**：
- `POST /api/v1/send_code`
  - 请求体：`{ "phone": "手机号" }`
  - 响应包含：`code`（开发环境可见）、`expires_in`（有效期秒数）

---

## 二、用户界面

### 1. 停车状态显示与操作
**功能描述**：显示当前是否有车辆停在停车场，提供"停车"和"离开"按钮。

**接口调用**：
- 查询当前在场停车记录：`GET /api/parking/:user_id/active-parking`
  - 路径参数：`user_id`（必填，从登录响应或 token 中获取）
  - 响应（成功，HTTP 200）：`[]ParkingRecord` 数组，包含完整字段：
    - `record_id`、`user_id`、`vehicle_id`、`space_id`、`lot_id`
    - `vehicle`：车辆信息（`license_plate`、`brand`、`model`、`color`）
    - `space`：车位信息（`space_number`、`space_type`、`is_occupied`、`is_reserved`）
    - `lot`：停车场信息（`name`、`address`、`hourly_rate`）
    - `entry_time`、`exit_time`、`duration_minute`、`fee_calculated`、`fee_paid`、`payment_status`、`record_status` 等
  - 错误响应：
    - HTTP 400：用户ID为空或无效
    - HTTP 404：未找到在场停车记录
    - HTTP 500：查询停车记录失败

**逻辑流程**：
- **显示逻辑**：
  - 调用接口查询当前在场停车记录
  - 如果有记录（HTTP 200）：显示"当前有车辆停在停车场"，显示车牌号（`vehicle.license_plate`）、停车场名称（`lot.name`）、入场时间（`entry_time`）、车位编号（`space.space_number`）等信息，显示"离开"按钮
  - 如果没有记录（HTTP 404）：显示"当前暂无车辆在使用停车场"，显示"停车"按钮
  - 如果发生错误（HTTP 400/500）：显示错误提示信息

- **停车操作**：
  1. 用户点击"停车"按钮
  2. 调用 `GET /api/v2/getparkinglots` 获取所有停车场列表
  3. 弹出停车场选择页面，显示附近停车场信息（名称、地址、收费标准、可用车位数等）
  4. 用户选择停车场后，可查看该停车场的车位可视化界面（见"模拟停车界面"）
  5. 用户确认后，调用 `POST /api/parking/entry`
     - 请求体：`{ "license_plate": "车牌号", "space_type": "普通" }`
  6. 接口返回停车记录信息（`record_id`、`space_id`、`space_number`、`lot_name`、`entry_time` 等）
  7. 显示"停车成功"提示，更新页面显示当前停车状态

- **离开操作**：
  1. 用户点击"离开"按钮
  2. 调用 `POST /api/parking/exit`
     - 请求体：`{ "license_plate": "车牌号" }`（必填）
  3. **成功响应**（HTTP 200）：
     - 返回费用信息：
       - `record_id`：停车记录ID
       - `space_id`、`space_number`：车位信息
       - `lot_name`：停车场名称
       - `entry_time`、`exit_time`：入场和出场时间
       - `duration_hours`：停车时长（小时）
       - `total_fee`：总费用（停车费 + 违规罚款）
       - `is_violation`：是否有违规（true/false）
       - `violation_fee`：违规罚款金额
       - `payment_url`：支付链接（格式：`http://127.0.0.1:8081/simulate_payment?provider={method}&payment_id={payment_id}`）
  4. **错误处理**：
     - HTTP 400：无效的请求参数（车牌号为空），显示错误提示
     - HTTP 404：未找到在场停车记录，显示"当前没有车辆在停车场"提示
     - HTTP 500：服务器错误（查询失败、更新失败、释放车位失败等），显示错误提示并记录日志
  5. 如果成功，跳转到支付页面（使用返回的 `payment_url`）
  6. 支付成功后，返回用户界面，显示"离开成功"提示
  7. 更新页面显示为"当前暂无车辆在使用停车场"（重新调用查询接口）

### 2. 预订信息显示
**功能描述**：显示用户的预订信息，提供预订按钮。

**接口调用**：
- 获取用户预订列表：`GET /api/v4/booking/user?user_id={user_id}`
  - 响应：`{ "code": 0, "message": "success", "data": [ReservationOrder...] }`

**逻辑流程**：
- **显示逻辑**：
  - 调用接口获取用户预订列表
  - 如果有预订：显示预订信息（停车场名称、车位编号、预订时间段、状态等）
  - 如果没有预订：显示"暂无预订信息"，显示"预订"按钮
  - 如果预订已超时（`status=1` 且 `start_time` 已过30分钟）：调用 `POST /api/violations/check`（`check_type=1`）生成违规记录，弹出违规提示

- **预订操作**：
  - 用户点击"预订"按钮，跳转到预订界面（见"预订界面"）

### 3. 订单信息显示
**功能描述**：显示待支付订单和历史停车/支付信息。

**接口调用**：
- 获取用户支付记录：`GET /api/v1/getpaymentinfo?page=1&page_size=10`
  - 查询参数：`page`（页码）、`page_size`（每页数量）
  - 响应：`{ "total": 总数, "page": 页码, "page_size": 每页数量, "records": [PaymentRecord...] }`
  - 说明：返回的记录包含关联的订单信息（`order` 字段）

**逻辑流程**：
- **待支付订单显示**：
  - 从支付记录中筛选 `payment_status=0`（待支付）的记录
  - 显示订单号、金额、支付方式、创建时间等信息
  - 如果没有待支付订单：显示"暂无待支付订单"
  - 点击待支付订单：跳转到支付页面

- **查看历史信息**：
  - 用户点击"查看支付信息和历史停车信息"按钮
  - 跳转到历史信息页面，显示所有支付记录和停车记录（已支付/未支付状态）

- **支付操作**：
  1. 用户点击待支付订单
  2. 选择支付方式（微信/支付宝）
  3. 调用 `POST /api/payment/create`
     - 请求体：
       ```json
       {
         "order_id": 订单ID,        // 必填，对应 reservation/parking/violation 的主键
         "type": "reservation",     // 必填，"reservation" | "parking" | "violation"
         "method": "alipay",        // 必填，"alipay" | "wechat"
         "amount": 30.0             // 可选，不传则使用后端计算的应付金额
       }
       ```
  4. **成功响应**（HTTP 200）：
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
  5. **错误处理**（HTTP 400）：
     - `"参数错误: ..."`：请求参数验证失败，显示错误提示
     - `"不支持的支付方式"`：method 不是 alipay 或 wechat
     - `"未知的订单类型"`：type 不是 reservation/parking/violation
     - `"订单不存在"` / `"停车记录不存在"` / `"违规记录不存在"`：对应的业务记录不存在
     - `"订单已支付"`：预订订单已支付
     - `"订单已取消"`：预订订单已取消
     - `"罚款已处理"`：违规记录已处理
     - `"订单金额为0，请确认金额"` / `"停车费用为0，请确认金额"` / `"罚款金额为0，请确认金额"`：金额无效
     - `"创建支付记录失败"`：数据库操作失败
  6. 如果成功，跳转到模拟支付页面（使用返回的 `redirect_url` 或 `payment_id`）
  7. 支付完成后，返回"已支付成功"提示，更新待支付订单列表（重新调用查询接口）

### 4. 违规记录查看
**功能描述**：用户查看自己的违规记录。

**接口调用**：
- 获取用户违规记录：`GET /api/violations/checkmyself/:user_id?status=0`
  - 路径参数：`user_id`（必填）
  - 查询参数：`status`（可选，0=未处理，1=已处理，不传则返回全部）
  - 响应：`{ "total": 数量, "data": [ViolationRecord...] }`
    - 每条记录包含：`violation_id`、`violation_type`、`violation_time`、`fine_amount`、`status`、`record`、`vehicle`、`user` 等字段

**逻辑流程**：
- 用户点击"查看违规记录"按钮
- 跳转到违规记录页面
- 调用接口获取违规记录列表
- 显示违规类型（`violation_type`）、违规时间（`violation_time`）、罚款金额（`fine_amount`）、处理状态（`status`：0=未处理，1=已处理）等信息
- 如果违规未处理（`status=0`），可点击"支付罚款"按钮
  - 调用 `POST /api/violations/:violation_id/pay`
  - 接口返回：
    ```json
    {
      "violation_id": 1,
      "payment_id": 2001,
      "payment_url": "http://127.0.0.1:8081/simulate_payment?provider=alipay&payment_id=2001"
    }
    ```
  - 跳转到模拟支付页面完成支付（见"模拟支付页面"）
  - 支付成功后，返回违规记录页面，刷新列表显示最新状态

### 5. 退出登录
**功能描述**：用户退出登录，清除本地 token，返回登录界面。

---

## 三、预订界面

**功能描述**：用户进行车位预订操作。

**接口调用**：
- 获取所有停车场：`GET /api/v2/getparkinglots`
- 获取停车场车位信息：`GET /api/parking/lots/:lot_id/spaces` 或 `GET /api/parking/getparkinglotoccupancy/:lot_id`
- 创建预订：`POST /api/v4/booking/create`

**逻辑流程**：
1. 用户从用户界面点击"预订"按钮，跳转到预订界面
2. 调用 `GET /api/v2/getparkinglots` 获取附近停车场列表
3. 显示停车场信息（名称、地址、收费标准、可用车位数等）
4. 用户点击某个停车场
5. 调用 `GET /api/parking/getparkinglotoccupancy/:lot_id` 获取该停车场的车位占用情况
6. 显示车位可视化界面（见"模拟停车界面"），用户可查看车位状态
7. 用户选择车位类型（普通、充电桩、残疾人、VIP等）
8. 用户填写预订开始时间和结束时间（格式：`RFC3339` 或 `"2006-01-02 15:04:05"`）
9. 用户点击"预订"按钮
10. 调用 `POST /api/v4/booking/create`
    - 请求体：`{ "user_id": 用户ID, "vehicle_id": 车辆ID, "lot_id": 停车场ID, "start_time": "开始时间", "end_time": "结束时间" }`
11. 接口返回预订订单信息（`order_id`、`reservation_cod` 等）
12. 显示"预订成功"提示
13. 用户点击"关闭"按钮，返回用户界面
14. 用户界面的预订信息自动更新（重新调用 `GET /api/v4/booking/user`）

---

## 四、模拟停车界面（车位可视化）

**功能描述**：以图形化方式展示停车场的车位状态，用于停车、离开、预订等操作时的可视化选择。

**接口调用**：
- 获取停车场车位列表：`GET /api/parking/lots/:lot_id/spaces`
  - 响应：`[]ParkingSpace` 数组（包含 `space_id`、`space_number`、`level`、`space_type`、`is_occupied`、`is_reserved`、`status` 等）
- 获取车位占用情况：`GET /api/parking/getparkinglotoccupancy/:lot_id`
  - 响应：`{ "lot_id": "ID", "occupancy": [{ "space_type": "类型", "total": 总数, "occupied": 已占用, "available": 可用 }] }`

**显示规则**：
- **车位颜色**：
  - 红色：车位被占用（`is_occupied=1`），显示车牌号
  - 蓝色：车位已被预订（`is_reserved=1`）
  - 黄色：车位处于维修/禁用状态（`status=0`）
  - 绿色：车位可用（`is_occupied=0` 且 `is_reserved=0` 且 `status=1`）
- **车位信息显示**：
  - 车位编号（`space_number`）
  - 车位类型（`space_type`：普通、充电桩、残疾人、VIP等）
- **楼层选择**：
  - 如果停车场有多层（`total_levels > 1`），提供楼层选择下拉框
  - 切换楼层时，只显示该楼层的车位
- **图例**：
  - 在页面上方显示颜色图例，说明各颜色代表的含义

**使用场景**：
- 用户点击"停车"按钮后，选择停车场时显示
- 用户点击"离开"按钮时，可查看当前停车位置
- 用户进行预订时，选择停车场和车位时显示

---

## 五、管理员界面

### 系统管理员界面

**功能描述**：系统管理员管理所有停车场，查看违规统计。

**接口调用**：
- 获取所有停车场：`GET /api/v2/getparkinglots`
- 添加停车场：`POST /api/v2/addparkinglot`
- 获取停车场详情：`GET /api/v2/getparkinglot/:id`
- 违规行为分析：`GET /admin/violations?year=2025&month=1`

**逻辑流程**：

1. **停车场管理**：
   - 页面加载时调用 `GET /api/v2/getparkinglots` 获取所有停车场列表
   - 显示停车场信息（名称、地址、总层数、总车位数、收费标准、状态等）
   - **添加停车场**：
     - 点击"添加停车场"按钮，跳转到添加页面
     - 用户填写停车场信息（名称、地址、总层数、总车位数、小时费率、描述等）
     - 调用 `POST /api/v2/addparkinglot` 提交
     - 显示"添加停车场成功"提示，返回列表页面，刷新列表
   - **删除停车场**：
     - 点击"删除停车场"按钮，弹出确认对话框
     - 确认后调用删除接口（注意：当前 API 文档中未明确删除接口，可能需要后端补充或使用更新状态的方式）

2. **违规统计分析**：
   - 点击"违规分析"按钮
   - 调用 `GET /admin/violations?year=年份&month=月份`
   - 显示违规统计数据（总违规次数、按类型统计、按状态统计、罚款总额、月度趋势等）

3. **退出登录**：
   - 清除管理员 token，返回登录界面

### 停车场管理员界面

**功能描述**：停车场管理员管理指定停车场的车位和查看数据。

**接口调用**：
- 实时车位占用情况：`GET /api/parking/getparkinglotoccupancy/:lot_id`
- 获取停车场车位列表：`GET /api/parking/lots/:lot_id/spaces`
- 更新车位状态：`PATCH /api/v2/updatespacestatus/:id`
- 车位使用率分析：`GET /admin/occupancy?start_time=...&end_time=...`
- 生成报告：`GET /admin/report?type=monthly&year=2025&month=1`

**逻辑流程**：

1. **实时车位占用显示**：
   - 页面加载时调用 `GET /api/parking/getparkinglotoccupancy/:lot_id`（`lot_id` 从登录响应的 `lot_id` 或 token 中获取）
   - 显示车位占用情况（按车位类型统计：总数、已占用、可用）
   - 可定时刷新（如每30秒）以保持实时性

2. **车位状态修改**：
   - 点击"停车位修改"按钮，跳转到修改页面
   - 显示该停车场的所有车位列表（调用 `GET /api/parking/lots/:lot_id/spaces`）
   - 管理员选择要修改的车位，选择状态（`status`：0-禁用，1-可用）、占用状态（`is_occupied`：0-未占用，1-占用）、预订状态（`is_reserved`：0-未预订，1-已预订）
   - 调用 `PATCH /api/v2/updatespacestatus/:id`
     - 请求体：`{ "status": 1, "is_occupied": 0, "is_reserved": 0 }`
   - 显示"修改成功"提示，返回列表

3. **数据查看**：
   - 点击"数据查看"按钮，跳转到数据查看页面（见"停车场管理员查看数据页面"）

4. **退出登录**：
   - 清除管理员 token，返回登录界面


### 停车场管理员查看数据页面

**功能描述**：停车场管理员通过点击数据查看按钮跳转至该页面，该页面主要显示的是该管理员对应的停车场的收入和使用率等数据。

**功能说明：**
1. **车位使用率分析**：管理员可选择时间周期（开始时间和结束时间，格式为 RFC3339），调用接口 `GET /admin/occupancy?start_time=xxx&end_time=xxx` 获取车位使用率、占用情况、收入等统计数据，并通过图表展示。
2. **违规行为分析**：管理员可选择年份和月份，调用接口 `GET /admin/violations?year=xxx&month=xxx` 获取违规统计、违规类型分布、处理情况等数据，并通过图表展示。
3. **报表生成**：管理员可选择报表类型（月度或年度）和时间参数，调用接口 `GET /admin/report?type=monthly&year=xxx&month=xxx` 或 `GET /admin/report?type=annual&year=xxx` 生成综合报告，包含停车统计、违规统计、收入统计、使用率分析、高峰时段分析等，并通过图表展示。

页面提供退出按钮，点击后返回至对应停车场管理员页面。

## 六、模拟支付页面

**功能描述**：根据用户选择的支付方式来生成对应的模拟支付页面，用于完成预订、停车、违规等各类订单的支付。

**接口调用**：
- 创建支付：`POST /api/payment/create`
- 支付回调：`POST /api/payment/notify`

**逻辑流程**：

1. **页面显示**：
   - 显示订单号（`order_id`）、支付金额（`amount`）及支付方式（`method`：微信/支付宝）
   - 如果页面通过 `payment_url` 打开，可从 URL 参数中获取 `payment_id` 和 `provider`

2. **创建支付**（如果未传入 `payment_id`）：
   - 页面加载时，根据订单类型（预订/停车/违规）调用接口 `POST /api/payment/create`
   - 请求参数：
     ```json
     {
       "order_id": 订单ID,        // 必填，预订订单ID/停车记录ID/违规记录ID
       "type": "reservation",     // 必填，"reservation" | "parking" | "violation"
       "method": "alipay",        // 必填，"alipay" | "wechat"
       "amount": 30.0             // 可选，不传则使用后端计算的金额
     }
     ```
   - 成功响应（HTTP 200）：
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
   - 错误处理（HTTP 400）：
     - 显示错误信息（见"订单信息显示"部分的错误处理说明）
     - 如果创建失败，显示错误提示并返回上一页

3. **支付确认**：
   - 用户点击"确认支付"按钮
   - 调用接口 `POST /api/payment/notify` 模拟支付回调
   - 请求参数：
     ```json
     {
       "payment_id": 2001,              // 必填，支付记录ID
       "amount": 30.0,                  // 必填，支付金额
       "transaction_no": "202501020001", // 必填，交易号（可生成随机字符串，如：时间戳+随机数）
       "provider": "alipay"             // 必填，"alipay" | "wechat"
     }
     ```
   - 成功响应（HTTP 200）：
     ```json
     {
       "code": 0,
       "message": "success",
       "payment_id": 2001
     }
     ```
   - 错误处理（HTTP 400）：
     - `"参数错误: ..."`：请求参数验证失败
     - `"支付记录不存在"`：payment_id 对应的支付记录不存在
     - `"查询支付记录失败"`：数据库查询失败
     - `"交易号已存在"`：transaction_no 已被其他支付记录使用
     - `"更新支付记录失败"`：支付记录更新失败
     - `"更新停车记录失败"`：停车记录更新失败（仅停车支付）
     - `"支付记录已更新，但订单更新失败: ..."`：支付记录已更新，但预订订单更新失败（仅预订支付）
     - `"支付已记录，但未找到关联的业务记录（reservation/parking/violation）"`：未找到对应的业务记录
   - 如果支付成功：
     - 显示"支付成功"提示
     - 返回支付成功信号给上一个页面
     - 后端会自动更新支付记录和关联订单的支付状态
   - 如果支付失败：
     - 显示错误提示
     - 允许用户重试或返回上一页

**注意事项**：
- 支付回调接口具有幂等性：如果支付记录已支付（payment_status=1），直接返回成功
- 交易号（transaction_no）必须唯一，建议使用时间戳+随机数生成
- 支付成功后，后端会按顺序查找并更新对应的业务记录：ParkingRecord → ReservationOrder → ViolationRecord


