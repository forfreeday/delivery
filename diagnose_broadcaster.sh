#!/bin/bash

# 诊断 TxBroadcaster 配置问题
echo "=== 诊断 TxBroadcaster 配置问题 ==="

# 设置变量
REST_URL="http://localhost:1317"
ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"

echo "1. 检查账户信息..."
ACCOUNT_INFO=$(curl -s "$REST_URL/auth/accounts/$ACCOUNT_ADDRESS")
echo "账户信息:"
echo "$ACCOUNT_INFO" | jq '.'

# 提取关键信息
SEQUENCE=$(echo "$ACCOUNT_INFO" | jq -r '.result.value.sequence')
ACCOUNT_NUMBER=$(echo "$ACCOUNT_INFO" | jq -r '.result.value.account_number')
CHAIN_ID=$(echo "$ACCOUNT_INFO" | jq -r '.result.value.chain_id // "unknown"')

echo ""
echo "2. 关键信息:"
echo "   - 账户地址: $ACCOUNT_ADDRESS"
echo "   - 当前序列号: $SEQUENCE"
echo "   - 账户编号: $ACCOUNT_NUMBER"
echo "   - 链ID: $CHAIN_ID"

echo ""
echo "3. 检查链配置..."
GENESIS_INFO=$(curl -s "$REST_URL/node_info")
echo "节点信息:"
echo "$GENESIS_INFO" | jq '.'

# 提取链ID
NODE_CHAIN_ID=$(echo "$GENESIS_INFO" | jq -r '.node_info.network // "unknown"')
echo "   - 节点链ID: $NODE_CHAIN_ID"

echo ""
echo "4. 检查 TxBroadcaster 可能的问题:"

echo "   问题1: 序列号不匹配"
echo "   - TxBroadcaster 初始化时获取的序列号可能不是最新的"
echo "   - 当前序列号: $SEQUENCE"
echo "   - 建议: 每次广播前重新获取序列号"

echo ""
echo "   问题2: 链ID不匹配"
echo "   - TxBroadcaster 使用的链ID: delivery-22125 (推测)"
echo "   - 实际需要的链ID: $NODE_CHAIN_ID"
echo "   - 建议: 确保使用正确的链ID"

echo ""
echo "   问题3: 账户地址不匹配"
echo "   - TxBroadcaster 使用的地址: 通过 helper.GetAddress() 获取"
echo "   - 期望的地址: $ACCOUNT_ADDRESS"
echo "   - 建议: 确保 helper.GetAddress() 返回正确的地址"

echo ""
echo "5. 解决方案建议:"

echo "   方案1: 使用 REST 方式（推荐）"
echo "   - 生成未签名交易"
echo "   - 客户端签名后广播"
echo "   - 避免序列号和链ID问题"

echo ""
echo "   方案2: 修复 TxBroadcaster 配置"
echo "   - 确保 helper.GetAddress() 返回正确地址"
echo "   - 确保 helper.GetGenesisDoc().ChainID 返回正确链ID"
echo "   - 每次广播前重新获取序列号"

echo ""
echo "   方案3: 使用双重方式（当前实现）"
echo "   - 方式1: REST 生成未签名交易（可靠）"
echo "   - 方式2: TxBroadcaster 直接广播（可能失败）"
echo "   - 如果方式2失败，仍可使用方式1"

echo ""
echo "6. 测试当前配置..."

# 构建测试请求
TEST_REQUEST=$(cat <<EOF
{
    "base_req": {
        "from": "$ACCOUNT_ADDRESS",
        "chain_id": "delivery-22125",
        "gas": "200000",
        "gas_adjustment": "1.2",
        "fees": [],
        "simulate": false
    },
    "checkpoint_number": "12345",
    "from": "$ACCOUNT_ADDRESS",
    "test_message": "诊断测试_$(date +%s)"
}
EOF
)

echo "发送测试请求..."
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$TEST_REQUEST" \
    "$REST_URL/checkpoint/repair-test")

echo "响应:"
echo "$RESPONSE" | jq '.'

if echo "$RESPONSE" | jq -e '.tx' > /dev/null; then
    echo ""
    echo "✅ 方式1 (REST) 工作正常"
    echo "   - 成功生成未签名交易"
    echo "   - 这是推荐的生产方式"
else
    echo ""
    echo "❌ 方式1 (REST) 失败"
    echo "   - 需要检查服务配置"
fi

echo ""
echo "=== 诊断完成 ==="
echo "总结:"
echo "1. 当前序列号: $SEQUENCE"
echo "2. 当前链ID: $NODE_CHAIN_ID"
echo "3. 推荐使用方式1 (REST生成未签名交易)"
echo "4. 如果方式2 (TxBroadcaster) 失败，这是预期的"
echo "5. 可以通过日志查看具体的失败原因" 