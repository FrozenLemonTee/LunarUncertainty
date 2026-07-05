# LunarUncertainty

LunarUncertainty 是一个面向 MoonBit 的测量不确定度基础库。它基于
[LunarUnits](https://github.com/FrozenLemonTee/LunarUnits) 构建，让测量值在
携带单位的同时，也携带标准不确定度，并在运算时自动传播不确定度。

第一版采用常见的工程计算模型：

```text
x = nominal ± standard_uncertainty
```

也就是说，`MeasuredQuantity` 表示一个名义值加一个对称的标准不确定度。
变量默认相互独立，加法、减法、乘法、除法和整数幂使用一阶不确定度传播规则。

## 功能

- `MeasuredQuantity`：一个名义值、一个非负标准不确定度和一个共享的 LunarUnits 单位。
- 可从两个 LunarUnits `Quantity` 构造，兼容单位会自动换算并规范化。
- 单位换算会同时转换名义值和不确定度。
- 加法和减法使用平方和开根传播绝对不确定度。
- 乘法、除法和整数幂使用相对不确定度传播。
- 对负不确定度、相对传播中的零名义值提供结构化错误。
- 简单格式化，并支持 LunarUnits 的 `FormatStyle`。

## 安装

```bash
moon add FrozenLemonTee/LunarUncertainty
```

然后导入测量包和需要的 LunarUnits 包：

```moonbit
import {
  "FrozenLemonTee/LunarUncertainty/measure",
  "FrozenLemonTee/LunarUnits/quantities/qgeometry",
  "FrozenLemonTee/LunarUnits/quantities/qsi",
}
```

## 快速开始

```moonbit
let distance = @measure.MeasuredQuantity::new(
  @qgeometry.meters(10.0),
  @qgeometry.meters(0.2),
)
let time = @measure.MeasuredQuantity::new(
  @qsi.seconds(2.0),
  @qsi.seconds(0.1),
)

let speed = distance.div(time)
let text = @measure.format_measured_quantity(speed)
// "5 ± 0.26925824035672524 m/s"
```

不确定度可以使用与名义值不同但兼容的单位：

```moonbit
let length = @measure.MeasuredQuantity::new(
  @qgeometry.meters(10.0),
  @qgeometry.centimeters(20.0),
)
// 内部规范化为 10.0 ± 0.2 m。
```

量纲错误仍由 LunarUnits 处理，因此 `10 m ± 1 s` 这类输入会保留
`Quantity` 的维度不匹配信息。

## 统计边界

LunarUncertainty 第一版只表示对称标准不确定度，不实现不对称区间、相关变量、
协方差矩阵、概率分布、Monte Carlo 传播、置信区间或自动有效数字舍入。需要这些
策略时，应用层可以在本库之上继续扩展。

## 开发

运行测试：

```bash
moon test
```

提交前更新接口并格式化：

```bash
moon info
moon fmt
```
