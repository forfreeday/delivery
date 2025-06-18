# 手动签名指南

## 问题分析

您遇到的错误：
```
Error while broadcasting the heimdall transaction module=txBroadcaster error=null txResponse="Response:\n  TxHash: C5EFAAEE5C8B3F18B13EABF974370FE82ABB92C1F9B312638289E9E125EC1355\n  Code: 4\n  Raw Log: {\"codespace\":\"sdk\",\"code\":4,\"message\":\"signature verification failed; verify correct account sequence and chain-id\"}"
```

**原因**: 签名验证失败，需要正确的账户序列号和链ID。

## 解决方案

### 方法1: 使用自动化脚本（推荐）

```bash
# 给脚本执行权限
chmod +x sign_and_broadcast.sh

# 运行自动化签名和广播
./sign_and_broadcast.sh
```

### 方法2: 手动步骤

#### 步骤1: 获取账户信息
```bash
curl -s "http://localhost:1317/auth/accounts/0xd4d14396282a000234862eaf2527c17ed680e58e" | jq '.'
```

#### 步骤2: 生成未签名交易
```bash
curl -X POST http://localhost:1317/checkpoint/repair-test \
  -H 'Content-Type: application/json' \
  -d '{
    "base_req": {
      "from": "0xd4d14396282a000234862eaf2527c17ed680e58e",
      "chain_id": "delivery-22125",
      "account_number": "57",
      "sequence": "12761",
      "gas": "200000",
      "gas_adjustment": "1.2",
      "fees": [],
      "simulate": false
    },
    "checkpoint_number": "60191",
    "from": "0xd4d14396282a000234862eaf2527c17ed680e58e",
    "test_message": "手动签名测试"
  }'
```

#### 步骤3: 保存未签名交易
```bash
# 将响应中的 tx 字段保存到文件
echo '{"type":"cosmos-sdk/StdTx",...}' > unsigned_tx.json
```

#### 步骤4: 签名交易
```bash
deliverycli tx sign unsigned_tx.json \
  --from=0xd4d14396282a000234862eaf2527c17ed680e58e \
  --chain-id=delivery-22125 \
  --output-document=signed_tx.json
```

#### 步骤5: 广播交易
```bash
deliverycli tx broadcast signed_tx.json \
  --chain-id=delivery-22125 \
  --broadcast-mode=sync
```

### 方法3: 使用 REST API 广播

如果 deliverycli 广播失败，可以使用 REST API：

```bash
# 将签名后的交易转换为 base64
SIGNED_TX_BYTES=$(cat signed_tx.json | base64 -w 0)

# 使用 REST API 广播
curl -X POST http://localhost:1317/cosmos/tx/v1beta1/txs \
  -H 'Content-Type: application/json' \
  -d "{\"tx_bytes\":\"$SIGNED_TX_BYTES\",\"mode\":\"BROADCAST_MODE_SYNC\"}"
```

## 关键参数

- **账户地址**: `0xd4d14396282a000234862eaf2527c17ed680e58e`
- **链ID**: `delivery-22125`
- **账户编号**: `57`
- **序列号**: `12761` (需要获取最新的)

## 验证交易

```bash
# 查询交易状态
curl -s "http://localhost:1317/cosmos/tx/v1beta1/txs/{TXHASH}" | jq '.'

# 查询账户最新序列号
curl -s "http://localhost:1317/auth/accounts/0xd4d14396282a000234862eaf2527c17ed680e58e" | jq '.result.value.sequence'
```

## 常见问题

### 1. 序列号错误
**错误**: `signature verification failed; verify correct account sequence`
**解决**: 获取最新的序列号并重新生成交易

### 2. 链ID错误
**错误**: `signature verification failed; verify correct chain-id`
**解决**: 确保使用正确的链ID `delivery-22125`

### 3. 账户地址错误
**错误**: `signature verification failed; verify correct account`
**解决**: 确保使用正确的账户地址

## 推荐流程

1. 使用 `generate_signed_tx.sh` 生成未签名交易
2. 使用 `sign_and_broadcast.sh` 自动签名和广播
3. 如果失败，按照手动步骤操作
4. 验证交易状态

这样可以避免 TxBroadcaster 的序列号和链ID问题。 