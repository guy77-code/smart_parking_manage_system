#!/bin/bash

# 数据生成脚本运行器
# 用于生成50个用户及其相关的停车记录、预订订单、支付记录和违规记录

echo "=========================================="
echo "智能停车系统 - 测试数据生成工具"
echo "=========================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "generate_test_data.go" ]; then
    echo "❌ 错误: 请在 smart_parking_backend 目录下运行此脚本"
    exit 1
fi

# 检查 Go 环境
if ! command -v go &> /dev/null; then
    echo "❌ 错误: 未找到 Go 环境，请先安装 Go"
    exit 1
fi

# 检查配置文件
if [ ! -f "config/config.yaml" ]; then
    echo "❌ 错误: 未找到配置文件 config/config.yaml"
    exit 1
fi

echo "📋 数据生成配置:"
echo "   - 用户数量: 50"
echo "   - 每个用户车辆数: 2"
echo "   - 每个用户停车记录: 2-3条"
echo "   - 每个用户预订订单: 1-2条"
echo "   - 所有用户密码: 12345678"
echo ""
echo "⚠️  警告: 此操作将在数据库中插入大量测试数据"
echo ""
read -p "是否继续? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消操作"
    exit 0
fi

echo ""
echo "🔄 开始编译并运行数据生成程序..."
echo ""

# 编译并运行
go run generate_test_data.go

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 数据生成完成！"
    echo "=========================================="
    echo ""
    echo "提示:"
    echo "  - 所有用户密码均为: 12345678"
    echo "  - 用户名格式: user001, user002, ..., user050"
    echo "  - 手机号格式: 13810000001, 13810000002, ..., 13810000050"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 数据生成失败"
    echo "=========================================="
    echo ""
    echo "请检查:"
    echo "  1. 数据库连接配置是否正确 (config/config.yaml)"
    echo "  2. 数据库服务是否运行"
    echo "  3. 数据库中是否已有停车场和车位数据"
    echo ""
    exit 1
fi

