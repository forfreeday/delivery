#!/bin/bash

# 检查服务状态和路由注册
# 验证Heimdall服务是否正常运行，路由是否正确注册

set -e

# 配置
HEIMDALL_REST="http://localhost:1317"

echo "=== 检查服务状态和路由注册 ==="
echo ""

# 检查服务是否运行
echo "1. 检查Heimdall服务状态"
if curl -s $HEIMDALL_REST/ > /dev/null 2>&1; then
    echo "✅ Heimdall服务正在运行"
else
    echo "❌ Heimdall服务未运行或无法访问"
    echo "   请启动服务: ./build/deliveryd start --home ~/.delivery"
    exit 1
fi
echo ""

# 检查现有路由
echo "2. 检查现有checkpoint路由"
echo "获取路由信息..."
ROUTES=$(curl -s $HEIMDALL_REST/ | grep -i checkpoint || echo "未找到checkpoint路由")
echo "现有路由: $ROUTES"
echo ""

# 测试新路由是否注册
echo "3. 测试新路由注册状态"
echo "测试 repair-fixed 路由..."
if curl -s -o /dev/null -w "%{http_code}" $HEIMDALL_REST/checkpoint/repair-fixed | grep -q "404"; then
    echo "❌ repair-fixed 路由未注册 (404)"
else
    echo "✅ repair-fixed 路由已注册"
fi

echo "测试 repair-test-fixed 路由..."
if curl -s -o /dev/null -w "%{http_code}" $HEIMDALL_REST/checkpoint/repair-test-fixed | grep -q "404"; then
    echo "❌ repair-test-fixed 路由未注册 (404)"
else
    echo "✅ repair-test-fixed 路由已注册"
fi

echo "测试 repair-optimized 路由..."
if curl -s -o /dev/null -w "%{http_code}" $HEIMDALL_REST/checkpoint/repair-optimized | grep -q "404"; then
    echo "❌ repair-optimized 路由未注册 (404)"
else
    echo "✅ repair-optimized 路由已注册"
fi

echo "测试 repair-test-optimized 路由..."
if curl -s -o /dev/null -w "%{http_code}" $HEIMDALL_REST/checkpoint/repair-test-optimized | grep -q "404"; then
    echo "❌ repair-test-optimized 路由未注册 (404)"
else
    echo "✅ repair-test-optimized 路由已注册"
fi
echo ""

# 检查进程
echo "4. 检查deliveryd进程"
PROCESSES=$(ps aux | grep deliveryd | grep -v grep | wc -l)
if [ "$PROCESSES" -gt 0 ]; then
    echo "✅ 发现 $PROCESSES 个deliveryd进程"
    ps aux | grep deliveryd | grep -v grep
else
    echo "❌ 未发现deliveryd进程"
fi
echo ""

echo "=== 总结 ==="
echo ""
echo "如果所有路由都显示为已注册，请运行："
echo "  ./test_fixed_only.sh"
echo ""
echo "如果有路由未注册，请："
echo "1. 重新编译: make install"
echo "2. 重启服务: pkill deliveryd && ./build/deliveryd start --home ~/.delivery"
echo "3. 再次运行此脚本检查状态" 