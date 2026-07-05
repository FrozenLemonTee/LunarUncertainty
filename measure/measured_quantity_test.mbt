///|
fn assert_close(actual : Double, expected : Double) -> Unit raise {
  let diff = if actual > expected {
    actual - expected
  } else {
    expected - actual
  }
  assert_true(diff < 0.000000001)
}

///|
test "construct normalizes compatible uncertainty unit" {
  let length = MeasuredQuantity::new(
    @qgeometry.meters(10.0),
    @qgeometry.centimeters(20.0),
  )
  assert_eq(length.value(), 10.0)
  assert_eq(length.uncertainty(), 0.2)
  assert_true(length.unit().is_compatible(@si.meter))
}

///|
test "construct rejects incompatible uncertainty dimension" {
  let mut caught = false
  try
    MeasuredQuantity::new(@qgeometry.meters(10.0), @qsi.seconds(1.0)) |> ignore
  catch {
    @quantity.DimensionMismatch((expected, actual)) => {
      caught = true
      assert_true(expected.is_same(@dimension.Dimension::length()))
      assert_true(actual.is_same(@dimension.Dimension::time()))
    }
    _ => ()
  }
  assert_true(caught)
}

///|
test "construct rejects negative uncertainty" {
  let mut caught = false
  try MeasuredQuantity::from_parts(10.0, -0.2, @si.meter) |> ignore catch {
    NegativeUncertainty => caught = true
  }
  assert_true(caught)
}

///|
test "checked constructors return none for invalid inputs" {
  assert_true(
    MeasuredQuantity::checked_from_parts(10.0, -0.2, @si.meter) is None,
  )
  assert_true(
    MeasuredQuantity::checked_new(@qgeometry.meters(10.0), @qsi.seconds(1.0))
    is None,
  )
}

///|
test "conversion converts value and uncertainty" {
  let length = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
  let cm = length.to(@geometry.centimeter)
  assert_eq(cm.value(), 1000.0)
  assert_eq(cm.uncertainty(), 20.0)
  assert_true(length.checked_to(@si.second) is None)
}

///|
test "add and sub propagate absolute uncertainty" {
  let x = MeasuredQuantity::from_parts(10.0, 0.3, @si.meter)
  let y = MeasuredQuantity::from_parts(50.0, 40.0, @geometry.centimeter)
  let sum = x.add(y)
  assert_eq(sum.value(), 10.5)
  assert_close(sum.uncertainty(), 0.5)
  let diff = x.sub(y)
  assert_eq(diff.value(), 9.5)
  assert_close(diff.uncertainty(), 0.5)
  assert_true(
    x.checked_add(MeasuredQuantity::from_parts(1.0, 0.1, @si.second)) is None,
  )
  assert_true(
    x.checked_sub(MeasuredQuantity::from_parts(1.0, 0.1, @si.second)) is None,
  )
}

///|
test "mul propagates relative uncertainty and composes units" {
  let width = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
  let height = MeasuredQuantity::from_parts(3.0, 0.2, @si.meter)
  let area = width.mul(height)
  assert_eq(area.value(), 6.0)
  assert_close(area.uncertainty(), 0.5)
  assert_true(area.unit().is_compatible(@si.meter.pow(2)))
}

///|
test "div propagates relative uncertainty and composes units" {
  let distance = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
  let time = MeasuredQuantity::from_parts(2.0, 0.1, @si.second)
  let speed = distance.div(time)
  assert_eq(speed.value(), 5.0)
  assert_close(speed.uncertainty(), 0.26925824035672524)
  assert_true(speed.unit().is_compatible(@si.meter / @si.second))
}

///|
test "pow propagates relative uncertainty" {
  let length = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
  let area = length.pow(2)
  assert_eq(area.value(), 4.0)
  assert_close(area.uncertainty(), 0.4)
  assert_true(area.unit().is_compatible(@si.meter.pow(2)))
  let one = length.pow(0)
  assert_eq(one.value(), 1.0)
  assert_eq(one.uncertainty(), 0.0)
}

///|
test "scale preserves non-negative uncertainty" {
  let scaled = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter).scale(-3.0)
  assert_eq(scaled.value(), -6.0)
  assert_close(scaled.uncertainty(), 0.3)
}

///|
test "relative paths reject zero nominal values" {
  let zero = MeasuredQuantity::from_parts(0.0, 0.1, @si.meter)
  let other = MeasuredQuantity::from_parts(2.0, 0.1, @si.second)
  let mut mul_caught = false
  try zero.mul(other) |> ignore catch {
    ZeroNominalForRelativeUncertainty => mul_caught = true
  }
  assert_true(mul_caught)
  let mut div_caught = false
  try other.div(zero) |> ignore catch {
    ZeroNominalForRelativeUncertainty => div_caught = true
  }
  assert_true(div_caught)
  let mut pow_caught = false
  try zero.pow(2) |> ignore catch {
    ZeroNominalForRelativeUncertainty => pow_caught = true
  }
  assert_true(pow_caught)
}

///|
test "quantity bridges and formatting" {
  let speed = MeasuredQuantity::from_parts(5.0, 0.3, @si.meter / @si.second)
  assert_eq(speed.value_quantity().value(), 5.0)
  assert_eq(speed.uncertainty_quantity().value(), 0.3)
  assert_eq(speed.relative_uncertainty(), 0.06)
  assert_eq(format_measured_quantity(speed), "5 ± 0.3 m/s")
  assert_eq(
    format_measured_quantity_with(speed, @unit.FormatStyle::Latex),
    "5 ± 0.3 \\mathrm{m}/\\mathrm{s}",
  )
}
