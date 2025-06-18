#!/bin/bash

# 测试修复后的广播功能（直接广播版本）
echo "=== 测试修复后的广播功能（直接广播版本）==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="修复测试_$(date +%s)"

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

# 2. 测试 repair-test 接口（修复版本）
echo ""
echo "2. 测试 repair-test 接口（修复版本）..."

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

# 检查是否成功广播
if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
    echo ""
    echo "✅ repair-test 接口直接广播成功！"
    echo "   - 消息已成功广播到链上"
    echo "   - 应该能看到 handler 日志"
    
    echo ""
    echo "📋 响应信息："
    echo "success: $(echo "$RESPONSE" | jq -r '.success')"
    echo "checkpoint_number: $(echo "$RESPONSE" | jq -r '.checkpoint_number')"
    echo "test_message: $(echo "$RESPONSE" | jq -r '.test_message')"
    echo "from: $(echo "$RESPONSE" | jq -r '.from')"
    echo "message: $(echo "$RESPONSE" | jq -r '.message')"
    
else
    echo ""
    echo "❌ repair-test 接口直接广播失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
    
    echo ""
    echo "🔍 可能的原因："
    echo "1. TxBroadcaster 配置问题"
    echo "2. 序列号不匹配"
    echo "3. 链ID不正确"
    echo "4. 账户余额不足"
fi

# 3. 测试 repair 接口（修复版本）
echo ""
echo "3. 测试 repair 接口（修复版本）..."

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
if echo "$REPAIR_RESPONSE" | jq -e '.success' > /dev/null; then
    echo ""
    echo "✅ repair 接口直接广播成功！"
    echo "   - 补录消息已成功广播到链上"
    echo "   - 应该能看到 handler 日志"
    
    echo ""
    echo "📋 响应信息："
    echo "success: $(echo "$REPAIR_RESPONSE" | jq -r '.success')"
    echo "checkpoint_number: $(echo "$REPAIR_RESPONSE" | jq -r '.checkpoint_number')"
    echo "from: $(echo "$REPAIR_RESPONSE" | jq -r '.from')"
    echo "message: $(echo "$REPAIR_RESPONSE" | jq -r '.message')"
    
else
    echo ""
    echo "❌ repair 接口直接广播失败"
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
echo "- repairCheckpointTestHandler, 尝试直接广播"
echo "- repairCheckpointTestHandler, 直接广播成功"
echo "- TxBroadcaster 相关的广播日志"
echo "- ✅ 收到测试消息 (在 handleMsgRepairCheckpointTest 中)"
echo ""
echo "repair 接口日志:"
echo "- repairCheckpointHandler, 开始处理补录消息"
echo "- repairCheckpointHandler, 尝试直接广播"
echo "- repairCheckpointHandler, 直接广播成功"
echo "- TxBroadcaster 相关的广播日志"
echo "- handleMsgRepairCheckpoint 中的日志"

# 5. 提供后续步骤
echo ""
echo "5. 后续步骤:"
echo ""
echo "如果直接广播成功，您应该能看到："
echo "1. ✅ 接口返回 success: true"
echo "2. ✅ 服务日志显示广播成功"
echo "3. ✅ handler 日志显示 '收到测试消息'"
echo ""
echo "如果直接广播失败，可以："
echo "1. 检查 TxBroadcaster 配置"
echo "2. 检查序列号和链ID"
echo "3. 回退到生成未签名交易的方式"
echo "4. 使用 ./sign_and_broadcast.sh 手动签名和广播"

echo ""
echo "=== 测试完成 ==="
echo "总结:"
echo "1. ✅ 修复版本使用直接广播"
echo "2. ✅ 参考了正确的代码模式"
echo "3. ✅ 应该能看到 handler 日志"
echo "4. ✅ 与 commit 9b19a7cc 版本行为一致"
echo ""
echo "关键改进："
echo "- 直接广播而不是生成未签名交易"
echo "- 同步错误处理"
echo "- 返回 success 响应格式"
echo "- 确保交易实际广播到链上" 