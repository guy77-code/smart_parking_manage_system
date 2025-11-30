#!/bin/bash

# 前端功能测试脚本
# 测试所有API接口是否正常工作

BASE_URL="http://127.0.0.1:8080"
TEST_USER_PHONE="1380000$(date +%s | tail -c 5)"
TEST_USER_PASSWORD="test123456"
TEST_ADMIN_PHONE="1390000$(date +%s | tail -c 5)"
TEST_ADMIN_PASSWORD="admin123456"
TEST_LICENSE_PLATE="粤A$(date +%s | tail -c 5)"

echo "=========================================="
echo "智能停车系统前端功能测试"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# 测试函数
test_api() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local expected_status=$5
    local use_token=${6:-true}
    
    echo -n "测试: $name ... "
    
    local headers="-H \"Content-Type: application/json\""
    if [ "$use_token" = "true" ] && [ -n "$TOKEN" ]; then
        headers="$headers -H \"Authorization: Bearer $TOKEN\""
    fi
    
    if [ "$method" = "GET" ]; then
        if [ "$use_token" = "true" ] && [ -n "$TOKEN" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
        fi
    else
        if [ "$use_token" = "true" ] && [ -n "$TOKEN" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $TOKEN" \
                -d "$data" \
                "$BASE_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" \
                -H "Content-Type: application/json" \
                -d "$data" \
                "$BASE_URL$endpoint")
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_status" ] || [ -z "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code, 期望: $expected_status)"
        echo "  响应: $body" | head -c 200
        echo ""
        ((FAIL_COUNT++))
        return 1
    fi
}

# 1. 测试用户注册
echo "1. 用户注册测试"
test_api "用户注册" "POST" "/api/v1/register" \
    "{\"users_list\":{\"username\":\"testuser\",\"password\":\"$TEST_USER_PASSWORD\",\"phone\":\"$TEST_USER_PHONE\",\"email\":\"test@example.com\"},\"vehicles\":[{\"license_plate\":\"$TEST_LICENSE_PLATE\"}]}" \
    "200"
echo ""

# 2. 测试发送验证码
echo "2. 发送验证码测试"
test_api "发送验证码" "POST" "/api/v1/send_code" \
    "{\"phone\":\"$TEST_USER_PHONE\"}" \
    "200"
sleep 2
echo ""

# 3. 测试用户登录
echo "3. 用户登录测试"
login_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$TEST_USER_PHONE\",\"password\":\"$TEST_USER_PASSWORD\"}" \
    "$BASE_URL/api/v1/login")

TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
USER_ID=$(echo "$login_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✓ 登录成功${NC}, Token: ${TOKEN:0:20}..., UserID: $USER_ID"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ 登录失败${NC}"
    echo "响应: $login_response"
    ((FAIL_COUNT++))
fi
echo ""

# 4. 测试获取停车场列表
echo "4. 获取停车场列表测试"
test_api "获取停车场列表" "GET" "/api/v2/getparkinglots" "" "200"
LOT_ID=$(curl -s "$BASE_URL/api/v2/getparkinglots" | grep -o '"lot_id":[0-9]*' | head -1 | cut -d':' -f2)
echo "  获取到停车场ID: $LOT_ID"
echo ""

# 5. 测试获取用户在场停车记录
echo "5. 获取用户在场停车记录测试"
test_api "获取用户在场停车记录" "GET" "/api/parking/$USER_ID/active-parking" "" "200"
echo ""

# 6. 测试车辆入场
echo "6. 车辆入场测试"
test_api "车辆入场" "POST" "/api/parking/entry" \
    "{\"license_plate\":\"$TEST_LICENSE_PLATE\"}" \
    "200"
sleep 1
echo ""

# 7. 测试获取用户在场停车记录（应该有记录）
echo "7. 再次获取用户在场停车记录测试"
test_api "获取用户在场停车记录" "GET" "/api/parking/$USER_ID/active-parking" "" "200"
echo ""

# 8. 测试创建预订
echo "8. 创建预订测试"
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "+1 hour")
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ" -d "+3 hours")
VEHICLE_ID=$(echo "$login_response" | grep -o '"vehicles":\[{"vehicle_id":[0-9]*' | grep -o '"vehicle_id":[0-9]*' | cut -d':' -f2)

if [ -z "$VEHICLE_ID" ]; then
    VEHICLE_ID=1
fi

test_api "创建预订" "POST" "/api/v4/booking/create" \
    "{\"user_id\":$USER_ID,\"vehicle_id\":$VEHICLE_ID,\"lot_id\":$LOT_ID,\"start_time\":\"$START_TIME\",\"end_time\":\"$END_TIME\"}" \
    "200"
echo ""

# 9. 测试获取用户预订列表
echo "9. 获取用户预订列表测试"
test_api "获取用户预订列表" "GET" "/api/v4/booking/user?user_id=$USER_ID" "" "200"
echo ""

# 10. 测试获取用户支付记录
echo "10. 获取用户支付记录测试"
# 确保使用用户token
TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
test_api "获取用户支付记录" "GET" "/api/v1/getpaymentinfo?page=1&page_size=10" "" "200"
echo ""

# 11. 测试获取用户违规记录
echo "11. 获取用户违规记录测试"
test_api "获取用户违规记录" "GET" "/api/violations/checkmyself/$USER_ID" "" "200"
echo ""

# 12. 测试车辆出场
echo "12. 车辆出场测试"
# 确保使用用户token
TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
test_api "车辆出场" "POST" "/api/parking/exit" \
    "{\"license_plate\":\"$TEST_LICENSE_PLATE\"}" \
    "200"
echo ""

# 13. 测试管理员注册
echo "13. 管理员注册测试"
test_api "管理员注册" "POST" "/admin/register" \
    "{\"phone\":\"$TEST_ADMIN_PHONE\",\"password\":\"$TEST_ADMIN_PASSWORD\",\"role\":\"lot_admin\",\"lot_id\":$LOT_ID}" \
    "200"
echo ""

# 14. 测试管理员登录
echo "14. 管理员登录测试"
admin_login_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$TEST_ADMIN_PHONE\",\"password\":\"$TEST_ADMIN_PASSWORD\"}" \
    "$BASE_URL/admin/login")

ADMIN_TOKEN=$(echo "$admin_login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
ADMIN_ID=$(echo "$admin_login_response" | grep -o '"admin_id":[0-9]*' | cut -d':' -f2)

if [ -n "$ADMIN_TOKEN" ]; then
    echo -e "${GREEN}✓ 管理员登录成功${NC}, Token: ${ADMIN_TOKEN:0:20}..., AdminID: $ADMIN_ID"
    ((PASS_COUNT++))
    TOKEN=$ADMIN_TOKEN
else
    echo -e "${RED}✗ 管理员登录失败${NC}"
    echo "响应: $admin_login_response"
    ((FAIL_COUNT++))
fi
echo ""

# 15. 测试获取车位使用率分析
echo "15. 获取车位使用率分析测试"
# 使用管理员token
TOKEN=$ADMIN_TOKEN
START_TIME_ANALYSIS=$(date -u +"%Y-%m-%dT00:00:00Z" -d "1 day ago")
END_TIME_ANALYSIS=$(date -u +"%Y-%m-%dT23:59:59Z")
test_api "获取车位使用率分析" "GET" "/admin/occupancy?start_time=$START_TIME_ANALYSIS&end_time=$END_TIME_ANALYSIS" "" "200"
echo ""

# 16. 测试获取违规分析
echo "16. 获取违规分析测试"
# 使用管理员token
TOKEN=$ADMIN_TOKEN
CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
test_api "获取违规分析" "GET" "/admin/violations?year=$CURRENT_YEAR&month=$CURRENT_MONTH" "" "200"
echo ""

# 17. 测试生成报表
echo "17. 生成报表测试"
# 使用管理员token
TOKEN=$ADMIN_TOKEN
test_api "生成月度报表" "GET" "/admin/report?type=monthly&year=$CURRENT_YEAR&month=$CURRENT_MONTH" "" "200"
echo ""

# 总结
echo "=========================================="
echo "测试总结"
echo "=========================================="
echo -e "${GREEN}通过: $PASS_COUNT${NC}"
echo -e "${RED}失败: $FAIL_COUNT${NC}"
echo "总计: $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}部分测试失败，请检查上述错误${NC}"
    exit 1
fi

