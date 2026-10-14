# MoonRecoder

纯 MoonBit 的有界 GF(256) 随机线性网络编码内核：增量创新性判断、精确恢复、**未解码中继重编码**，以及可诊断的包追踪重放。

适用于在 MoonBit 中实现丢包实验、遥测网关、仿真中继或离线抓包诊断。它是可嵌入的同步库，不包含网络传输、重传调度或加密认证。MIT；模块 `ZJH-666-ZJH/moonrecoder@0.1.0`。

## 安装

使用支持 `moon.mod` / `moon.pkg` 的 MoonBit 稳定工具链。在自己的模块中：

```sh
moon add ZJH-666-ZJH/moonrecoder@0.1.0
```

在消费者 `moon.pkg` 中加入：

```moonbit
import {
  "ZJH-666-ZJH/moonrecoder" @r,
}
```

## 最小恢复流程

下面的逻辑可以放在测试块中；构造与接纳可能抛出 `CodeError`。完整可运行程序见 `examples/`。

```moonbit
let input = @r.Symbols::from_bytes(b"hello")
let encoder = @r.Encoder::new(7, input, 2)
let decoder = @r.Decoder::new(encoder.generation())
ignore(decoder.admit(encoder.systematic(0, 0)))
ignore(decoder.admit(encoder.systematic(2, 2)))
let hint = @r.feedback_from_wire(decoder.feedback().to_wire())
ignore(decoder.admit_batch(encoder.repair(hint, 10)))
assert_true(decoder.recover().equal(input))
```

## 三个完整工作流

| 下游用户 | 输入与处理 | 可核验结果 | 命令 |
|---|---|---|---|
| 遥测网关 / 丢包实验开发者 | 五个系统包中丢两个、重复一个，经反馈请求缺失主元修复 | 两个修复包恢复原始字节，重复计数为 1 | `moon run examples/telemetry` |
| 多跳仿真 / 中继组件开发者 | 中继仅收到三个源符号中的两个，在秩不足时混合当前基 | 下游收到两个独立混合包和另一个源包后恢复；中继始终秩 2 | `moon run examples/relay` |
| 测试设施 / 离线诊断作者 | 非法 hex、重复帧、两代交错流和七字节网络切片 | 生成拒绝事件、不污染秩，分别恢复两代并释放保留额度 | `moon run examples/trace` |

可在命令中加 `--target wasm-gc`、`wasm`、`js` 或 `native`。运行 native 需要相应 C 编译器；本地 Windows 未安装 C 编译器，native 的执行验证由 Ubuntu CI 承担。

## 主要接口

- `Symbols`：0..255 验证、分离可变数组、Bytes/hex 适配、向量乘加。
- `FieldMatrix`：有界批量秩、乘法和逆；`Basis`：增广 RREF、部分已知符号和矛盾检测。
- `Encoder`：系统包、显式系数包、确定性系数流、缺失主元反馈修复。
- `Decoder`：创新 / 依赖判定、秩 / 额度 / JSON 报告、恢复、fork、原子批量接纳。
- `Relay`：基序混合、确定性系数流混合、独立基包导出，不要求先恢复源。
- `Packet` / `Feedback`：自定义 MRC1 / MRF1 格式，长度、形状、域边界和 CRC 校验。
- `FrameReader`：网络分片组帧；整次 feed 失败回滚，不做字节流重同步。
- `SessionPool`：多代分派、字段单元保留预算、显式回收。
- `Replay`：hex / wire 输入转结构化事件；坏包记录为 rejected，而非使整个重放退出。

完整公开签名见生成的 `pkg.generated.mbti`；[架构与不变量](docs/architecture.md)、[逐字节格式](docs/wire-format.md)、[安全边界](SECURITY.md)。

## 约束，不可误用为保证

GF(256) 多项式为 `0x11d`；每代 1..64 个源符号，每符号 1..4096 字节，总源容量不超过 262144 字节。最后符号零填充；空输入无代。generation ID / sequence 使用非负有符号 31 位整数。

**随机包不保证任意 k 包可恢复**；依赖包不增加秩。序号仅为元数据，不用于去重和防重放。同序号不同独立方程可以增加秩，换序号的重复方程仍然依赖。重编码只能重新分布已有信息，不能增加中继的秩。

`CoefficientStream` 使用可复现 xorshift32；全零向量替换为 e0，分布并不均匀，也不具密码学安全性。流额度按生成的**系数字节数**计算，而非包数。CRC32 仅检测意外损坏，攻击者可重算它。欠定的污染包可能仍可接纳；应用必须在接纳前实现认证。

这不是 Reed–Solomon、RaptorQ 或 RFC 8681 的互操作实现。没有 MDS 保证、socket、自动重传、持久化会话、抗恶意编码或常数时间实现。

## 验证

```sh
moon info
moon fmt
moon fmt --check
moon check --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon run examples/telemetry --target wasm-gc --deny-warn
moon run examples/relay --target wasm-gc --deny-warn
moon run examples/trace --target wasm-gc --deny-warn
```

把目标替换为 wasm / js / native 可复现 CI 流程。43 个测试包含所有 65536 对域乘法与独立多项式长除法 oracle 的比较、增量/批量秩一致性、255 组中继权重、全部单切点组帧、最大帧、矛盾与原子回滚。没有发布吞吐量或覆盖率保证。

[CI](https://github.com/ZJH-666-ZJH/moonrecoder/actions/workflows/ci.yml) 使用干净 Ubuntu runner 执行四后端检查、构建、测试和三个示例。实际交付证据见 [工程审计](docs/competition/engineering-audit.md)。

## 来源与参与

这是原创工程实现，不是第三方库移植。运行时仅依赖 MoonBit 标准库；没有复制相邻项目源码。[参考/许可证边界](docs/provenance.md)、[AI 使用说明](AI-USE.md)、[变更记录](CHANGELOG.md)、[有界查重证据](docs/competition/duplicate-check.md)。

报告问题时请提供目标后端、工具链版本、维度和最小可公开的包 trace；不要提交生产数据、认证材料或私密抓包。参赛申报材料不属于本仓库。
