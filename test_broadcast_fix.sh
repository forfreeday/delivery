#!/bin/bash

# 测试修复后的 checkpoint 补录广播机制
echo "=== 测试修复后的 checkpoint 补录广播机制 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="测试修复后的广播机制_$(date +%s)"

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
echo "发送请求到 repair-test 接口（使用 TxBroadcaster 广播）..."

# 发送请求
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

# 检查响应
if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
    echo ""
    echo "✅ repair-test 接口调用成功！"
    echo "checkpoint_number: $(echo "$RESPONSE" | jq -r '.checkpoint_number')"
    echo "test_message: $(echo "$RESPONSE" | jq -r '.test_message')"
    echo "from: $(echo "$RESPONSE" | jq -r '.from')"
    echo ""
    echo "请检查服务日志，应该能看到以下日志："
    echo "1. repairCheckpointTestHandler, 开始广播测试消息"
    echo "2. repairCheckpointTestHandler, 广播成功"
    echo "3. TxBroadcaster 相关的广播日志"
    echo "4. handleMsgRepairCheckpointTest 中的日志"
else
    echo ""
    echo "❌ repair-test 接口调用失败"
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
if echo "$REPAIR_RESPONSE" | jq -e '.success' > /dev/null; then
    echo ""
    echo "✅ repair 接口调用成功！"
    echo "checkpoint_number: $(echo "$REPAIR_RESPONSE" | jq -r '.checkpoint_number')"
    echo "from: $(echo "$REPAIR_RESPONSE" | jq -r '.from')"
    echo ""
    echo "请检查服务日志，应该能看到以下日志："
    echo "1. repairCheckpointHandler, 开始广播补录消息"
    echo "2. repairCheckpointHandler, 广播成功"
    echo "3. TxBroadcaster 相关的广播日志"
    echo "4. handleMsgRepairCheckpoint 中的日志"
else
    echo ""
    echo "❌ repair 接口调用失败"
    echo "错误信息:"
    echo "$REPAIR_RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试完成 ==="
echo "总结："
echo "1. 两个接口现在都使用 TxBroadcaster 进行广播"
echo "2. 不再直接操作数据库，而是通过标准的消息广播机制"
echo "3. 消息会被广播到 Heimdall 链上，由相应的 handler 处理"
echo "4. 可以通过日志确认广播是否成功" 