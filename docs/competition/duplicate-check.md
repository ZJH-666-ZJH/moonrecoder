# 语义查重与选题证据

复核日期：2026-10-14（Asia/Shanghai）。范围是当日可见的 MoonCakes、GitHub MoonBit 项目、官方 awesome-moonbit 清单和本地永久选题登记；不是对整个互联网的唯一性证明。已实际执行 osc2026-guide 的 Project Research Guide，而非仅引用其名称。比赛固定交付规则与本次参与者截止日期 2026-10-30 分开处理。

## 候选筛选

分数 1..5，5 为有利；“不重复”是基于下述有限证据的风险判断，成熟直接重复有否决权，不由总分覆盖。

| 候选领域 / 能力 | 用户广度 | 独立缺口 | 实现深度 | 可复现验收 | 交付可行性 | 结论 |
|---|---:|---:|---:|---:|---:|---|
| Petri 网可达性 / 不变量 | 4 | 1 | 5 | 4 | 4 | 淘汰；成熟 moonpetri 与永久预留高度重叠 |
| 物理量纲 / 仿射单位 | 5 | 1 | 4 | 5 | 4 | 淘汰；LunarUnits 已有实质能力 |
| 系统故障树 / 可靠性分析 | 4 | 2 | 5 | 4 | 4 | 淘汰；moon-reliability + MoonBDD 邻接成熟，应扩展而非重做 |
| GF256 增量包创新与欠秩中继重编码 | 4 | 4 | 5 | 5 | 4 | 选择；核心是任意方程、动态秩状态和欠秩 relay，不是固定分片恢复 |

## 检索范围与限制

MoonCakes 实际使用 `moon search <keyword> --limit 100`：fault tree、reliability、bdd、petri、reachability、units、dimension、rlnc、network coding、fountain、erasure、reed-solomon、fec、recoding、random linear、编码、linear coding、rank feedback。单次上限 100；结果为模糊匹配，子包展示存在“Showing 5 of ...”截断，不能把摘要展示等同于全部接口。对关键相邻项另取精确版本 manifest、README、公开接口、实现和测试。rlnc 无命中；fountain 命中为剧本格式/粒子喷泉而非 fountain code；recoding 中有 recording/replay 等噪声。无命中不等于不存在。

GitHub repository search 使用 per_page=100，核对 incomplete_results=false；检索 rlnc language:MoonBit、network coding（带 MoonBit 或 language:MoonBit）、recoding language:MoonBit、random linear language:MoonBit、fountain code moonbit 及各相邻项目名。已读官方 [awesome-moonbit](https://github.com/moonbitlang/awesome-moonbit) 清单。仓库搜索不保证覆盖未标语言、无索引、私有、刚创建的项目；没有把它当代码全量搜索。下载量只作为时点元数据，不用于否定低下载项目。

永久登记按字段/算法/用户任务读完整指纹，覆盖 reserved/completed/rejected/external-checked。MoonBench、MoonContract、MoonRecur、MoonShard 的保留边界没有用改名方式绕过；Petri、单位、BDD、可靠性与分片恢复的相邻指纹均纳入比较。MoonRecoder 在实现前持锁原子预留，最终状态须在交付核验后才更新。

## 实际源码/测试检查

| 项目与版本 | 实际检查的文件 / 来源 | 语义结论 |
|---|---|---|
| [MoonErasure](https://github.com/oyjh0381/MoonErasure), oyjh0381/moonerasure@0.2.0, Apache-2.0 | README、pkg.generated.mbti、codec.mbt、matrix.mbt、catalog_test、catalog_extension_test、bundle_test、bundle_stream_test、LICENSE、manifest | 固定索引 Reed–Solomon 分片、范围恢复/修复、目录与包流，成熟且近期维护。不重做该对象/分片工作流。 |
| [CAIMEOX/reed_solomon@0.1.0](https://mooncakes.io/docs/CAIMEOX/reed_solomon@0.1.0/), Apache-2.0 | README、src/decoder.mbt、LICENSE、旧版模块 metadata | 多项式纠错，不提供任意包方程的增量接纳或欠秩中继。旧元数据不足以断言停止维护。 |
| [moonbit-shard-note](https://github.com/JJ-ai-nb/moonbit-shard-note), 0.2.1, Apache-2.0 | README、pkg.generated.mbti、resilient.mbt、resilient_test.mbt、LICENSE、exact manifest | 可打印短消息卡片、固定数据/校验卡索引、整副牌诊断/恢复。线性求解原语相邻，但不是动态 relay span 或网络代反馈会话。 |
| [MoonBDD](https://github.com/oyjh0381/MoonBDD), 0.1.0, Apache-2.0 | README、analysis.mbt、公开接口、analysis_test.mbt、LICENSE、manifest | ROBDD / 符号状态分析，故障树候选不宜再做独立近似项目。 |
| [moonpetri](https://mooncakes.io/docs/okMambaOut/moonpetri@0.1.4/), MIT | README、commands.mbt、公开接口、invariants_test.mbt、LICENSE、manifest | 可达性/不变量/命令入口已完整；对应候选淘汰。登记同时记录后续仓库重命名，不以失效旧名规避查重。 |
| [LunarUnits](https://github.com/FrozenLemonTee/LunarUnits), 0.1.9, Apache-2.0 | README、affine/affine.mbt、根/affine/physics 接口、affine_test、physical_constants_test、LICENSE、manifest | 单位/仿射与常量能力已成熟，候选淘汰。 |
| [moon-reliability](https://github.com/wcx789ll/moon-reliability), 0.3.3, Apache-2.0 | README、accelerated_life.mbt、公开接口、boundary_test、confidence_test、LICENSE、manifest | 可靠性/寿命/统计模型广，应贡献扩展而不是再建高度相邻工程。 |

## 核心能力矩阵

“未见”仅指上述版本的实际检查范围，不表示永久断言。性能不作未测比较。

| 能力 / 数据模型 | MoonRecoder 0.1.0 | MoonErasure 0.2.0 | shard-note 0.2.1 | CAIMEOX RS 0.1.0 |
|---|---|---|---|---|
| 基础有限域/线性算法 | GF256 / RREF | GF256 / RS 矩阵 | GF256 / 卡片线性求解 | 多项式纠错 |
| 固定索引分片任意 k 恢复 | 不保证 | 核心能力 | 固定数据/校验卡恢复 | 不同纠错模型 |
| 任意显式系数包增量创新 / 依赖 / 矛盾事务 | 核心 | 未见同类公共会话 | 未见 | 未见 |
| **欠秩中继不用恢复源即可重编码** | 核心 | 未见 | 未见 | 未见 |
| 当前主元反馈与确定性补空间修复 | 支持，hint 非认证 | 分片缺失/范围修复，语义不同 | 缺卡诊断，语义不同 | 未见 |
| 对象目录、范围读取、持久化修复包 | 不做 | 支持 | 打印布局/卡片审计 | 不做 |
| 代际交错流 / 字段单元预算 / 事件重放 | 支持 | 固定分片帧/目录模型 | 文本卡片/整副牌模型 | 未见 |

若仅需要固定分片丢失恢复，应优先使用/贡献 MoonErasure；若需要纸面恢复卡片，应使用 shard-note。把这些项目扩成 RLNC 需要改变固定索引输入、恢复保证和会话状态合同，不是简单补一个帮助函数。独立工程的必要性在于该不兼容的输入/状态/验收模型，而非新增 GF256 或 CRC。MoonRecoder 不宣称优于或替代这些项目；没有复制其源码。

## 反向复核与放行边界

实现完成后再按“rlnc / network coding / incomplete relay / random linear / rank feedback”反向检索。2026-10-14：四组 GitHub 查询均 total_count=0 且 incomplete_results=false；MoonCakes rlnc 无命中，random linear 26 项主要为数值线代/随机流，rank feedback 1 项为图像库。又实际补查 shard-note 的实现/测试，并核对成品公开接口：确实包含欠秩 Relay.mix、事务 Decoder.admit_batch、Feedback 和 Replay，而非把 RS 包换名字。

放行结论：在已检查的公开范围内，没有发现相同核心合同且维护良好的直接替代；相邻成熟项目已承认且明确区隔。证据受检索上限、索引时延和读取范围限制，不作“首个/唯一/绝无重复”保证。发布前再次核对永久登记；若发现直接重合，应停止发布并重新评估。
