#!/bin/bash

# 专门测试修复版本接口
# 使用真实地址测试 tx_fixed.go 中的接口

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"
CHAIN_ID="delivery-22125"
FROM_ADDRESS="0xD4D14396282A000234862EAF2527C17ED680E58E"

echo "=== 测试修复版本接口 ==="
echo "节点地址: $FROM_ADDRESS"
echo ""

# 测试 repair-fixed 接口
echo "1. 测试 /checkpoint/repair-fixed 接口"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191"
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 检查响应
if echo "$RESPONSE" | grep -q '"success": true'; then
    echo "✅ repair-fixed 接口测试成功！"
    echo "   交易已成功广播到链上"
elif echo "$RESPONSE" | grep -q "404"; then
    echo "❌ 路由未找到 (404)"
    echo "   请检查服务是否重新编译并重启"
else
    echo "⚠️  接口响应异常"
    echo "   响应内容: $RESPONSE"
fi

echo ""

# 测试 repair-test-fixed 接口
echo "2. 测试 /checkpoint/repair-test-fixed 接口"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-test-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191",
    "test_message": "测试消息"
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 检查响应
if echo "$RESPONSE" | grep -q '"success": true'; then
    echo "✅ repair-test-fixed 接口测试成功！"
    echo "   测试消息已成功广播到链上"
    echo "   请检查服务端日志中是否有 '收到测试消息' 的日志"
elif echo "$RESPONSE" | grep -q "404"; then
    echo "❌ 路由未找到 (404)"
    echo "   请检查服务是否重新编译并重启"
else
    echo "⚠️  接口响应异常"
    echo "   响应内容: $RESPONSE"
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "如果测试成功，您应该能在服务端日志中看到："
echo "  - 'repairCheckpointHandler, 开始处理补录消息'"
echo "  - 'repairCheckpointHandler, 直接广播成功'"
echo "  - '收到测试消息' (仅测试接口)"
echo ""
echo "如果测试失败，请："
echo "1. 确认服务正在运行"
echo "2. 重新编译并重启服务"
echo "3. 检查服务端日志中的详细错误信息" 