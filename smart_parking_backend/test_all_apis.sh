#!/bin/bash
# 智能停车后端API自动化测试脚本

BASE_URL="http://localhost:8080"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_RESULTS=()

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local headers="$5"
    local expected_status="${6:-200}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local url="${BASE_URL}${endpoint}"
    local response
    local status_code
    
    echo -n "测试: $name ... "
    
    if [ "$method" = "GET" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "$headers" "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" "$url" 2>&1)
        fi
    elif [ "$method" = "POST" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -H "$headers" -d "$data" "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -d "$data" "$url" 2>&1)
        fi
    elif [ "$method" = "PATCH" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -H "$headers" -X PATCH -d "$data" "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -X PATCH -d "$data" "$url" 2>&1)
        fi
    elif [ "$method" = "DELETE" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "$headers" -X DELETE "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X DELETE "$url" 2>&1)
        fi
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (Status: $status_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("PASS: $name")
        echo "$body" | head -c 200
        echo ""
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (期望: $expected_status, 实际: $status_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("FAIL: $name - Status: $status_code")
        echo "响应: $body" | head -c 200
        echo ""
        return 1
    fi
}

echo "============================================================"
echo "开始测试智能停车后端所有API接口"
echo "============================================================"
echo ""

# 全局变量
USER_TOKEN=""
ADMIN_TOKEN=""
USER_ID=""
ADMIN_ID=""
LOT_ID=""
SPACE_ID=""
ORDER_ID=""
VEHICLE_ID=""
VIOLATION_ID=""
PAYMENT_ID=""
PHONE=""
LICENSE_PLATE=""

# ==================== 1. 用户模块测试 ====================
echo -e "${YELLOW}【1. 用户模块测试】${NC}"
echo "------------------------------------------------------------"

# 1.1 用户注册
TIMESTAMP=$(date +%s)
PHONE="138$((TIMESTAMP % 100000000))"
LICENSE_PLATE="粤A$((TIMESTAMP % 10000))"
REGISTER_DATA="{\"users_list\":{\"username\":\"testuser_${TIMESTAMP}\",\"password\":\"123456\",\"phone\":\"${PHONE}\",\"email\":\"test@example.com\",\"real_name\":\"测试用户\"},\"vehicles\":[{\"license_plate\":\"${LICENSE_PLATE}\",\"brand\":\"测试品牌\",\"model\":\"测试型号\",\"color\":\"白色\"}]}"

RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$REGISTER_DATA" "${BASE_URL}/api/v1/register")
USER_ID=$(echo "$RESPONSE" | grep -o '"user_id":[0-9]*' | grep -o '[0-9]*' | head -1)
test_api "用户注册" "POST" "/api/v1/register" "$REGISTER_DATA" "" 200

# 1.2 发送登录验证码
SEND_CODE_DATA="{\"phone\":\"${PHONE}\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$SEND_CODE_DATA" "${BASE_URL}/api/v1/send_code")
CODE=$(echo "$RESPONSE" | grep -o '"code":"[0-9]*"' | grep -o '[0-9]*' | head -1)
test_api "发送登录验证码" "POST" "/api/v1/send_code" "$SEND_CODE_DATA" "" 200

# 1.3 用户登录（密码登录）
LOGIN_DATA="{\"phone\":\"${PHONE}\",\"password\":\"123456\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$LOGIN_DATA" "${BASE_URL}/api/v1/login")
USER_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 | head -1)
if [ -z "$USER_ID" ]; then
    USER_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
fi
test_api "用户登录（密码）" "POST" "/api/v1/login" "$LOGIN_DATA" "" 200

# 1.4 用户登录（验证码登录）
if [ -n "$CODE" ]; then
    LOGIN_CODE_DATA="{\"phone\":\"${PHONE}\",\"code\":\"${CODE}\"}"
    RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$LOGIN_CODE_DATA" "${BASE_URL}/api/v1/login")
    if [ -z "$USER_TOKEN" ]; then
        USER_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 | head -1)
    fi
    test_api "用户登录（验证码）" "POST" "/api/v1/login" "$LOGIN_CODE_DATA" "" 200
fi

# 1.5 获取用户支付记录（需要认证）
if [ -n "$USER_TOKEN" ]; then
    test_api "获取用户支付记录" "GET" "/api/v1/getpaymentinfo?page=1&page_size=10" "" "Authorization: Bearer ${USER_TOKEN}" 200
fi

# ==================== 2. 管理员模块测试 ====================
echo ""
echo -e "${YELLOW}【2. 管理员模块测试】${NC}"
echo "------------------------------------------------------------"

# 2.1 管理员注册
ADMIN_PHONE="139$((TIMESTAMP % 100000000))"
ADMIN_REGISTER_DATA="{\"phone\":\"${ADMIN_PHONE}\",\"password\":\"123456\",\"lot_id\":1,\"role\":\"lot_admin\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$ADMIN_REGISTER_DATA" "${BASE_URL}/admin/register")
ADMIN_ID=$(echo "$RESPONSE" | grep -o '"admin_id":[0-9]*' | grep -o '[0-9]*' | head -1)
LOT_ID=$(echo "$RESPONSE" | grep -o '"lot_id":[0-9]*' | grep -o '[0-9]*' | head -1)
test_api "管理员注册" "POST" "/admin/register" "$ADMIN_REGISTER_DATA" "" 200

# 2.2 管理员登录
ADMIN_LOGIN_DATA="{\"phone\":\"${ADMIN_PHONE}\",\"password\":\"123456\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$ADMIN_LOGIN_DATA" "${BASE_URL}/admin/login")
ADMIN_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 | head -1)
if [ -z "$LOT_ID" ]; then
    LOT_ID=$(echo "$RESPONSE" | grep -o '"lot_id":[0-9]*' | grep -o '[0-9]*' | head -1)
fi
if [ -z "$LOT_ID" ]; then
    LOT_ID=1
fi
test_api "管理员登录" "POST" "/admin/login" "$ADMIN_LOGIN_DATA" "" 200

# 2.3 车位使用率分析（需要管理员认证）
if [ -n "$ADMIN_TOKEN" ]; then
    START_TIME=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2025-01-01T00:00:00Z")
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2025-01-08T00:00:00Z")
    test_api "车位使用率分析" "GET" "/admin/occupancy?start_time=${START_TIME}&end_time=${END_TIME}" "" "Authorization: Bearer ${ADMIN_TOKEN}" 200
fi

# 2.4 违规行为分析（需要管理员认证）
if [ -n "$ADMIN_TOKEN" ]; then
    YEAR=$(date +%Y)
    MONTH=$(date +%m)
    test_api "违规行为分析" "GET" "/admin/violations?year=${YEAR}&month=${MONTH}" "" "Authorization: Bearer ${ADMIN_TOKEN}" 200
fi

# 2.5 报表生成（需要管理员认证）
if [ -n "$ADMIN_TOKEN" ]; then
    YEAR=$(date +%Y)
    MONTH=$(date +%m)
    test_api "报表生成" "GET" "/admin/report?type=monthly&year=${YEAR}&month=${MONTH}" "" "Authorization: Bearer ${ADMIN_TOKEN}" 200
fi

# ==================== 3. 停车场模块测试 ====================
echo ""
echo -e "${YELLOW}【3. 停车场模块测试】${NC}"
echo "------------------------------------------------------------"

# 3.1 添加停车场
PARKING_LOT_DATA="{\"name\":\"测试停车场_${TIMESTAMP}\",\"address\":\"测试地址123号\",\"total_levels\":3,\"total_spaces\":200,\"hourly_rate\":5.0,\"status\":1,\"description\":\"测试停车场描述\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$PARKING_LOT_DATA" "${BASE_URL}/api/v2/addparkinglot")
NEW_LOT_ID=$(echo "$RESPONSE" | grep -o '"lot_id":[0-9]*' | grep -o '[0-9]*' | head -1)
if [ -n "$NEW_LOT_ID" ]; then
    LOT_ID=$NEW_LOT_ID
fi
test_api "添加停车场" "POST" "/api/v2/addparkinglot" "$PARKING_LOT_DATA" "" 200

# 3.2 获取所有停车场
test_api "获取所有停车场" "GET" "/api/v2/getparkinglots" "" "" 200

# 3.3 获取指定停车场详情
if [ -n "$LOT_ID" ]; then
    test_api "获取停车场详情" "GET" "/api/v2/getparkinglot/${LOT_ID}" "" "" 200
fi

# 3.4 添加车位
if [ -n "$LOT_ID" ]; then
    SPACE_DATA="{\"lot_id\":${LOT_ID},\"level\":1,\"space_number\":\"A-$((TIMESTAMP % 1000))\",\"space_type\":\"普通\",\"status\":1}"
    RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$SPACE_DATA" "${BASE_URL}/api/v2/addparkingspace")
    SPACE_ID=$(echo "$RESPONSE" | grep -o '"space_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "添加车位" "POST" "/api/v2/addparkingspace" "$SPACE_DATA" "" 200
fi

# 3.5 更新车位状态
if [ -n "$SPACE_ID" ]; then
    UPDATE_DATA="{\"status\":1,\"is_occupied\":0,\"is_reserved\":0}"
    test_api "更新车位状态" "PATCH" "/api/v2/updatespacestatus/${SPACE_ID}" "$UPDATE_DATA" "" 200
fi

# 3.6 获取指定停车场下所有车位
if [ -n "$LOT_ID" ]; then
    test_api "获取停车场车位列表" "GET" "/api/v2/getspacesbylotid/${LOT_ID}" "" "" 200
fi

# ==================== 4. 预订模块测试 ====================
echo ""
echo -e "${YELLOW}【4. 预订模块测试】${NC}"
echo "------------------------------------------------------------"

# 4.1 创建预订
if [ -n "$USER_ID" ] && [ -n "$LOT_ID" ]; then
    START_TIME=$(date -u -d "1 hour" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v+1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2025-12-01T10:00:00Z")
    END_TIME=$(date -u -d "3 hours" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v+3H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2025-12-01T12:00:00Z")
    BOOKING_DATA="{\"user_id\":${USER_ID},\"vehicle_id\":1,\"lot_id\":${LOT_ID},\"start_time\":\"${START_TIME}\",\"end_time\":\"${END_TIME}\"}"
    RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$BOOKING_DATA" "${BASE_URL}/api/v4/booking/create")
    ORDER_ID=$(echo "$RESPONSE" | grep -o '"order_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "创建预订" "POST" "/api/v4/booking/create" "$BOOKING_DATA" "" 200
fi

# 4.2 获取用户预订列表
if [ -n "$USER_ID" ]; then
    test_api "获取用户预订列表" "GET" "/api/v4/booking/user?user_id=${USER_ID}" "" "" 200
fi

# 4.3 获取预订详情
if [ -n "$ORDER_ID" ]; then
    test_api "获取预订详情" "GET" "/api/v4/booking/detail/${ORDER_ID}" "" "" 200
fi

# 4.4 取消预订
if [ -n "$ORDER_ID" ]; then
    test_api "取消预订" "DELETE" "/api/v4/booking/cancel/${ORDER_ID}" "" "" 200
fi

# ==================== 5. 停车模块测试 ====================
echo ""
echo -e "${YELLOW}【5. 停车模块测试】${NC}"
echo "------------------------------------------------------------"

# 5.1 获取车位类型
test_api "获取车位类型" "GET" "/api/parking/space-types" "" "" 200

# 5.2 获取停车场车位信息
if [ -n "$LOT_ID" ]; then
    test_api "获取停车场车位信息" "GET" "/api/parking/lots/${LOT_ID}/spaces" "" "" 200
fi

# 5.3 根据车牌号获取车辆信息
if [ -n "$LICENSE_PLATE" ]; then
    test_api "根据车牌获取车辆信息" "GET" "/api/parking/getlicense/${LICENSE_PLATE}" "" "" 200
fi

# 5.4 获取停车场占用情况
if [ -n "$LOT_ID" ]; then
    test_api "获取停车场占用情况" "GET" "/api/parking/getparkinglotoccupancy/${LOT_ID}" "" "" 200
fi

# 5.5 获取用户在场停车记录
if [ -n "$USER_ID" ]; then
    test_api "获取用户在场停车记录" "GET" "/api/parking/${USER_ID}/active-parking" "" "" 200
fi

# 5.6 车辆入场
if [ -n "$LICENSE_PLATE" ]; then
    ENTRY_DATA="{\"license_plate\":\"${LICENSE_PLATE}\",\"space_type\":\"普通\"}"
    test_api "车辆入场" "POST" "/api/parking/entry" "$ENTRY_DATA" "" 200
fi

# 5.7 车辆出场
if [ -n "$LICENSE_PLATE" ]; then
    EXIT_DATA="{\"license_plate\":\"${LICENSE_PLATE}\"}"
    RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$EXIT_DATA" "${BASE_URL}/api/parking/exit")
    PAYMENT_ID=$(echo "$RESPONSE" | grep -o '"payment_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "车辆出场" "POST" "/api/parking/exit" "$EXIT_DATA" "" 200
fi

# ==================== 6. 违规模块测试 ====================
echo ""
echo -e "${YELLOW}【6. 违规模块测试】${NC}"
echo "------------------------------------------------------------"

# 6.1 检查违规行为
test_api "检查违规行为" "POST" "/api/violations/check" "{\"check_type\":1}" "" 200

# 6.2 获取用户违规记录
if [ -n "$USER_ID" ]; then
    RESPONSE=$(curl -s "${BASE_URL}/api/violations/checkmyself/${USER_ID}")
    VIOLATION_ID=$(echo "$RESPONSE" | grep -o '"violation_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "获取用户违规记录" "GET" "/api/violations/checkmyself/${USER_ID}" "" "" 200
fi

# 6.3 支付罚款
if [ -n "$VIOLATION_ID" ]; then
    RESPONSE=$(curl -s -H "Content-Type: application/json" -X POST "${BASE_URL}/api/violations/${VIOLATION_ID}/pay")
    PAYMENT_ID=$(echo "$RESPONSE" | grep -o '"payment_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "支付罚款" "POST" "/api/violations/${VIOLATION_ID}/pay" "" "" 200
fi

# ==================== 7. 支付模块测试 ====================
echo ""
echo -e "${YELLOW}【7. 支付模块测试】${NC}"
echo "------------------------------------------------------------"

# 7.1 创建支付
if [ -n "$ORDER_ID" ]; then
    PAYMENT_DATA="{\"order_id\":${ORDER_ID},\"type\":\"reservation\",\"method\":\"alipay\",\"amount\":30.0}"
    RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$PAYMENT_DATA" "${BASE_URL}/api/payment/create")
    PAYMENT_ID=$(echo "$RESPONSE" | grep -o '"payment_id":[0-9]*' | grep -o '[0-9]*' | head -1)
    test_api "创建支付" "POST" "/api/payment/create" "$PAYMENT_DATA" "" 200
fi

# 7.2 支付回调
if [ -n "$PAYMENT_ID" ]; then
    NOTIFY_DATA="{\"payment_id\":${PAYMENT_ID},\"amount\":30.0,\"transaction_no\":\"TXN${TIMESTAMP}\",\"provider\":\"alipay\"}"
    test_api "支付回调" "POST" "/api/payment/notify" "$NOTIFY_DATA" "" 200
fi

# ==================== 测试结果汇总 ====================
echo ""
echo "============================================================"
echo "测试结果汇总"
echo "============================================================"
echo ""
echo "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS ✓${NC}"
echo -e "${RED}失败: $FAILED_TESTS ✗${NC}"
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
    echo "通过率: ${PASS_RATE}%"
fi

if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo "失败的测试:"
    echo "------------------------------------------------------------"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == FAIL:* ]]; then
            echo -e "${RED}$result${NC}"
        fi
    done
fi

echo ""
echo "============================================================"

exit $FAILED_TESTS

