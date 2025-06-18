#!/bin/bash

# 测试 repair-test 接口的定时器重试机制
echo "=== 测试 repair-test 接口定时器重试机制 ==="

# 设置变量
REST_URL="http://localhost:1317"
FROM_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"
CHECKPOINT_NUMBER=12345
TEST_MESSAGE="定时器测试消息 $(date +%s)"
MAX_RETRIES=3
RETRY_DELAY=5

echo "发送者地址: $FROM_ADDRESS"
echo "Checkpoint 编号: $CHECKPOINT_NUMBER"
echo "测试消息: $TEST_MESSAGE"
echo "最大重试次数: $MAX_RETRIES"
echo "重试间隔: ${RETRY_DELAY}秒"

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

# 重试函数
retry_broadcast() {
    local attempt=1
    local success=false
    
    while [ $attempt -le $MAX_RETRIES ] && [ "$success" = false ]; do
        echo ""
        echo "=== 第 $attempt 次尝试 ==="
        
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
            echo "✅ 第 $attempt 次尝试成功！"
            success=true
            break
        else
            echo ""
            echo "❌ 第 $attempt 次尝试失败"
            echo "错误信息:"
            echo "$RESPONSE" | jq -r '.error // .message // "未知错误"'
            
            # 检查是否是序列号错误
            if echo "$RESPONSE" | grep -q "sequence"; then
                echo "检测到序列号错误，等待 ${RETRY_DELAY} 秒后重试..."
                sleep $RETRY_DELAY
            else
                echo "非序列号错误，继续重试..."
                sleep 2
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ "$success" = false ]; then
        echo ""
        echo "❌ 所有 $MAX_RETRIES 次尝试都失败了"
        return 1
    else
        echo ""
        echo "✅ 最终成功！请检查服务日志确认是否收到 handleMsgRepairCheckpointTest 日志"
        return 0
    fi
}

# 执行重试
retry_broadcast

echo ""
echo "=== 测试完成 ===" 