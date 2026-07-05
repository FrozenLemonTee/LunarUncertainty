# LunarUncertainty

LunarUncertainty is a small MoonBit library for measured values with units and
standard uncertainty propagation. It builds on
[LunarUnits](https://github.com/FrozenLemonTee/LunarUnits), so measured values
keep the same dimension checks, unit conversions, composite units and formatters
as ordinary `Quantity` values.

The first release focuses on the common engineering model:

```text
x = nominal ± standard_uncertainty
```

`MeasuredQuantity` assumes independent variables and uses first-order
uncertainty propagation for addition, subtraction, multiplication, division and
integer powers.

## Features

- `MeasuredQuantity`: one nominal value, one non-negative standard uncertainty
  and one shared LunarUnits unit.
- Construction from two LunarUnits `Quantity` values, with compatible
  uncertainty units normalized into the nominal unit.
- Unit conversion for both nominal value and uncertainty.
- Addition/subtraction with root-sum-square absolute uncertainty propagation.
- Multiplication/division/powers with relative uncertainty propagation.
- Structured errors for negative uncertainty and zero nominal values in
  relative propagation paths.
- Simple formatting with LunarUnits `FormatStyle` support.

## Installation

```bash
moon add FrozenLemonTee/LunarUncertainty
```

Then import the measurement package and the LunarUnits packages you need:

```moonbit
import {
  "FrozenLemonTee/LunarUncertainty/measure",
  "FrozenLemonTee/LunarUnits/quantities/qgeometry",
  "FrozenLemonTee/LunarUnits/quantities/qsi",
}
```

## Quick Start

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

A compatible uncertainty unit is converted automatically:

```moonbit
let length = @measure.MeasuredQuantity::new(
  @qgeometry.meters(10.0),
  @qgeometry.centimeters(20.0),
)
// Stored as 10.0 ± 0.2 m.
```

Dimension errors still come from LunarUnits, so `10 m ± 1 s` is rejected with
the same dimension mismatch information users get from `Quantity`.

## Statistical Boundary

This library models symmetric standard uncertainty only. It does not implement
asymmetric intervals, correlations, covariance matrices, probability
distributions, Monte Carlo propagation, confidence intervals or automatic
significant-figure rounding. Applications can layer those policies on top when
they need them.

## Development

Run the full test suite:

```bash
moon test
```

Update generated interfaces and formatting before review:

```bash
moon info
moon fmt
```
