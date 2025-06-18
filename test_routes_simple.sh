#!/bin/bash

# 简化的路由测试脚本
# 只测试路由是否可以访问，不依赖具体的地址配置

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"

echo "=== 测试新注册的路由可访问性 ==="
echo ""

# 测试1: repair-fixed 路由
echo "1. 测试 /checkpoint/repair-fixed 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "0x1234567890123456789012345678901234567890",
      "chain_id": "delivery-22125",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 测试2: repair-test-fixed 路由
echo "2. 测试 /checkpoint/repair-test-fixed 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-test-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "0x1234567890123456789012345678901234567890",
      "chain_id": "delivery-22125",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123,
    "test_message": "测试消息"
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 测试3: repair-optimized 路由
echo "3. 测试 /checkpoint/repair-optimized 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-optimized \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "0x1234567890123456789012345678901234567890",
      "chain_id": "delivery-22125",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 测试4: repair-test-optimized 路由
echo "4. 测试 /checkpoint/repair-test-optimized 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-test-optimized \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "0x1234567890123456789012345678901234567890",
      "chain_id": "delivery-22125",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123,
    "test_message": "测试消息"
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

echo "=== 测试结果分析 ==="
echo ""
echo "如果看到以下情况，说明路由注册成功："
echo ""
echo "✅ 成功情况："
echo "  - HTTP状态码不是404"
echo "  - 返回JSON响应（可能是错误信息，但说明路由存在）"
echo ""
echo "❌ 失败情况："
echo "  - HTTP状态码是404"
echo "  - 连接被拒绝"
echo ""
echo "如果所有路由都返回404，请："
echo "1. 确认Heimdall服务正在运行"
echo "2. 重新编译并重启服务"
echo "3. 检查路由注册代码是否正确" 