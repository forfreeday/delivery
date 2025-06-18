#!/bin/bash

# 生成正确的签名交易
echo "=== 生成正确的签名交易 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHAIN_ID="delivery-22125"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="手动签名测试_$(date +%s)"

echo "账户地址: $ACCOUNT_ADDRESS"
echo "链ID: $CHAIN_ID"
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

# 2. 生成未签名交易
echo ""
echo "2. 生成未签名交易..."

REQUEST_BODY=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "$CHAIN_ID",
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

echo "请求体:"
echo "$REQUEST_BODY" | jq '.'

# 发送请求获取未签名交易
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

# 检查是否成功生成未签名交易
if echo "$RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ 成功生成未签名交易"
    
    # 提取交易数据
    UNSIGNED_TX=$(echo "$RESPONSE" | jq -r '.tx')
    echo "未签名交易长度: ${#UNSIGNED_TX} 字符"
    
    # 保存未签名交易到文件
    echo "$UNSIGNED_TX" > unsigned_tx.json
    echo "未签名交易已保存到 unsigned_tx.json"
    
    echo ""
    echo "3. 签名步骤:"
    echo "   1) 使用 deliverycli 签名交易:"
    echo "      deliverycli tx sign unsigned_tx.json --from=$ACCOUNT_ADDRESS --chain-id=$CHAIN_ID --output-document=signed_tx.json"
    echo ""
    echo "   2) 广播签名后的交易:"
    echo "      deliverycli tx broadcast signed_tx.json --chain-id=$CHAIN_ID"
    echo ""
    echo "   或者使用 REST API 广播:"
    echo "   curl -X POST $REST_URL/cosmos/tx/v1beta1/txs \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"tx_bytes\":\"$(base64 -w 0 signed_tx.json)\",\"mode\":\"BROADCAST_MODE_SYNC\"}'"
    
else
    echo ""
    echo "❌ 生成未签名交易失败"
    echo "错误信息:"
    echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
    exit 1
fi

echo ""
echo "4. 验证交易内容..."
echo "交易包含的消息:"
echo "$RESPONSE" | jq -r '.tx' | jq '.'

echo ""
echo "=== 生成完成 ==="
echo "下一步:"
echo "1. 检查 unsigned_tx.json 文件"
echo "2. 使用 deliverycli 签名交易"
echo "3. 广播签名后的交易"
echo "4. 检查交易状态" 