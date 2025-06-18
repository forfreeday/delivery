#!/bin/bash

# 快速测试修复后的JSON格式
# 验证Amino编码要求（数字字段用引号包围）

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"

echo "=== 测试修复后的JSON格式 ==="
echo ""

# 测试修复版本接口
echo "1. 测试 repair-fixed 接口（修复后的JSON格式）"
echo "发送请求..."
RESPONSE=$(curl -X POST $HEIMDALL_REST/checkpoint/repair-fixed \
  -H "Content-Type: application/json" \
  -d '{
    "base_req": {
      "from": "0x1234567890123456789012345678901234567890",
      "chain_id": "delivery-22125",
      "gas": "200000",
      "gas_adjustment": "1.2"
    },
    "checkpoint_number": "60191"
  }' \
  -w "\nHTTP状态码: %{http_code}" \
  -s 2>/dev/null)

echo "响应: $RESPONSE"
echo ""

# 检查是否还有JSON解析错误
if echo "$RESPONSE" | grep -q "invalid character"; then
    echo "❌ 仍然存在JSON解析错误"
    echo "请检查其他数字字段是否也需要用引号包围"
else
    echo "✅ JSON格式正确，没有解析错误"
fi

echo ""
echo "=== 修复说明 ==="
echo ""
echo "已修复的问题："
echo "  - checkpoint_number: 123 → \"60191\""
echo "  - 所有数字字段都用引号包围"
echo ""
echo "Amino编码要求："
echo "  - int/int64/uint/uint64 类型需要用引号包围"
echo "  - 这是为了JavaScript数字支持"
echo ""
echo "如果仍有错误，请检查："
echo "1. 其他数字字段是否也需要引号"
echo "2. 服务是否已重新编译并重启"
echo "3. 路由是否正确注册" 