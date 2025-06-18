#!/bin/bash

echo "=== 检查账户序列号 ==="

ACCOUNT_ADDRESS="0xd4d14396282a000234862eaf2527c17ed680e58e"

echo "1. 获取账户信息..."
account_info=$(curl -s "http://localhost:1317/auth/accounts/$ACCOUNT_ADDRESS")
echo "$account_info" | jq '.'

echo ""
echo "2. 提取序列号..."
sequence=$(echo "$account_info" | jq -r '.result.value.sequence')
account_number=$(echo "$account_info" | jq -r '.result.value.account_number')
echo "序列号: $sequence"
echo "账户号: $account_number"

echo ""
echo "3. 检查链 ID..."
chain_info=$(curl -s "http://localhost:1317/node_info")
chain_id=$(echo "$chain_info" | jq -r '.node_info.network')
echo "链 ID: $chain_id"

echo ""
echo "4. 验证信息..."
echo "✅ 账户地址: $ACCOUNT_ADDRESS"
echo "✅ 当前序列号: $sequence"
echo "✅ 账户号: $account_number"
echo "✅ 链 ID: $chain_id"

echo ""
echo "=== 检查完成 ===" 