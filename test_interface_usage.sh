#!/bin/bash

# 测试接口使用示例脚本
# 演示 tx_fixed.go 和 tx_optimized.go 两个接口的使用方法

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"
CHAIN_ID="delivery-22125"
FROM_ADDRESS="0x..."  # 请替换为您的地址

echo "=== 接口使用示例 ==="
echo ""

# 1. 测试 tx_fixed.go 的补录接口
echo "1. 测试 tx_fixed.go 补录接口 (/checkpoint/repair-fixed)"
echo "请求:"
cat << EOF
curl -X POST $HEIMDALL_REST/checkpoint/repair-fixed \\
  -H "Content-Type: application/json" \\
  -d '{
    "base_req": {
      "from": "$FROM_ADDRESS",
      "chain_id": "$CHAIN_ID",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191"
  }'
EOF
echo ""
echo "预期响应:"
cat << EOF
{
  "success": true,
  "checkpoint_number": "60191",
  "from": "$FROM_ADDRESS",
  "message": "补录消息已成功广播到链上"
}
EOF
echo ""

# 2. 测试 tx_fixed.go 的测试接口
echo "2. 测试 tx_fixed.go 测试接口 (/checkpoint/repair-test-fixed)"
echo "请求:"
cat << EOF
curl -X POST $HEIMDALL_REST/checkpoint/repair-test-fixed \\
  -H "Content-Type: application/json" \\
  -d '{
    "base_req": {
      "from": "$FROM_ADDRESS",
      "chain_id": "$CHAIN_ID",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191",
    "test_message": "测试消息"
  }'
EOF
echo ""
echo "预期响应:"
cat << EOF
{
  "success": true,
  "checkpoint_number": "60191",
  "from": "$FROM_ADDRESS",
  "message": "补录消息已成功广播到链上"
}
EOF
echo ""

# 3. 测试 tx_optimized.go 的补录接口
echo "3. 测试 tx_optimized.go 补录接口 (/checkpoint/repair-optimized)"
echo "请求:"
cat << EOF
curl -X POST $HEIMDALL_REST/checkpoint/repair-optimized \\
  -H "Content-Type: application/json" \\
  -d '{
    "base_req": {
      "from": "$FROM_ADDRESS",
      "chain_id": "$CHAIN_ID",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191"
  }'
EOF
echo ""
echo "预期响应 (未签名交易):"
cat << EOF
{
  "type": "cosmos-sdk/StdTx",
  "value": {
    "msg": [
      {
        "type": "checkpoint/MsgRepairCheckpoint",
        "value": {
          "from": "$FROM_ADDRESS",
          "checkpoint_number": "60191",
          "root_chain": "tron",
          "checkpoint": {...}
        }
      }
    ],
    "fee": {
      "amount": [...],
      "gas": "200000"
    },
    "signatures": null,
    "memo": ""
  }
}
EOF
echo ""

# 4. 测试 tx_optimized.go 的测试接口
echo "4. 测试 tx_optimized.go 测试接口 (/checkpoint/repair-test-optimized)"
echo "请求:"
cat << EOF
curl -X POST $HEIMDALL_REST/checkpoint/repair-test-optimized \\
  -H "Content-Type: application/json" \\
  -d '{
    "base_req": {
      "from": "$FROM_ADDRESS",
      "chain_id": "$CHAIN_ID",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191",
    "test_message": "测试消息"
  }'
EOF
echo ""
echo "预期响应 (未签名交易):"
cat << EOF
{
  "type": "cosmos-sdk/StdTx",
  "value": {
    "msg": [
      {
        "type": "checkpoint/MsgRepairCheckpointTest",
        "value": {
          "from": "$FROM_ADDRESS",
          "checkpoint_number": "60191",
          "root_chain": "tron",
          "test_message": "测试消息",
          "checkpoint": {...}
        }
      }
    ],
    "fee": {
      "amount": [...],
      "gas": "200000"
    },
    "signatures": null,
    "memo": ""
  }
}
EOF
echo ""

echo "=== 接口对比总结 ==="
echo ""
echo "tx_fixed.go 特点:"
echo "  ✅ 直接广播到链上"
echo "  ✅ 返回明确的成功/失败状态"
echo "  ✅ 适合自动化脚本"
echo "  ❌ 依赖 TxBroadcaster 配置"
echo ""
echo "tx_optimized.go 特点:"
echo "  ✅ 生成标准未签名交易"
echo "  ✅ 异步尝试直接广播"
echo "  ✅ 容错性强，双重保障"
echo "  ✅ 适合手动签名流程"
echo "  ⚠️  需要客户端手动签名广播"
echo ""
echo "=== 使用建议 ==="
echo ""
echo "1. 如果 TxBroadcaster 配置正确，推荐使用 tx_fixed.go"
echo "2. 如果需要手动控制签名过程，推荐使用 tx_optimized.go"
echo "3. 可以同时测试两个接口，选择最适合的方案" 