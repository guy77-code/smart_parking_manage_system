#!/usr/bin/env python3
"""
智能停车后端API自动化测试脚本
测试所有接口并报告问题
"""

import requests
import json
import time
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

BASE_URL = "http://localhost:8080"
test_results = []
user_token = None
admin_token = None
user_id = None
admin_id = None
lot_id = None
space_id = None
order_id = None
vehicle_id = None
violation_id = None
payment_id = None

def log_test(name: str, method: str, url: str, status: int, success: bool, error: str = ""):
    """记录测试结果"""
    result = {
        "name": name,
        "method": method,
        "url": url,
        "status": status,
        "success": success,
        "error": error,
        "timestamp": datetime.now().isoformat()
    }
    test_results.append(result)
    status_icon = "✅" if success else "❌"
    print(f"{status_icon} {name}: {method} {url} - Status: {status}")
    if error:
        print(f"   错误: {error}")

def test_api(name: str, method: str, endpoint: str, data: Optional[Dict] = None, 
             headers: Optional[Dict] = None, expected_status: int = 200) -> Optional[Dict]:
    """通用API测试函数"""
    url = f"{BASE_URL}{endpoint}"
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, params=data, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=10)
        elif method == "PATCH":
            response = requests.patch(url, json=data, headers=headers, timeout=10)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=10)
        else:
            log_test(name, method, endpoint, 0, False, f"不支持的HTTP方法: {method}")
            return None
        
        success = response.status_code == expected_status
        error = "" if success else f"期望状态码 {expected_status}, 实际 {response.status_code}"
        
        try:
            result = response.json()
        except:
            result = {"raw": response.text[:200]}
            error += f" | 响应不是JSON: {response.text[:100]}"
        
        log_test(name, method, endpoint, response.status_code, success, error)
        return result if success else None
    except Exception as e:
        log_test(name, method, endpoint, 0, False, str(e))
        return None

def main():
    global user_token, admin_token, user_id, admin_id, lot_id, space_id, order_id, vehicle_id, violation_id, payment_id
    
    print("=" * 80)
    print("开始测试智能停车后端所有API接口")
    print("=" * 80)
    print()
    
    # ==================== 1. 用户模块测试 ====================
    print("\n【1. 用户模块测试】")
    print("-" * 80)
    
    # 1.1 用户注册
    register_data = {
        "users_list": {
            "username": f"testuser_{int(time.time())}",
            "password": "123456",
            "phone": f"138{int(time.time()) % 100000000:08d}",
            "email": "test@example.com",
            "real_name": "测试用户"
        },
        "vehicles": [
            {
                "license_plate": f"粤A{int(time.time()) % 10000:04d}",
                "brand": "测试品牌",
                "model": "测试型号",
                "color": "白色"
            }
        ]
    }
    result = test_api("用户注册", "POST", "/api/v1/register", register_data)
    if result:
        user_id = result.get("user_id")
        vehicle_id = result.get("vehicles_registered", [])
        if isinstance(vehicle_id, list) and vehicle_id:
            vehicle_id = vehicle_id[0]
    
    # 1.2 发送登录验证码
    if user_id:
        phone = register_data["users_list"]["phone"]
        result = test_api("发送登录验证码", "POST", "/api/v1/send_code", {"phone": phone})
        code = result.get("code") if result else None
    else:
        code = None
    
    # 1.3 用户登录（密码登录）
    if user_id:
        login_data = {
            "phone": register_data["users_list"]["phone"],
            "password": "123456"
        }
        result = test_api("用户登录（密码）", "POST", "/api/v1/login", login_data)
        if result:
            user_token = result.get("token")
            if not user_id:
                user_id = result.get("user", {}).get("id")
    
    # 1.4 用户登录（验证码登录）
    if code:
        login_code_data = {
            "phone": register_data["users_list"]["phone"],
            "code": code
        }
        result = test_api("用户登录（验证码）", "POST", "/api/v1/login", login_code_data)
        if result and not user_token:
            user_token = result.get("token")
    
    # 1.5 获取用户支付记录（需要认证）
    if user_token:
        headers = {"Authorization": f"Bearer {user_token}"}
        result = test_api("获取用户支付记录", "GET", "/api/v1/getpaymentinfo", 
                         {"page": 1, "page_size": 10}, headers)
    
    # ==================== 2. 管理员模块测试 ====================
    print("\n【2. 管理员模块测试】")
    print("-" * 80)
    
    # 2.1 管理员注册
    admin_register_data = {
        "phone": f"139{int(time.time()) % 100000000:08d}",
        "password": "123456",
        "lot_id": 1,
        "role": "lot_admin"
    }
    result = test_api("管理员注册", "POST", "/admin/register", admin_register_data)
    if result:
        admin_id = result.get("admin", {}).get("admin_id")
        lot_id = result.get("admin", {}).get("lot_id") or 1
    
    # 2.2 管理员登录
    if admin_id:
        admin_login_data = {
            "phone": admin_register_data["phone"],
            "password": "123456"
        }
        result = test_api("管理员登录", "POST", "/admin/login", admin_login_data)
        if result:
            admin_token = result.get("token")
            if not lot_id:
                lot_id = result.get("lot_id") or 1
    
    # 2.3 车位使用率分析（需要管理员认证）
    if admin_token:
        headers = {"Authorization": f"Bearer {admin_token}"}
        end_time = datetime.now()
        start_time = end_time - timedelta(days=7)
        params = {
            "start_time": start_time.isoformat() + "Z",
            "end_time": end_time.isoformat() + "Z"
        }
        result = test_api("车位使用率分析", "GET", "/admin/occupancy", params, headers)
    
    # 2.4 违规行为分析（需要管理员认证）
    if admin_token:
        headers = {"Authorization": f"Bearer {admin_token}"}
        params = {
            "year": datetime.now().year,
            "month": datetime.now().month
        }
        result = test_api("违规行为分析", "GET", "/admin/violations", params, headers)
    
    # 2.5 报表生成（需要管理员认证）
    if admin_token:
        headers = {"Authorization": f"Bearer {admin_token}"}
        params = {
            "type": "monthly",
            "year": datetime.now().year,
            "month": datetime.now().month
        }
        result = test_api("报表生成", "GET", "/admin/report", params, headers)
    
    # ==================== 3. 停车场模块测试 ====================
    print("\n【3. 停车场模块测试】")
    print("-" * 80)
    
    # 3.1 添加停车场
    parking_lot_data = {
        "name": f"测试停车场_{int(time.time())}",
        "address": "测试地址123号",
        "total_levels": 3,
        "total_spaces": 200,
        "hourly_rate": 5.0,
        "status": 1,
        "description": "测试停车场描述"
    }
    result = test_api("添加停车场", "POST", "/api/v2/addparkinglot", parking_lot_data)
    if result:
        lot_id = result.get("data", {}).get("lot_id") or lot_id or 1
    
    # 3.2 获取所有停车场
    result = test_api("获取所有停车场", "GET", "/api/v2/getparkinglots")
    
    # 3.3 获取指定停车场详情
    if lot_id:
        result = test_api("获取停车场详情", "GET", f"/api/v2/getparkinglot/{lot_id}")
    
    # 3.4 添加车位
    if lot_id:
        space_data = {
            "lot_id": lot_id,
            "level": 1,
            "space_number": f"A-{int(time.time()) % 1000:03d}",
            "space_type": "普通",
            "status": 1
        }
        result = test_api("添加车位", "POST", "/api/v2/addparkingspace", space_data)
        if result:
            space_id = result.get("data", {}).get("space_id")
    
    # 3.5 更新车位状态
    if space_id:
        update_data = {
            "status": 1,
            "is_occupied": 0,
            "is_reserved": 0
        }
        result = test_api("更新车位状态", "PATCH", f"/api/v2/updatespacestatus/{space_id}", update_data)
    
    # 3.6 获取指定停车场下所有车位
    if lot_id:
        result = test_api("获取停车场车位列表", "GET", f"/api/v2/getspacesbylotid/{lot_id}")
    
    # ==================== 4. 预订模块测试 ====================
    print("\n【4. 预订模块测试】")
    print("-" * 80)
    
    # 4.1 创建预订
    if user_id and lot_id:
        start_time = datetime.now() + timedelta(hours=1)
        end_time = start_time + timedelta(hours=2)
        booking_data = {
            "user_id": user_id,
            "vehicle_id": vehicle_id or 1,
            "lot_id": lot_id,
            "start_time": start_time.isoformat() + "Z",
            "end_time": end_time.isoformat() + "Z"
        }
        result = test_api("创建预订", "POST", "/api/v4/booking/create", booking_data)
        if result and result.get("code") == 0:
            order_id = result.get("data", {}).get("order_id")
    
    # 4.2 获取用户预订列表
    if user_id:
        result = test_api("获取用户预订列表", "GET", "/api/v4/booking/user", {"user_id": user_id})
    
    # 4.3 获取预订详情
    if order_id:
        result = test_api("获取预订详情", "GET", f"/api/v4/booking/detail/{order_id}")
    
    # 4.4 取消预订
    if order_id:
        result = test_api("取消预订", "DELETE", f"/api/v4/booking/cancel/{order_id}")
    
    # ==================== 5. 停车模块测试 ====================
    print("\n【5. 停车模块测试】")
    print("-" * 80)
    
    # 5.1 获取车位类型
    result = test_api("获取车位类型", "GET", "/api/parking/space-types")
    
    # 5.2 获取停车场车位信息
    if lot_id:
        result = test_api("获取停车场车位信息", "GET", f"/api/parking/lots/{lot_id}/spaces")
    
    # 5.3 根据车牌号获取车辆信息
    if register_data.get("vehicles"):
        license_plate = register_data["vehicles"][0]["license_plate"]
        result = test_api("根据车牌获取车辆信息", "GET", f"/api/parking/getlicense/{license_plate}")
    
    # 5.4 获取停车场占用情况
    if lot_id:
        result = test_api("获取停车场占用情况", "GET", f"/api/parking/getparkinglotoccupancy/{lot_id}")
    
    # 5.5 获取用户在场停车记录
    if user_id:
        result = test_api("获取用户在场停车记录", "GET", f"/api/parking/{user_id}/active-parking")
    
    # 5.6 车辆入场
    if register_data.get("vehicles"):
        license_plate = register_data["vehicles"][0]["license_plate"]
        entry_data = {
            "license_plate": license_plate,
            "space_type": "普通"
        }
        result = test_api("车辆入场", "POST", "/api/parking/entry", entry_data)
    
    # 5.7 车辆出场
    if register_data.get("vehicles"):
        license_plate = register_data["vehicles"][0]["license_plate"]
        exit_data = {
            "license_plate": license_plate
        }
        result = test_api("车辆出场", "POST", "/api/parking/exit", exit_data)
    
    # ==================== 6. 违规模块测试 ====================
    print("\n【6. 违规模块测试】")
    print("-" * 80)
    
    # 6.1 检查违规行为
    result = test_api("检查违规行为", "POST", "/api/violations/check", {"check_type": 1})
    
    # 6.2 获取用户违规记录
    if user_id:
        result = test_api("获取用户违规记录", "GET", f"/api/violations/checkmyself/{user_id}")
        if result:
            violations = result.get("data", [])
            if violations:
                violation_id = violations[0].get("violation_id") if violations else None
    
    # 6.3 支付罚款
    if violation_id:
        result = test_api("支付罚款", "POST", f"/api/violations/{violation_id}/pay")
        if result:
            payment_id = result.get("payment_id")
    
    # ==================== 7. 支付模块测试 ====================
    print("\n【7. 支付模块测试】")
    print("-" * 80)
    
    # 7.1 创建支付
    if order_id:
        payment_data = {
            "order_id": order_id,
            "type": "reservation",
            "method": "alipay",
            "amount": 30.0
        }
        result = test_api("创建支付", "POST", "/api/payment/create", payment_data)
        if result and result.get("code") == 0:
            payment_id = result.get("payment_id") or result.get("data", {}).get("payment_id")
    
    # 7.2 支付回调
    if payment_id:
        notify_data = {
            "payment_id": payment_id,
            "amount": 30.0,
            "transaction_no": f"TXN{int(time.time())}",
            "provider": "alipay"
        }
        result = test_api("支付回调", "POST", "/api/payment/notify", notify_data)
    
    # ==================== 测试结果汇总 ====================
    print("\n" + "=" * 80)
    print("测试结果汇总")
    print("=" * 80)
    
    total = len(test_results)
    passed = sum(1 for r in test_results if r["success"])
    failed = total - passed
    
    print(f"\n总测试数: {total}")
    print(f"通过: {passed} ✅")
    print(f"失败: {failed} ❌")
    print(f"通过率: {passed/total*100:.1f}%")
    
    if failed > 0:
        print("\n失败的测试:")
        print("-" * 80)
        for r in test_results:
            if not r["success"]:
                print(f"❌ {r['name']}: {r['method']} {r['url']}")
                print(f"   状态码: {r['status']}, 错误: {r['error']}")
    
    # 保存详细结果到文件
    with open("test_results.json", "w", encoding="utf-8") as f:
        json.dump({
            "summary": {
                "total": total,
                "passed": passed,
                "failed": failed,
                "pass_rate": f"{passed/total*100:.1f}%"
            },
            "results": test_results
        }, f, ensure_ascii=False, indent=2)
    
    print(f"\n详细测试结果已保存到: test_results.json")
    print("=" * 80)
    
    return failed == 0

if __name__ == "__main__":
    try:
        success = main()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n测试被用户中断")
        exit(1)
    except Exception as e:
        print(f"\n测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

