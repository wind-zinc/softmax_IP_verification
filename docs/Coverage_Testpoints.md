# Softmax IP 功能覆盖测试点说明

## 1. 文档目的

本文档说明 Softmax IP 验证环境中采集的功能覆盖测试点。覆盖率由 `softmax_coverage` 和 `softmax_scoreboard` 两部分共同完成：

- `softmax_coverage`：采集输入特征、输出特征、连续流、气泡、复位和延迟。
- `softmax_scoreboard`：采集逐元素误差和整笔事务最大误差。

覆盖率按 `NUM_ELEMENTS` 参数化，已对 4、8、13、16 路配置执行回归。其中 13 路用于覆盖非 2 次幂 padding 路径。

## 2. 采样条件
```text
| 覆盖对象    	| 采样条件 														  	  	|
| 输入特征 		| `rst_n == 1` 且 `array_valid == 1`，input monitor 发布输入事务时采样	|
| 输出特征 		| `softmax_valid == 1`，output monitor 发布输出事务时采样 				|
| Burst/Gap 	| coverage component 每个 monitor clocking block 周期观察 `array_valid`   |
| 复位 			| 检测到一次新的低有效复位区间时采样 								    	|
| 延迟 			| 输入事务入队时间戳与对应输出事务时间戳配对后采样 			    			|
| 数值误差		| scoreboard 成功配对 expected transaction 和 actual transaction 后采样   |
```
如果输入或输出含有 X/Z，coverage component 会增加 unknown 计数并报告 warning，不使用该事务更新正常功能 covergroup。

## 3. 输入覆盖 `input_cg`

### 3.1 最大值所在 lane

`cp_max_index` 为每个输入 lane 建立一个 bin，确认最大输入值可以出现在任意并行位置：

```text
0 ... NUM_ELEMENTS-1
```

当存在多个相同最大值时，`max_index` 记录第一次出现最大值的位置；并列关系由独立的最大值并列 coverpoint 统计。

### 3.2 输入符号组合

`cp_sign` 统计以下输入向量：

- 全负数。
- 全正数。
- 全零。
- 同时包含正数和负数。
- 仅包含非负数且至少含一个零。
- 仅包含非正数且至少含一个零。

### 3.3 输入动态范围

输入动态范围定义为：

```text
span = maximum(input) - minimum(input)
```

`cp_range` 的分箱如下：
```text
| 分箱     | Q16.16 数值条件	   	|
| Zero   | `span == 0`			|
| Small  | `0 < span <= 1.0` 	|
| Medium | `1.0 < span <= 4.0` 	|
| Large  | `span > 4.0`			|
```
### 3.4 最大值并列关系

`cp_max_tie` 检查：

- 唯一最大值。
- 部分 lane 并列最大值。
- 所有 lane 全部相等。

### 3.5 输入排列顺序

`cp_order` 检查：

- 所有元素相等。
- 单调非递减。
- 单调非递增。
- 无序排列。

### 3.6 输入综合场景

`cp_scenario` 将最大值并列关系和动态范围组合为以下场景：

- 均匀输入：全部元素相等。
- 非均匀并列：部分元素并列最大。
- 唯一最大值、小动态范围。
- 唯一最大值、中动态范围。
- 唯一最大值、大动态范围。

### 3.7 输入边界值

`cp_boundary` 检查输入是否命中验证配置中的最小值和最大值：

- 不包含边界值。
- 仅包含最小值。
- 仅包含最大值。
- 同时包含最小值和最大值。

当前验证配置的输入范围为 `[-4, 4]`。

### 3.8 零值存在性

`cp_contains_zero` 检查输入向量中：

- 不含零。
- 至少含一个零。

### 3.9 输入交叉覆盖

`x_unique_lane_by_range` 仅在最大值唯一时采样，并交叉：

```text
最大值所在 lane × Small/Medium/Large 动态范围
```

该 cross 用于证明每个 lane 都能在不同动态范围下成为唯一最大值。`RANGE_ZERO` 因为不可能具有唯一最大值而被忽略。

## 4. 输出覆盖 `output_cg`

输出按无符号 Q16.16 概率解释，理论概率和接近 `1.0`。

### 4.1 最大概率所在 lane

`cp_max_index` 为每个输出 lane 建立一个 bin，检查最大 Softmax 概率能够出现在任意输出位置。

### 4.2 最大概率峰值

`cp_peak` 根据最大输出概率分箱：
```text
| 分箱 		| 概率范围							|
| Low 		| `max_probability <= 0.25` 		|
| Medium 	| `0.25 < max_probability <= 0.50`	|
| High 		| `0.50 < max_probability <= 0.75` 	|
| Near one 	| `max_probability > 0.75` 			|
```
### 4.3 近零输出元素

输出值小于或等于 `TOLERANCE_LSB` 时视为近零元素。当前容差为 66 LSB。

`cp_near_zero` 检查：

- 没有近零元素。
- 部分元素接近零。
- 所有元素均接近零。

“所有元素均接近零”定义为 `illegal_bins`，因为合法 Softmax 输出的概率和应接近 1，不应全部接近零。

### 4.4 输出最大值并列关系

`cp_max_tie` 检查：

- 唯一最大概率。
- 部分输出并列最大概率。
- 所有输出概率相等。

### 4.5 概率和

令：

```text
expected_sum = 1 << FRACTIONAL_BITS
sum_difference = abs(sum(softmax_array_out) - expected_sum)
```

`cp_sum` 分为：

- Exact：概率定点和严格等于 1.0。
- Near：与 1.0 的差不超过 `NUM_ELEMENTS × TOLERANCE_LSB`。
- Outside：超出上述范围，定义为 `illegal_bins`。

### 4.6 输出综合场景

`cp_scenario` 检查：

- 均匀分布：所有输出相等。
- 非均匀并列：部分最大概率并列。
- 分散分布：唯一最大值且峰值处于 Low 或 Medium。
- 集中分布：唯一最大值且峰值处于 High 或 Near one。

### 4.7 输出交叉覆盖

`x_unique_lane_by_peak` 仅在最大概率唯一时交叉：

```text
最大概率所在 lane × Low/Medium/High/Near-one 峰值区间
```

该 cross 检查不同输出集中程度下，任意 lane 成为唯一最大概率位置的能力。

## 5. 连续流与气泡覆盖

### 5.1 Burst 长度 `burst_cg`

连续多个周期 `array_valid == 1` 被视为一个 burst：
```text
| 分箱 		| 长度 		|
| Single 	| 1 		|
| Short 	| 2–4 		|
| Medium 	| 5–16 		|
| Long 		| 17 及以上   |
```
### 5.2 Gap 长度 `gap_cg`

已经出现流量后，两个有效输入 burst 之间连续的 `array_valid == 0` 周期被视为 gap：
```text
| 分箱 		| 长度 		|
| Single 	| 1 		|
| Short 	| 2–4 		|
| Long 		| 5 及以上 	|
```
## 6. 复位覆盖 `reset_cg`

复位分为：

- Initial reset：复位前尚未出现有效输入事务。
- Runtime reset：已经出现流量后再次复位。

进入复位时，coverage component 会结束正在统计的 burst，并清空尚未配对的输入时间戳，避免复位前后事务错误配对。

## 7. 延迟覆盖 `latency_cg`

输入和输出事务按顺序配对，并依据 monitor 时间戳计算延迟。预期 monitor 可见延迟为：

```text
TREE_LEVELS = max(1, ceil(log2(NUM_ELEMENTS)))
EXPECTED_LATENCY_CYCLES = 22 + 2 × TREE_LEVELS
```

对应已验证配置：
```text
| NUM_ELEMENTS 	| TREE_LEVELS 	| 预期延迟 	|
| 4 			| 2 			| 26 cycles |
| 8 			| 3 			| 28 cycles |
| 13 			| 4 			| 30 cycles |
| 16 			| 4 			| 30 cycles |
```
`latency_cg` 包含：

- Expected latency：合法延迟 bin。
- Too short：小于预期延迟，`illegal_bins`。
- Too long：大于预期延迟，`illegal_bins`。

## 8. Scoreboard 数值误差覆盖

### 8.1 逐 lane 误差 `lane_error_cg`

对每个输出 lane 计算：

```text
error_lsb = abs(actual - expected)
```

覆盖分箱为：

- Exact：0 LSB。
- 1–4 LSB。
- 5–16 LSB。
- 17–32 LSB。
- 33–66 LSB。
- 超过 66 LSB：`illegal_bins`。

同时采样 lane index，从而确认每个并行位置均执行过误差检查。

### 8.2 整笔事务最大误差 `transaction_error_cg`

取一笔 Softmax 输出向量中所有 lane 的最大误差，并使用与逐 lane 误差相同的分箱。超过 66 LSB 定义为非法事务。

较大误差分箱未命中表示数值精度良好，不代表测试激励缺失，因此不应仅为了提高功能覆盖率而故意制造错误结果。

## 9. 覆盖率关闭原则

以下测试点应作为主要关闭目标：

- 输入特征覆盖。
- 输出主要行为覆盖。
- Burst 与 gap 覆盖。
- 初始复位与运行时复位。
- 参数相关固定延迟。
- 超容差误差、非法概率和、全近零输出、过短延迟和过长延迟均为零命中。

以下覆盖缺口需要分析后 waiver，而不是盲目补激励：

- 数学上不可达的输出组合。
- 非法参数保护分支。
- 合法 Softmax 输入下不可达的零分母。
- 静态 CORDIC ROM 总线及合法数值范围导致的低 toggle。
- 因误差始终较小而未命中的大误差统计分箱。
