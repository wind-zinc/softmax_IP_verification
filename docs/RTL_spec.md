# 参数化 CORDIC Softmax IP 简要规格

### Author : Wenbo Shao @IMECAS, R.Zine @IHEP.

## 1. 功能概述

该 RTL 接收一组并行定点输入，计算对应的 Softmax 概率向量：

```text
y[i] = exp(x[i] - max(x)) / Σ exp(x[j] - max(x))
```

在指数运算前减去全局最大值，可避免正指数溢出。每个输入 lane 使用独立的流水线 CORDIC 单元计算指数，随后通过流水加法树求和，最后执行定点除法得到归一化概率。

顶层模块名称为：

```text
softmax_complete_top
```

## 2. 参数
```text
| 参数 				| 默认值 	| 说明 								|
| `DATA_WIDTH` 		| 32 		| 每个输入、输出元素的位宽 			|
| `FRACTIONAL_BITS` | 16 		| 定点小数位数，默认格式为 Q16.16 	|
| `NUM_ELEMENTS` 	| 8 		| 并行输入和输出的元素数量 			|
```
内部参数自动计算：

```text
TREE_LEVELS = max(1, ceil(log2(NUM_ELEMENTS)))
SUM_WIDTH   = DATA_WIDTH + TREE_LEVELS
```

设计支持非 2 次幂并行路数。树结构会扩展到不小于 `NUM_ELEMENTS` 的下一个 2 次幂：

- 最大值树的空叶子填充为最小有符号数。
- 累加树的空叶子填充为零。

已验证的 `NUM_ELEMENTS` 配置为 4、8、13 和 16。

## 3. 顶层接口
```text
| 信号 					| 方向 		| 位宽 							| 说明 						|
| `clk` 				| input 	| 1 							| 工作时钟，上升沿触发 		|
| `rst_n` 				| input 	| 1 							| 异步低有效复位 			|
| `array_in` 			| input 	| `NUM_ELEMENTS × DATA_WIDTH` 	| 并行有符号定点输入向量 	|
| `array_valid` 		| input 	| 1 							| 输入向量有效指示 			|	
| `softmax_array_out` 	| output 	| `NUM_ELEMENTS × DATA_WIDTH` 	| 并行无符号定点概率向量 	|
| `softmax_valid` 		| output 	| 1 							| 输出向量有效指示 			|
```
第 `i` 个元素在打包总线中的位置为：

```systemverilog
array_in[i*DATA_WIDTH +: DATA_WIDTH]
softmax_array_out[i*DATA_WIDTH +: DATA_WIDTH]
```

输入元素按有符号定点数解释；输出元素按无符号定点概率解释。默认 Q16.16 格式下：

```text
real_value = fixed_value / 65536.0
```

本轮功能验证使用的输入实数范围为 `[-4, 4]`。

## 4. 数据传输规则

### 4.1 输入

- 当 `array_valid == 1` 时，`array_in` 中的全部 `NUM_ELEMENTS` 个元素构成一笔事务。
- RTL 没有 ready 信号，不能对输入施加反压。
- 设计为流水线结构，可以接收连续周期有效的输入事务。
- 当 `array_valid == 0` 时，该周期不产生新的有效事务。

### 4.2 输出

- 当 `softmax_valid == 1` 时，`softmax_array_out` 中的全部元素构成一笔有效 Softmax 输出事务。
- 输出顺序与有效输入顺序一致。
- 输入气泡会在固定流水延迟后表现为输出气泡。
- 当 `softmax_valid == 0` 时，不应使用 `softmax_array_out` 进行功能判断。

## 5. RTL 数据通路

### 5.1 流水最大值树

`tree_max_finder` 对所有输入元素进行二叉比较。每一级比较结果均寄存，因此最大值查找延迟为 `TREE_LEVELS` 个流水级。

原始输入向量沿独立延迟链同步延迟，使其与最终最大值对齐。

### 5.2 减最大值

对每个 lane 计算：

```text
cordic_input[i] = array_in[i] - global_max
```

因此所有 CORDIC 输入均小于或等于零，至少一路输入为零。

### 5.3 并行 CORDIC 指数计算

每个 lane 实例化一个 `cordic_top`，计算：

```text
exp_array[i] ≈ exp(cordic_input[i])
```

CORDIC 数据通路包含：

- 指数范围预处理。
- 16 级 CORDIC 迭代流水线。
- 指数缩放后处理。

所有 lane 使用同一个输入 valid，并按相同延迟输出。

### 5.4 流水累加树

`tree_accumulator` 对所有指数结果求和：

```text
sum = Σ exp_array[i]
```

二叉加法树逐级寄存，流水级数为 `TREE_LEVELS`。累加位宽扩展为 `SUM_WIDTH`，降低多路相加产生溢出的风险。

### 5.5 定点除法

divider 将指数向量延迟到与累加结果对齐，然后计算：

```text
softmax_array_out[i] = (exp_array[i] << FRACTIONAL_BITS) / sum
```

当前验证版 divider 使用 Verilog `/` 运算符实现功能模型。后续替换为 Vivado Divider IP 时，需要保持输入输出数值格式、valid 对齐和顶层可见延迟一致，或同步更新验证配置。

如果 `sum == 0`，divider 输出全零并拉高对应的 `softmax_valid`。对于合法 Softmax 数据，由于减最大值后至少一路满足 `exp(0) = 1`，零分母属于防御性分支，正常工作时不可达。

## 6. 延迟与吞吐

当前 UVM monitor 观察到的输入到输出延迟为：

```text
LATENCY = 22 + 2 × TREE_LEVELS
```
```text
| NUM_ELEMENTS 	| TREE_LEVELS 	| Monitor 观察延迟 	|
| 4 			| 2 			| 26 cycles 		|
| 8 			| 3 			| 28 cycles 		|
| 13 			| 4 			| 30 cycles 		|
| 16 			| 4 			| 30 cycles 		|
```
该数值包含 monitor clocking block 的采样口径。若从 RTL 寄存器边界采用不同方式定义延迟，可能出现一拍的计数口径差异，因此 testbench 应统一以输入 monitor 和输出 monitor 的时间戳差作为判断标准。

流水线充满后，RTL 支持每个周期接收一笔输入，并在对应延迟后每个周期产生一笔输出。

## 7. 复位行为

`rst_n` 为异步低有效复位：

- 清零各级数据寄存器和 valid 流水线。
- 取消流水线内尚未输出的事务。
- 复位期间 `softmax_valid` 无效。
- 释放复位后，新的有效输入从空流水线重新开始处理。

验证环境在运行时复位时同步清空 reference model、scoreboard 和 coverage 中尚未完成配对的事务。

## 8. 数值行为

理想情况下输出满足：

```text
0 <= softmax[i] <= 1
Σ softmax[i] ≈ 1
```

由于 CORDIC 近似、定点截断和整数除法，RTL 输出与双精度数学模型之间允许存在小量 LSB 误差。本轮验证采用 66 LSB 容差；4、8、13、16 路回归中观测到的误差均未超过 16 LSB。

## 9. 参数与使用限制

- `NUM_ELEMENTS` 必须大于等于 1。
- `FRACTIONAL_BITS` 必须位于 0 到 `DATA_WIDTH` 之间。
- `SUM_WIDTH` 不应小于 `DATA_WIDTH + TREE_LEVELS`。
- 当前主要验证配置为 32 位 Q16.16，未执行其他定点格式的完整回归。
- 本规格描述功能仿真行为，不包含综合后 Fmax、面积、功耗及目标 FPGA Divider IP 的时序承诺。

