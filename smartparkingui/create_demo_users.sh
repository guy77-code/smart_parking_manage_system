#!/bin/bash

# 创建演示用户和管理员的脚本

BASE_URL="http://127.0.0.1:8080"
TIMESTAMP=$(date +%s)

echo "=========================================="
echo "创建演示用户和管理员"
echo "=========================================="
echo ""

# 创建演示用户1
echo "1. 创建演示用户1..."
USER1_PHONE="1380000$(echo $TIMESTAMP | tail -c 4)"
USER1_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"users_list\": {
      \"username\": \"demo_user1\",
      \"password\": \"demo123456\",
      \"phone\": \"$USER1_PHONE\",
      \"email\": \"demo1@example.com\"
    },
    \"vehicles\": [{
      \"license_plate\": \"粤A12345\"
    }]
  }")

if echo "$USER1_RESPONSE" | grep -q "user_id"; then
    echo "✅ 用户1创建成功"
    echo "   手机号: $USER1_PHONE"
    echo "   密码: demo123456"
    echo "   车牌号: 粤A12345"
else
    echo "❌ 用户1创建失败: $USER1_RESPONSE"
fi
echo ""

# 创建演示用户2
echo "2. 创建演示用户2..."
USER2_PHONE="1380001$(echo $TIMESTAMP | tail -c 4)"
USER2_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"users_list\": {
      \"username\": \"demo_user2\",
      \"password\": \"demo123456\",
      \"phone\": \"$USER2_PHONE\",
      \"email\": \"demo2@example.com\"
    },
    \"vehicles\": [{
      \"license_plate\": \"粤B67890\"
    }]
  }")

if echo "$USER2_RESPONSE" | grep -q "user_id"; then
    echo "✅ 用户2创建成功"
    echo "   手机号: $USER2_PHONE"
    echo "   密码: demo123456"
    echo "   车牌号: 粤B67890"
else
    echo "❌ 用户2创建失败: $USER2_RESPONSE"
fi
echo ""

# 获取停车场ID
echo "3. 获取停车场列表..."
LOT_RESPONSE=$(curl -s "$BASE_URL/api/v2/getparkinglots")
LOT_ID=$(echo "$LOT_RESPONSE" | grep -o '"lot_id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$LOT_ID" ]; then
    echo "✅ 找到停车场，ID: $LOT_ID"
else
    echo "⚠️  未找到停车场，使用默认ID: 1"
    LOT_ID=1
fi
echo ""

# 创建系统管理员
echo "4. 创建系统管理员..."
ADMIN_SYSTEM_PHONE="1390000$(echo $TIMESTAMP | tail -c 4)"
ADMIN_SYSTEM_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": \"$ADMIN_SYSTEM_PHONE\",
    \"password\": \"admin123456\",
    \"role\": \"system\"
  }")

if echo "$ADMIN_SYSTEM_RESPONSE" | grep -q "admin_id"; then
    echo "✅ 系统管理员创建成功"
    echo "   手机号: $ADMIN_SYSTEM_PHONE"
    echo "   密码: admin123456"
    echo "   角色: system"
else
    echo "❌ 系统管理员创建失败: $ADMIN_SYSTEM_RESPONSE"
fi
echo ""

# 创建停车场管理员
echo "5. 创建停车场管理员..."
ADMIN_LOT_PHONE="1390001$(echo $TIMESTAMP | tail -c 4)"
ADMIN_LOT_RESPONSE=$(curl -s -X POST "$BASE_URL/admin/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": \"$ADMIN_LOT_PHONE\",
    \"password\": \"admin123456\",
    \"role\": \"lot_admin\",
    \"lot_id\": $LOT_ID
  }")

if echo "$ADMIN_LOT_RESPONSE" | grep -q "admin_id"; then
    echo "✅ 停车场管理员创建成功"
    echo "   手机号: $ADMIN_LOT_PHONE"
    echo "   密码: admin123456"
    echo "   角色: lot_admin"
    echo "   管理停车场ID: $LOT_ID"
else
    echo "❌ 停车场管理员创建失败: $ADMIN_LOT_RESPONSE"
fi
echo ""

echo "=========================================="
echo "演示账号信息汇总"
echo "=========================================="
echo ""
echo "【普通用户账号1】"
echo "  手机号: $USER1_PHONE"
echo "  密码: demo123456"
echo "  车牌号: 粤A12345"
echo ""
echo "【普通用户账号2】"
echo "  手机号: $USER2_PHONE"
echo "  密码: demo123456"
echo "  车牌号: 粤B67890"
echo ""
echo "【系统管理员账号】"
echo "  手机号: $ADMIN_SYSTEM_PHONE"
echo "  密码: admin123456"
echo ""
echo "【停车场管理员账号】"
echo "  手机号: $ADMIN_LOT_PHONE"
echo "  密码: admin123456"
echo ""
echo "=========================================="
echo "请在Qt应用中使用以上账号进行测试"
echo "=========================================="

