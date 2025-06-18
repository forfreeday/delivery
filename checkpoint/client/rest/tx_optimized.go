package rest

import (
	"net/http"

	"github.com/cosmos/cosmos-sdk/client/context"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/maticnetwork/heimdall/bridge/setu/broadcaster"
	"github.com/maticnetwork/heimdall/checkpoint/types"
	restClient "github.com/maticnetwork/heimdall/client/rest"
	"github.com/maticnetwork/heimdall/helper"
	hmTypes "github.com/maticnetwork/heimdall/types"
	"github.com/maticnetwork/heimdall/types/rest"
)

// 优化的 repairCheckpointHandler - 参考提供的代码模式
func repairCheckpointHandlerOptimized(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RepairCheckpointReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// 获取发送者地址
		var from hmTypes.HeimdallAddress
		if req.From != "" {
			from = hmTypes.HexToHeimdallAddress(req.From)
		} else {
			from = helper.GetFromAddress(cliCtx)
		}
		if from.Empty() {
			http.Error(w, "发送者地址不能为空", http.StatusBadRequest)
			return
		}

		// 记录开始操作的日志
		helper.Logger.Info("repairCheckpointHandler, 开始处理补录消息",
			"checkpointNumber", req.CheckpointNumber,
			"from", from.String(),
		)

		// 创建一个模拟的 checkpoint 用于测试
		testCheckpoint := hmTypes.Checkpoint{
			StartBlock: 50080768,
			EndBlock:   50089983,
			RootHash:   hmTypes.HexToHeimdallHash("0xc18d16ec7f97533ad4aa49aac5aaf73486da34839410f002d41fa73c5c2f06d3"),
			Proposer:   hmTypes.HexToHeimdallAddress("0xd4d14396282a000234862eaf2527c17ed680e58e"),
			BorChainID: "22125",
			TimeStamp:  1749546051,
		}

		// 创建 MsgRepairCheckpoint 消息
		msg := types.NewMsgRepairCheckpoint(
			from,
			req.CheckpointNumber,
			"tron", // rootChain
			testCheckpoint,
		)

		// 验证消息
		if err := msg.ValidateBasic(); err != nil {
			helper.Logger.Error("repairCheckpointHandler, 消息验证失败", "error", err)
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		// 方式1: 使用标准的 REST 方式生成未签名交易
		helper.Logger.Info("repairCheckpointHandler, 方式1: 生成未签名交易",
			"checkpointNumber", req.CheckpointNumber,
			"from", from.String(),
		)

		// 使用 WriteGenerateStdTxResponse 生成未签名交易
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})

		// 方式2: 尝试使用 TxBroadcaster 直接广播（异步，不影响响应）
		go func() {
			helper.Logger.Info("repairCheckpointHandler, 方式2: 尝试直接广播",
				"checkpointNumber", req.CheckpointNumber,
				"from", from.String(),
			)

			// 创建 TxBroadcaster 实例
			txBroadcaster := broadcaster.NewTxBroadcaster(cliCtx.Codec)

			// 使用 TxBroadcaster 广播消息到 Heimdall
			err := txBroadcaster.BroadcastToHeimdall(msg)
			if err != nil {
				helper.Logger.Error("repairCheckpointHandler, 直接广播失败",
					"error", err,
					"checkpointNumber", req.CheckpointNumber,
					"from", from.String(),
					"note", "这是预期的，因为 TxBroadcaster 需要正确的序列号和链ID配置",
				)
			} else {
				helper.Logger.Info("repairCheckpointHandler, 直接广播成功",
					"checkpointNumber", req.CheckpointNumber,
					"from", from.String(),
				)
			}
		}()
	}
}

// 优化的 repairCheckpointTestHandler - 参考提供的代码模式
func repairCheckpointTestHandlerOptimized(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RepairCheckpointTestReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		// 获取发送者地址
		var from hmTypes.HeimdallAddress
		if req.From != "" {
			from = hmTypes.HexToHeimdallAddress(req.From)
		} else {
			from = helper.GetFromAddress(cliCtx)
		}
		if from.Empty() {
			http.Error(w, "发送者地址不能为空", http.StatusBadRequest)
			return
		}

		// 验证 BaseReq
		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// 记录开始处理的日志
		helper.Logger.Info("repairCheckpointTestHandler, 开始处理测试消息",
			"checkpointNumber", req.CheckpointNumber,
			"testMessage", req.TestMessage,
			"from", from.String(),
		)

		// 创建一个测试 checkpoint 消息
		testCheckpoint := hmTypes.Checkpoint{
			StartBlock: 50080768,
			EndBlock:   50089983,
			RootHash:   hmTypes.HexToHeimdallHash("0xc18d16ec7f97533ad4aa49aac5aaf73486da34839410f002d41fa73c5c2f06d3"),
			Proposer:   hmTypes.HexToHeimdallAddress("0xd4d14396282a000234862eaf2527c17ed680e58e"),
			BorChainID: "22125",
			TimeStamp:  1749546051,
		}

		// 创建 MsgRepairCheckpointTest 消息
		msg := types.NewMsgRepairCheckpointTest(
			from,
			req.CheckpointNumber,
			"tron", // rootChain
			req.TestMessage,
			testCheckpoint,
		)

		// 验证消息
		if err := msg.ValidateBasic(); err != nil {
			helper.Logger.Error("repairCheckpointTestHandler, 消息验证失败", "error", err)
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		// 方式1: 使用标准的 REST 方式生成未签名交易
		helper.Logger.Info("repairCheckpointTestHandler, 方式1: 生成未签名交易",
			"checkpointNumber", req.CheckpointNumber,
			"testMessage", req.TestMessage,
			"from", from.String(),
		)

		// 使用 WriteGenerateStdTxResponse 生成未签名交易
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})

		// 方式2: 尝试使用 TxBroadcaster 直接广播（异步，不影响响应）
		go func() {
			helper.Logger.Info("repairCheckpointTestHandler, 方式2: 尝试直接广播",
				"checkpointNumber", req.CheckpointNumber,
				"testMessage", req.TestMessage,
				"from", from.String(),
			)

			// 创建 TxBroadcaster 实例
			txBroadcaster := broadcaster.NewTxBroadcaster(cliCtx.Codec)

			// 使用 TxBroadcaster 广播消息到 Heimdall
			err := txBroadcaster.BroadcastToHeimdall(msg)
			if err != nil {
				helper.Logger.Error("repairCheckpointTestHandler, 直接广播失败",
					"error", err,
					"checkpointNumber", req.CheckpointNumber,
					"testMessage", req.TestMessage,
					"from", from.String(),
					"note", "这是预期的，因为 TxBroadcaster 需要正确的序列号和链ID配置",
				)
			} else {
				helper.Logger.Info("repairCheckpointTestHandler, 直接广播成功",
					"checkpointNumber", req.CheckpointNumber,
					"testMessage", req.TestMessage,
					"from", from.String(),
				)
			}
		}()
	}
}

// 参考提供的代码模式，创建一个简化的广播函数
func broadcastCheckpointMessage(cliCtx context.CLIContext, msg sdk.Msg, checkpointNumber uint64, from hmTypes.HeimdallAddress) error {
	// 创建 TxBroadcaster 实例
	txBroadcaster := broadcaster.NewTxBroadcaster(cliCtx.Codec)

	// 使用 TxBroadcaster 广播消息到 Heimdall
	err := txBroadcaster.BroadcastToHeimdall(msg)
	if err != nil {
		helper.Logger.Error("Error while broadcasting checkpoint to heimdall",
			"error", err,
			"checkpointNumber", checkpointNumber,
			"from", from.String(),
		)
		return err
	}

	helper.Logger.Info("Checkpoint broadcast successful",
		"checkpointNumber", checkpointNumber,
		"from", from.String(),
	)
	return nil
}
