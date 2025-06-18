#!/bin/bash

# 测试 repair-test 接口的标准 REST 流程
echo "=== 测试 repair-test 接口标准 REST 流程 ==="

# 设置变量
REST_URL="http://localhost:1317"
FROM_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER=12345
TEST_MESSAGE="测试REST消息 $(date +%s)"

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
  "checkpoint_number": $CHECKPOINT_NUMBER,
  "from": "$FROM_ADDRESS",
  "test_message": "$TEST_MESSAGE"
}
EOF
)

echo "请求体:"
echo "$REQUEST_BODY" | jq '.'

echo ""
echo "步骤1: 发送请求到 repair-test 接口生成未签名交易..."

# 发送请求生成未签名交易
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

# 检查响应
if echo "$RESPONSE" | jq -e '.value' > /dev/null; then
    echo ""
    echo "✅ 步骤1成功：未签名交易生成成功！"
    
    # 提取交易数据
    UNSIGNED_TX=$(echo "$RESPONSE" | jq -r '.value.msg[0]')
    FEE=$(echo "$RESPONSE" | jq -r '.value.fee')
    SIGNATURES=$(echo "$RESPONSE" | jq -r '.value.signatures')
    
    echo "未签名交易数据:"
    echo "msg: $UNSIGNED_TX"
    echo "fee: $FEE"
    echo "signatures: $SIGNATURES"
    
    echo ""
    echo "步骤2: 现在需要签名并广播这个交易..."
    echo "请使用 deliverycli 或其他工具签名并广播这个交易"
    echo ""
    echo "示例命令:"
    echo "deliverycli tx broadcast <signed_tx_file> --chain-id delivery-22125"
    
else
    echo ""
    echo "❌ 步骤1失败：未签名交易生成失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
fi

echo ""
echo "=== 测试完成 ==="
echo ""
echo "注意：这是标准的 REST 流程，需要客户端签名并广播交易"
echo "如果您需要自动广播，请使用其他接口或修改代码" 