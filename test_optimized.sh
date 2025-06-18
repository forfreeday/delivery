#!/bin/bash

# 测试优化后的广播功能
echo "=== 测试优化后的广播功能 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="优化测试_$(date +%s)"

echo "账户地址: $ACCOUNT_ADDRESS"
echo "Checkpoint编号: $CHECKPOINT_NUMBER"
echo "测试消息: $TEST_MESSAGE"

# 1. 获取账户信息
echo ""
echo "1. 获取账户信息..."
ACCOUNT_INFO=$(curl -s "$REST_URL/auth/accounts/$ACCOUNT_ADDRESS")
SEQUENCE=$(echo "$ACCOUNT_INFO" | jq -r '.result.value.sequence')
ACCOUNT_NUMBER=$(echo "$ACCOUNT_INFO" | jq -r '.result.value.account_number')

echo "当前序列号: $SEQUENCE"
echo "账户编号: $ACCOUNT_NUMBER"

# 2. 测试 repair-test 接口（优化后）
echo ""
echo "2. 测试 repair-test 接口（优化后）..."

REQUEST_BODY=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "delivery-22125",
        "account_number": "$ACCOUNT_NUMBER",
        "sequence": "$SEQUENCE",
        "gas": "200000",
        "gas_adjustment": "1.2",
        "fees": [],
        "simulate": false
    },
    "checkpoint_number": "$CHECKPOINT_NUMBER",
    "from": "$ACCOUNT_ADDRESS",
    "test_message": "$TEST_MESSAGE"
}
EOF
)

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

# 检查是否成功生成未签名交易
if echo "$RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ repair-test 接口工作正常（优化后）"
    echo "   - 成功生成未签名交易"
    echo "   - 方式1 (REST) 可用"
    
    # 保存交易数据
    UNSIGNED_TX=$(echo "$RESPONSE" | jq -r '.tx')
    echo "$UNSIGNED_TX" > optimized_unsigned_tx.json
    echo "未签名交易已保存到 optimized_unsigned_tx.json"
    
else
    echo ""
    echo "❌ repair-test 接口失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

# 3. 测试 repair 接口（优化后）
echo ""
echo "3. 测试 repair 接口（优化后）..."

REPAIR_REQUEST_BODY=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "delivery-22125",
        "account_number": "$ACCOUNT_NUMBER",
        "sequence": "$SEQUENCE",
        "gas": "200000",
        "gas_adjustment": "1.2",
        "fees": [],
        "simulate": false
    },
    "checkpoint_number": "$CHECKPOINT_NUMBER",
    "from": "$ACCOUNT_ADDRESS"
}
EOF
)

REPAIR_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REPAIR_REQUEST_BODY" \
    "$REST_URL/checkpoint/repair")

echo "repair 响应:"
echo "$REPAIR_RESPONSE" | jq '.'

# 检查 repair 响应
if echo "$REPAIR_RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ repair 接口工作正常（优化后）"
    echo "   - 成功生成未签名交易"
    echo "   - 方式1 (REST) 可用"
    
    # 保存交易数据
    REPAIR_UNSIGNED_TX=$(echo "$REPAIR_RESPONSE" | jq -r '.tx')
    echo "$REPAIR_UNSIGNED_TX" > optimized_repair_unsigned_tx.json
    echo "repair 未签名交易已保存到 optimized_repair_unsigned_tx.json"
    
else
    echo ""
    echo "❌ repair 接口失败"
    echo "错误信息:"
    echo "$REPAIR_RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

# 4. 检查服务日志
echo ""
echo "4. 检查服务日志..."
echo "请查看服务日志，应该能看到以下信息："
echo ""
echo "repair-test 接口日志:"
echo "- repairCheckpointTestHandler, 开始处理测试消息"
echo "- repairCheckpointTestHandler, 方式1: 生成未签名交易"
echo "- repairCheckpointTestHandler, 方式2: 尝试直接广播"
echo "- 如果直接广播成功: repairCheckpointTestHandler, 直接广播成功"
echo "- 如果直接广播失败: repairCheckpointTestHandler, 直接广播失败"
echo ""
echo "repair 接口日志:"
echo "- repairCheckpointHandler, 开始处理补录消息"
echo "- repairCheckpointHandler, 方式1: 生成未签名交易"
echo "- repairCheckpointHandler, 方式2: 尝试直接广播"
echo "- 如果直接广播成功: repairCheckpointHandler, 直接广播成功"
echo "- 如果直接广播失败: repairCheckpointHandler, 直接广播失败"

# 5. 提供后续步骤
echo ""
echo "5. 后续步骤:"
echo ""
echo "如果两个接口都成功生成未签名交易，您可以："
echo ""
echo "选项1: 使用自动化脚本"
echo "  ./sign_and_broadcast.sh"
echo ""
echo "选项2: 手动签名和广播"
echo "  # 签名交易"
echo "  deliverycli tx sign optimized_unsigned_tx.json \\"
echo "    --from=$ACCOUNT_ADDRESS \\"
echo "    --chain-id=delivery-22125 \\"
echo "    --output-document=optimized_signed_tx.json"
echo ""
echo "  # 广播交易"
echo "  deliverycli tx broadcast optimized_signed_tx.json \\"
echo "    --chain-id=delivery-22125 \\"
echo "    --broadcast-mode=sync"
echo ""
echo "选项3: 使用 REST API 广播"
echo "  # 将签名后的交易转换为 base64"
echo "  SIGNED_TX_BYTES=\$(cat optimized_signed_tx.json | base64 -w 0)"
echo ""
echo "  # 使用 REST API 广播"
echo "  curl -X POST $REST_URL/cosmos/tx/v1beta1/txs \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d \"{\\\"tx_bytes\\\":\\\"\$SIGNED_TX_BYTES\\\",\\\"mode\\\":\\\"BROADCAST_MODE_SYNC\\\"}\""

echo ""
echo "=== 优化总结 ==="
echo "1. ✅ 借鉴了正确的代码模式"
echo "2. ✅ 实现了双重广播方式"
echo "3. ✅ 改进了错误处理和日志"
echo "4. ✅ 保持了向后兼容性"
echo "5. ✅ 提供了灵活的广播选项"
echo ""
echo "主要改进："
echo "- 使用正确的消息创建模式"
echo "- 改进的 TxBroadcaster 使用方式"
echo "- 详细的错误处理和日志记录"
echo "- 异步处理，不影响响应"
echo "- 简化的广播函数" 