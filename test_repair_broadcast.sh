#!/bin/bash

# 测试 repair-test 接口的 bridge TxBroadcaster 广播功能
echo "=== 测试 repair-test 接口的 bridge TxBroadcaster 广播功能 ==="

# 设置变量
REST_URL="http://localhost:1317"
FROM_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER=12345
TEST_MESSAGE="bridge广播测试消息 $(date +%s)"

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
    echo ""
    echo "请检查服务日志确认是否收到以下日志："
    echo "1. repairCheckpointTestHandler, 开始广播测试消息"
    echo "2. repairCheckpointTestHandler, 消息验证成功，准备广播"
    echo "3. repairCheckpointTestHandler, 广播成功"
    echo "4. handleMsgRepairCheckpointTest"
else
    echo ""
    echo "❌ repair-test 接口调用失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "广播方式说明："
echo "1. 使用项目中标准的 bridge/setu/broadcaster.TxBroadcaster"
echo "2. 这是项目中其他模块使用的标准广播方式"
echo "3. 如果出现序列号错误，可能需要确保 bridge 使用的账户与请求账户一致"
echo "4. bridge TxBroadcaster 使用 helper.GetAddress() 获取的地址" 