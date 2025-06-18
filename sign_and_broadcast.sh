#!/bin/bash

# 自动签名和广播交易
echo "=== 自动签名和广播交易 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHAIN_ID="delivery-22125"
CHECKPOINT_NUMBER="60191"
TEST_MESSAGE="自动签名广播测试_$(date +%s)"

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

# 发送请求获取未签名交易
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    "$REST_URL/checkpoint/repair-test")

# 检查是否成功生成未签名交易
if echo "$RESPONSE" | jq -e '.tx' > /dev/null; then
    echo "✅ 成功生成未签名交易"
    
    # 提取交易数据
    UNSIGNED_TX=$(echo "$RESPONSE" | jq -r '.tx')
    echo "$UNSIGNED_TX" > unsigned_tx.json
    echo "未签名交易已保存到 unsigned_tx.json"
    
else
    echo "❌ 生成未签名交易失败"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

# 3. 签名交易
echo ""
echo "3. 签名交易..."
if command -v deliverycli &> /dev/null; then
    echo "使用 deliverycli 签名交易..."
    
    # 签名交易
    SIGN_RESULT=$(deliverycli tx sign unsigned_tx.json \
        --from=$ACCOUNT_ADDRESS \
        --chain-id=$CHAIN_ID \
        --output-document=signed_tx.json \
        --yes 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ 交易签名成功"
    else
        echo "❌ 交易签名失败"
        echo "$SIGN_RESULT"
        exit 1
    fi
    
else
    echo "❌ deliverycli 未找到，请手动签名交易"
    echo "命令: deliverycli tx sign unsigned_tx.json --from=$ACCOUNT_ADDRESS --chain-id=$CHAIN_ID --output-document=signed_tx.json"
    exit 1
fi

# 4. 广播交易
echo ""
echo "4. 广播交易..."

# 检查签名后的交易文件
if [ -f "signed_tx.json" ]; then
    echo "使用 deliverycli 广播交易..."
    
    # 广播交易
    BROADCAST_RESULT=$(deliverycli tx broadcast signed_tx.json \
        --chain-id=$CHAIN_ID \
        --broadcast-mode=sync 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ 交易广播成功"
        echo "广播结果:"
        echo "$BROADCAST_RESULT"
        
        # 提取交易哈希
        TXHASH=$(echo "$BROADCAST_RESULT" | grep -o 'txhash: [A-F0-9]*' | cut -d' ' -f2)
        if [ ! -z "$TXHASH" ]; then
            echo ""
            echo "交易哈希: $TXHASH"
            echo "查询交易状态:"
            echo "curl -s \"$REST_URL/cosmos/tx/v1beta1/txs/$TXHASH\" | jq '.'"
        fi
        
    else
        echo "❌ 交易广播失败"
        echo "$BROADCAST_RESULT"
        
        # 尝试使用 REST API 广播
        echo ""
        echo "尝试使用 REST API 广播..."
        
        # 读取签名后的交易
        SIGNED_TX_BYTES=$(cat signed_tx.json | base64 -w 0)
        
        # 使用 REST API 广播
        REST_BROADCAST_RESULT=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"tx_bytes\":\"$SIGNED_TX_BYTES\",\"mode\":\"BROADCAST_MODE_SYNC\"}" \
            "$REST_URL/cosmos/tx/v1beta1/txs")
        
        echo "REST API 广播结果:"
        echo "$REST_BROADCAST_RESULT" | jq '.'
        
    fi
    
else
    echo "❌ 签名后的交易文件不存在"
    exit 1
fi

echo ""
echo "=== 完成 ==="
echo "清理临时文件..."
rm -f unsigned_tx.json signed_tx.json

echo "总结:"
echo "1. ✅ 生成未签名交易"
echo "2. ✅ 签名交易"
echo "3. ✅ 广播交易"
echo "4. 请检查交易状态确认是否成功" 