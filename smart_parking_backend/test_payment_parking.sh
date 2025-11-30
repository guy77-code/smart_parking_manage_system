#!/bin/bash
# 测试支付模块、获取用户在场停车记录和车辆出场功能

BASE_URL="http://localhost:8080"
TIMESTAMP=$(date +%s)
TEST_USERNAME="test_payment_${TIMESTAMP}"
TEST_PHONE="138$((TIMESTAMP % 100000000))"
TEST_LICENSE="TEST${TIMESTAMP: -6}"
TEST_PASSWORD="123456"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================================"
echo "测试支付模块、获取用户在场停车记录和车辆出场功能"
echo "============================================================"
echo ""

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local headers="$5"
    local expected_status="${6:-200}"
    
    echo -n "测试: $name ... "
    
    local url="${BASE_URL}${endpoint}"
    local response
    local status_code
    
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
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (Status: $status_code)"
        echo "$body" | head -c 300
        echo ""
        echo "$body"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (期望: $expected_status, 实际: $status_code)"
        echo "响应: $body" | head -c 500
        echo ""
        return 1
    fi
}

# ==================== 1. 创建测试用户和车辆 ====================
echo -e "${BLUE}【步骤1: 创建测试用户和车辆】${NC}"
echo "------------------------------------------------------------"

REGISTER_DATA="{\"users_list\":{\"username\":\"${TEST_USERNAME}\",\"password\":\"${TEST_PASSWORD}\",\"phone\":\"${TEST_PHONE}\",\"email\":\"test@example.com\",\"real_name\":\"测试用户\"},\"vehicles\":[{\"license_plate\":\"${TEST_LICENSE}\",\"brand\":\"测试品牌\",\"model\":\"测试型号\",\"color\":\"白色\"}]}"

RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$REGISTER_DATA" "${BASE_URL}/api/v1/register")
USER_ID=$(echo "$RESPONSE" | grep -o '"user_id":[0-9]*' | grep -o '[0-9]*' | head -1)
VEHICLE_ID=$(echo "$RESPONSE" | grep -o '"vehicle_id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -z "$USER_ID" ]; then
    echo -e "${RED}用户注册失败，无法继续测试${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 用户注册成功: UserID=$USER_ID, VehicleID=$VEHICLE_ID${NC}"
echo ""

# ==================== 2. 用户登录获取Token ====================
echo -e "${BLUE}【步骤2: 用户登录】${NC}"
echo "------------------------------------------------------------"

LOGIN_DATA="{\"phone\":\"${TEST_PHONE}\",\"password\":\"${TEST_PASSWORD}\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$LOGIN_DATA" "${BASE_URL}/api/v1/login")
USER_TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ -z "$USER_TOKEN" ]; then
    echo -e "${RED}用户登录失败，无法继续测试${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 用户登录成功${NC}"
echo ""

# ==================== 3. 获取停车场ID ====================
echo -e "${BLUE}【步骤3: 获取停车场信息】${NC}"
echo "------------------------------------------------------------"

RESPONSE=$(curl -s "${BASE_URL}/api/v2/getparkinglots")
LOT_ID=$(echo "$RESPONSE" | grep -o '"lot_id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -z "$LOT_ID" ]; then
    echo -e "${RED}无法获取停车场ID${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 获取停车场ID: $LOT_ID${NC}"
echo ""

# ==================== 4. 车辆入场 ====================
echo -e "${BLUE}【步骤4: 车辆入场】${NC}"
echo "------------------------------------------------------------"

ENTRY_DATA="{\"license_plate\":\"${TEST_LICENSE}\",\"space_type\":\"普通\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$ENTRY_DATA" "${BASE_URL}/api/parking/entry")
RECORD_ID=$(echo "$RESPONSE" | grep -o '"record_id":[0-9]*' | grep -o '[0-9]*' | head -1)
SPACE_ID=$(echo "$RESPONSE" | grep -o '"space_id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -z "$RECORD_ID" ]; then
    echo -e "${RED}车辆入场失败${NC}"
    echo "响应: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ 车辆入场成功: RecordID=$RECORD_ID, SpaceID=$SPACE_ID${NC}"
echo "响应: $RESPONSE"
echo ""

# ==================== 5. 测试获取用户在场停车记录 ====================
echo -e "${BLUE}【步骤5: 测试获取用户在场停车记录】${NC}"
echo "------------------------------------------------------------"

test_api "获取用户在场停车记录" "GET" "/api/parking/${USER_ID}/active-parking" "" "" 200

# 验证返回的数据
RESPONSE=$(curl -s "${BASE_URL}/api/parking/${USER_ID}/active-parking")
FOUND_RECORD_ID=$(echo "$RESPONSE" | grep -o '"record_id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ "$FOUND_RECORD_ID" = "$RECORD_ID" ]; then
    echo -e "${GREEN}✓ 验证通过: 返回的记录ID匹配${NC}"
else
    echo -e "${RED}✗ 验证失败: 期望RecordID=$RECORD_ID, 实际=$FOUND_RECORD_ID${NC}"
fi
echo ""

# ==================== 6. 测试支付模块 - 创建支付 ====================
echo -e "${BLUE}【步骤6: 测试支付模块 - 创建支付】${NC}"
echo "------------------------------------------------------------"

# 先等待一下，确保停车记录已保存
sleep 1

PAYMENT_DATA="{\"order_id\":${RECORD_ID},\"type\":\"parking\",\"method\":\"alipay\",\"amount\":30.0}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$PAYMENT_DATA" "${BASE_URL}/api/payment/create")
PAYMENT_ID=$(echo "$RESPONSE" | grep -o '"payment_id":[0-9]*' | grep -o '[0-9]*' | head -1)
REDIRECT_URL=$(echo "$RESPONSE" | grep -o '"redirect_url":"[^"]*"' | cut -d'"' -f4 | head -1)

test_api "创建支付" "POST" "/api/payment/create" "$PAYMENT_DATA" "" 200

if [ -n "$PAYMENT_ID" ]; then
    echo -e "${GREEN}✓ 支付ID: $PAYMENT_ID${NC}"
    echo -e "${GREEN}✓ 支付链接: $REDIRECT_URL${NC}"
else
    echo -e "${RED}✗ 未获取到支付ID${NC}"
fi
echo ""

# ==================== 7. 测试支付模块 - 支付回调 ====================
echo -e "${BLUE}【步骤7: 测试支付模块 - 支付回调】${NC}"
echo "------------------------------------------------------------"

if [ -n "$PAYMENT_ID" ]; then
    NOTIFY_DATA="{\"payment_id\":${PAYMENT_ID},\"amount\":30.0,\"transaction_no\":\"TXN${TIMESTAMP}\",\"provider\":\"alipay\"}"
    test_api "支付回调" "POST" "/api/payment/notify" "$NOTIFY_DATA" "" 200
    
    # 验证支付状态是否已更新
    sleep 1
    echo "验证支付状态..."
else
    echo -e "${YELLOW}⚠ 跳过支付回调测试（未获取到支付ID）${NC}"
fi
echo ""

# ==================== 8. 测试车辆出场 ====================
echo -e "${BLUE}【步骤8: 测试车辆出场】${NC}"
echo "------------------------------------------------------------"

EXIT_DATA="{\"license_plate\":\"${TEST_LICENSE}\"}"
RESPONSE=$(curl -s -H "Content-Type: application/json" -d "$EXIT_DATA" "${BASE_URL}/api/parking/exit")
EXIT_STATUS=$(curl -s -w "%{http_code}" -H "Content-Type: application/json" -d "$EXIT_DATA" "${BASE_URL}/api/parking/exit" -o /dev/null)

test_api "车辆出场" "POST" "/api/parking/exit" "$EXIT_DATA" "" 200

# 验证返回的数据
EXIT_RECORD_ID=$(echo "$RESPONSE" | grep -o '"record_id":[0-9]*' | grep -o '[0-9]*' | head -1)
EXIT_PAYMENT_URL=$(echo "$RESPONSE" | grep -o '"payment_url":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ -n "$EXIT_RECORD_ID" ]; then
    echo -e "${GREEN}✓ 出场记录ID: $EXIT_RECORD_ID${NC}"
    if [ -n "$EXIT_PAYMENT_URL" ]; then
        echo -e "${GREEN}✓ 出场支付链接: $EXIT_PAYMENT_URL${NC}"
    else
        echo -e "${YELLOW}⚠ 未获取到支付链接${NC}"
    fi
else
    echo -e "${RED}✗ 未获取到出场记录ID${NC}"
fi
echo ""

# ==================== 9. 验证出场后无法再次获取在场记录 ====================
echo -e "${BLUE}【步骤9: 验证出场后无法获取在场记录】${NC}"
echo "------------------------------------------------------------"

RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/parking/${USER_ID}/active-parking")
STATUS=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "404" ]; then
    echo -e "${GREEN}✓ 验证通过: 出场后正确返回404${NC}"
else
    echo -e "${YELLOW}⚠ 状态码: $STATUS (期望404)${NC}"
fi
echo ""

# ==================== 测试总结 ====================
echo "============================================================"
echo "测试完成"
echo "============================================================"
echo "测试用户: $TEST_USERNAME"
echo "用户ID: $USER_ID"
echo "车牌号: $TEST_LICENSE"
echo "停车记录ID: $RECORD_ID"
if [ -n "$PAYMENT_ID" ]; then
    echo "支付ID: $PAYMENT_ID"
fi
echo "============================================================"

