package rest

import (
	"github.com/maticnetwork/heimdall/app"
	"net/http"

	"github.com/cosmos/cosmos-sdk/client/context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/gorilla/mux"

	"github.com/maticnetwork/heimdall/bridge/setu/broadcaster"
	"github.com/maticnetwork/heimdall/checkpoint/types"
	restClient "github.com/maticnetwork/heimdall/client/rest"
	"github.com/maticnetwork/heimdall/helper"
	hmTypes "github.com/maticnetwork/heimdall/types"
	"github.com/maticnetwork/heimdall/types/rest"
)

func registerTxRoutes(cliCtx context.CLIContext, r *mux.Router) {
	r.HandleFunc(
		"/checkpoint/new",
		newCheckpointHandler(cliCtx),
	).Methods("POST")
	r.HandleFunc("/checkpoint/ack", newCheckpointACKHandler(cliCtx)).Methods("POST")
	r.HandleFunc("/checkpoint/no-ack", newCheckpointNoACKHandler(cliCtx)).Methods("POST")
	r.HandleFunc("/checkpoint/repair", repairCheckpointHandler(cliCtx)).Methods("POST")
	r.HandleFunc("/checkpoint/repair-test", repairCheckpointTestHandler(cliCtx)).Methods("POST")

	// 添加新的修复版本路由
	r.HandleFunc("/checkpoint/repair-fixed", repairCheckpointHandlerFixed(cliCtx)).Methods("POST")
	r.HandleFunc("/checkpoint/repair-test-fixed", repairCheckpointTestHandlerFixed(cliCtx)).Methods("POST")

	// 添加新的优化版本路由
	r.HandleFunc("/checkpoint/repair-optimized", repairCheckpointHandlerOptimized(cliCtx)).Methods("POST")
	r.HandleFunc("/checkpoint/repair-test-optimized", repairCheckpointTestHandlerOptimized(cliCtx)).Methods("POST")

	r.HandleFunc("/your-module/test", myTestHandlerFn(cliCtx)).Methods("POST")
}

type (
	// HeaderBlockReq struct for incoming checkpoint
	HeaderBlockReq struct {
		BaseReq rest.BaseReq `json:"base_req"`

		Proposer        hmTypes.HeimdallAddress `json:"proposer"`
		RootHash        hmTypes.HeimdallHash    `json:"root_Hash"`
		AccountRootHash hmTypes.HeimdallHash    `json:"account_root_hash"`
		StartBlock      uint64                  `json:"start_block"`
		EndBlock        uint64                  `json:"end_block"`
		BorChainID      string                  `json:"bor_chain_id"`
		RootChain       string                  `json:"root_chain"`
		Epoch           uint64                  `json:"epoch"`
	}

	// HeaderACKReq struct for sending ACK for a new headers
	// by providing the header index assigned my mainchain contract
	HeaderACKReq struct {
		BaseReq rest.BaseReq `json:"base_req"`

		From        hmTypes.HeimdallAddress `json:"proposer"`
		HeaderBlock uint64                  `json:"header_block"`
		StartBlock  uint64                  `json:"start_block"`
		EndBlock    uint64                  `json:"end_block"`
		Proposer    hmTypes.HeimdallAddress `json:"proposer"`
		RootHash    hmTypes.HeimdallHash    `json:"root_Hash"`
		TxHash      hmTypes.HeimdallHash    `json:"tx_hash"`
		LogIndex    uint64                  `json:"log_index"`
		RootChain   string                  `json:"root_chain"`
	}

	// HeaderNoACKReq struct for sending no-ack for a new headers
	HeaderNoACKReq struct {
		BaseReq rest.BaseReq `json:"base_req"`

		Proposer hmTypes.HeimdallAddress `json:"proposer"`
	}

	// RepairCheckpointReq 用于repair接口的请求体
	RepairCheckpointReq struct {
		BaseReq          rest.BaseReq `json:"base_req"`
		CheckpointNumber uint64       `json:"checkpoint_number"`
		From             string       `json:"from"` // 添加 From 字段
	}

	// RepairCheckpointTestReq 用于测试接口的请求体
	RepairCheckpointTestReq struct {
		BaseReq          rest.BaseReq `json:"base_req"`
		CheckpointNumber uint64       `json:"checkpoint_number"`
		From             string       `json:"from"`
		TestMessage      string       `json:"test_message"`
	}
)

func newCheckpointHandler(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req HeaderBlockReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// draft a message and send response
		msg := types.NewMsgCheckpointBlock(
			req.Proposer,
			req.StartBlock,
			req.EndBlock,
			req.RootHash,
			req.AccountRootHash,
			req.BorChainID,
			req.Epoch,
			req.RootChain,
		)

		// send response
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})
	}
}

func newCheckpointACKHandler(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req HeaderACKReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// draft a message and send response
		msg := types.NewMsgCheckpointAck(
			req.From,
			req.HeaderBlock,
			req.Proposer,
			req.StartBlock,
			req.EndBlock,
			req.RootHash,
			req.TxHash,
			req.LogIndex,
			req.RootChain,
		)

		// send response
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})
	}
}

func newCheckpointNoACKHandler(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req HeaderNoACKReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// draft a message and send response
		msg := types.NewMsgCheckpointNoAck(
			req.Proposer,
		)

		// send response
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})
	}
}

func repairCheckpointHandler(cliCtx context.CLIContext) http.HandlerFunc {
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

			txBroadcaster2 := broadcaster.NewTxBroadcaster(app.MakeCodec())
			err2 := txBroadcaster2.BroadcastToHeimdall(msg)
			if err2 != nil {
				helper.Logger.Error("repairCheckpointHandler, txBroadcaster2 直接广播失败",
					"error", err2,
					"checkpointNumber", req.CheckpointNumber,
					"from", from.String(),
					"note", "这是预期的，因为 TxBroadcaster 需要正确的序列号和链ID配置",
				)
			} else {
				helper.Logger.Info("repairCheckpointHandler, txBroadcaster2 直接广播成功",
					"checkpointNumber", req.CheckpointNumber,
					"from", from.String(),
				)
			}

		}()
	}
}

func repairCheckpointTestHandler(cliCtx context.CLIContext) http.HandlerFunc {
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

type myTestReq struct {
	BaseReq  rest.BaseReq `json:"base_req"` // 使用 heimdall 的 rest.BaseReq
	From     string       `json:"from"`
	TestData string       `json:"test_data"`
}

func myTestHandlerFn(cliCtx context.CLIContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req myTestReq
		if !rest.ReadRESTReq(w, r, cliCtx.Codec, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		fromAddr := hmTypes.HexToHeimdallAddress(req.From)

		// Create message
		msg := types.NewMsgMyTest(fromAddr, req.TestData)
		if err := msg.ValidateBasic(); err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		// Send the message
		restClient.WriteGenerateStdTxResponse(w, cliCtx, req.BaseReq, []sdk.Msg{msg})
	}
}
