#!/bin/bash

# 测试新注册的路由是否可以正常访问
# 验证 tx_fixed.go 和 tx_optimized.go 中的处理函数是否被正确注册

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"
CHAIN_ID="delivery-22125"
FROM_ADDRESS="0x..."  # 请替换为您的地址

echo "=== 测试新注册的路由 ==="
echo ""

# 测试1: 检查 repair-fixed 路由
echo "1. 测试 /checkpoint/repair-fixed 路由"
echo "发送请求..."
curl -X POST $HEIMDALL_REST/checkpoint/repair-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123
  }' \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s
echo ""

# 测试2: 检查 repair-test-fixed 路由
echo "2. 测试 /checkpoint/repair-test-fixed 路由"
echo "发送请求..."
curl -X POST $HEIMDALL_REST/checkpoint/repair-test-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123,
    "test_message": "测试消息"
  }' \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s
echo ""

# 测试3: 检查 repair-optimized 路由
echo "3. 测试 /checkpoint/repair-optimized 路由"
echo "发送请求..."
curl -X POST $HEIMDALL_REST/checkpoint/repair-optimized \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123
  }' \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s
echo ""

# 测试4: 检查 repair-test-optimized 路由
echo "4. 测试 /checkpoint/repair-test-optimized 路由"
echo "发送请求..."
curl -X POST $HEIMDALL_REST/checkpoint/repair-test-optimized \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "'$FROM_ADDRESS'",
      "chain_id": "'$CHAIN_ID'",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": 123,
    "test_message": "测试消息"
  }' \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s
echo ""

# 测试5: 检查所有可用的路由
echo "5. 检查所有可用的 checkpoint 路由"
echo "获取路由列表..."
curl -s $HEIMDALL_REST/ | grep -i checkpoint || echo "未找到路由信息，请检查服务是否运行"
echo ""

echo "=== 测试结果说明 ==="
echo ""
echo "如果看到以下响应，说明路由注册成功："
echo ""
echo "repair-fixed 和 repair-test-fixed:"
echo "  - 成功: 返回 {\"success\": true, ...}"
echo "  - 失败: 返回 404 或错误信息"
echo ""
echo "repair-optimized 和 repair-test-optimized:"
echo "  - 成功: 返回 {\"type\": \"cosmos-sdk/StdTx\", ...}"
echo "  - 失败: 返回 404 或错误信息"
echo ""
echo "如果所有路由都返回 404，请检查："
echo "1. Heimdall 服务是否正在运行"
echo "2. 代码是否已重新编译"
echo "3. 路由注册是否正确" 