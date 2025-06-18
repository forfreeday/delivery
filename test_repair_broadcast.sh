#!/bin/bash

# 测试 repair-test 接口的真正广播功能
echo "=== 测试 repair-test 接口的真正广播功能 ==="

# 设置变量
REST_URL="http://localhost:1317"
FROM_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER=12345
TEST_MESSAGE="真正广播测试消息 $(date +%s)"

echo "发送者地址: $FROM_ADDRESS"
echo "Checkpoint 编号: $CHECKPOINT_NUMBER"
echo "测试消息: $TEST_MESSAGE"

# 构建请求体
REQUEST_BODY=$(cat <<EOF
{
  "base_req": {
    "from": "$FROM_ADDRESS",
    "chain_id": "delivery-22125",
    "gas": "200000",
    "gas_adjustment": "1.2",
    "fees": [
      {
        "denom": "delivery",
        "amount": "1000"
      }
    ],
    "simulate": false
  },
  "checkpoint_number": "$CHECKPOINT_NUMBER",
  "from": "$FROM_ADDRESS",
  "test_message": "$TEST_MESSAGE"
}
EOF
)

echo "请求体:"
echo "$REQUEST_BODY" | jq '.'

echo ""
echo "发送请求到 repair-test 接口..."

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
    
    # 提取交易哈希
    TX_HASH=$(echo "$RESPONSE" | jq -r '.tx_hash // empty')
    ACCOUNT_NUMBER=$(echo "$RESPONSE" | jq -r '.account_number // empty')
    SEQUENCE=$(echo "$RESPONSE" | jq -r '.sequence // empty')
    
    if [ -n "$TX_HASH" ]; then
        echo "交易哈希: $TX_HASH"
        echo "账户号: $ACCOUNT_NUMBER"
        echo "序列号: $SEQUENCE"
        echo ""
        echo "请检查服务日志确认是否收到以下日志："
        echo "1. repairCheckpointTestHandler, 开始广播测试消息"
        echo "2. repairCheckpointTestHandler, 获取到账户信息"
        echo "3. repairCheckpointTestHandler, 广播成功"
        echo "4. handleMsgRepairCheckpointTest"
    else
        echo "注意：响应中没有交易哈希，可能广播失败"
    fi
else
    echo ""
    echo "❌ repair-test 接口调用失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "改进说明："
echo "1. 现在使用正确的账户信息进行广播"
echo "2. 通过REST API获取账户的account_number和sequence"
echo "3. 使用这些信息创建TxBuilder"
echo "4. 调用helper.BuildAndBroadcastMsgs进行真正广播" 