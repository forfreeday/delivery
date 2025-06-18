#!/bin/bash

# 使用真实地址测试接口
# 使用您提供的节点地址进行测试

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"
CHAIN_ID="delivery-22125"
FROM_ADDRESS="0xD4D14396282A000234862EAF2527C17ED680E58E"

echo "=== 使用真实地址测试接口 ==="
echo "节点地址: $FROM_ADDRESS"
echo ""

# 测试1: repair-fixed 路由
echo "1. 测试 /checkpoint/repair-fixed 路由"
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

# 测试2: repair-test-fixed 路由
echo "2. 测试 /checkpoint/repair-test-fixed 路由"
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

# 测试3: repair-optimized 路由
echo "3. 测试 /checkpoint/repair-optimized 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-optimized \
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

# 测试4: repair-test-optimized 路由
echo "4. 测试 /checkpoint/repair-test-optimized 路由"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-test-optimized \
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

echo "=== 测试结果分析 ==="
echo ""
echo "预期结果："
echo ""
echo "repair-fixed 和 repair-test-fixed:"
echo "  ✅ 成功: {\"success\": true, \"checkpoint_number\": \"60191\", ...}"
echo "  ❌ 失败: 错误信息或404"
echo ""
echo "repair-optimized 和 repair-test-optimized:"
echo "  ✅ 成功: {\"type\": \"cosmos-sdk/StdTx\", ...}"
echo "  ❌ 失败: 错误信息或404"
echo ""
echo "如果看到成功响应，说明："
echo "1. 路由注册成功"
echo "2. JSON格式正确"
echo "3. 处理函数正常工作"
echo ""
echo "如果看到错误，请检查："
echo "1. 服务是否正在运行"
echo "2. 代码是否已重新编译"
echo "3. 服务端日志中的详细错误信息" 