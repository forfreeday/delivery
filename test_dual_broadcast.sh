#!/bin/bash

# 测试两种广播方式：REST 生成未签名交易 + TxBroadcaster 直接广播
echo "=== 测试两种广播方式 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="测试两种广播方式_$(date +%s)"

echo "发送者地址: $ACCOUNT_ADDRESS"
echo "Checkpoint 编号: $CHECKPOINT_NUMBER"
echo "测试消息: $TEST_MESSAGE"

# 构建请求体
REQUEST_BODY=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "heimdall-22125",
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

echo ""
echo "请求体:"
echo "$REQUEST_BODY" | jq '.'

echo ""
echo "发送请求到 repair-test 接口（测试两种方式）..."

# 发送请求
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

# 检查响应
if echo "$RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ 方式1: REST 生成未签名交易成功！"
    echo "交易数据已生成，可以进行签名和广播"
    
    # 提取交易数据
    TX_DATA=$(echo "$RESPONSE" | jq -r '.tx')
    echo "交易数据长度: ${#TX_DATA} 字符"
    
    echo ""
    echo "请检查服务日志，应该能看到以下日志："
    echo "1. repairCheckpointTestHandler, 开始处理测试消息"
    echo "2. repairCheckpointTestHandler, 方式1: 生成未签名交易"
    echo "3. repairCheckpointTestHandler, 方式2: 尝试直接广播"
    echo "4. 如果直接广播成功: repairCheckpointTestHandler, 直接广播成功"
    echo "5. 如果直接广播失败: repairCheckpointTestHandler, 直接广播失败"
    echo "6. handleMsgRepairCheckpointTest 中的日志（如果直接广播成功）"
    
    echo ""
    echo "=== 两种方式对比 ==="
    echo "方式1 (REST): 生成未签名交易，需要客户端签名后广播"
    echo "方式2 (TxBroadcaster): 直接广播到链上，但可能遇到序列号/链ID问题"
    echo ""
    echo "建议："
    echo "- 如果直接广播成功，说明 TxBroadcaster 配置正确"
    echo "- 如果直接广播失败，可以使用方式1生成的交易数据进行手动签名和广播"
    
else
    echo ""
    echo "❌ 请求失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试 repair 接口（实际补录）==="

# 构建 repair 请求体
REPAIR_REQUEST_BODY=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "heimdall-22125",
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

echo "repair 请求体:"
echo "$REPAIR_REQUEST_BODY" | jq '.'

echo ""
echo "发送请求到 repair 接口..."

# 发送 repair 请求
REPAIR_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REPAIR_REQUEST_BODY" \
    "$REST_URL/checkpoint/repair")

echo "repair 响应:"
echo "$REPAIR_RESPONSE" | jq '.'

# 检查 repair 响应
if echo "$REPAIR_RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ repair 接口调用成功！"
    echo "交易数据已生成，可以进行签名和广播"
    
    echo ""
    echo "请检查服务日志，应该能看到以下日志："
    echo "1. repairCheckpointHandler, 开始处理补录消息"
    echo "2. repairCheckpointHandler, 方式1: 生成未签名交易"
    echo "3. repairCheckpointHandler, 方式2: 尝试直接广播"
    echo "4. 如果直接广播成功: repairCheckpointHandler, 直接广播成功"
    echo "5. 如果直接广播失败: repairCheckpointHandler, 直接广播失败"
    echo "6. handleMsgRepairCheckpoint 中的日志（如果直接广播成功）"
else
    echo ""
    echo "❌ repair 接口调用失败"
    echo "错误信息:"
    echo "$REPAIR_RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试完成 ==="
echo "总结："
echo "1. 两个接口现在都支持两种方式"
echo "2. 方式1: 生成未签名交易（可靠，推荐）"
echo "3. 方式2: 直接广播（可能遇到序列号/链ID问题）"
echo "4. 可以通过日志确认哪种方式成功"
echo "5. 如果直接广播失败，仍然可以使用方式1生成的交易" 