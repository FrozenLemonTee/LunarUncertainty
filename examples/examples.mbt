///|
/// A speed measurement from distance and time measurements.
test "speed measurement example" {
  let distance = @measure.MeasuredQuantity::new(
    @qgeometry.meters(10.0),
    @qgeometry.meters(0.2),
  )
  let time = @measure.MeasuredQuantity::new(
    @qsi.seconds(2.0),
    @qsi.seconds(0.1),
  )
  let speed = distance.div(time)
  assert_eq(speed.value(), 5.0)
  assert_true(speed.unit().is_compatible(@si.meter / @si.second))
}

///|
/// Relative uncertainty is often the natural input form for instruments.
test "relative uncertainty example" {
  let length = @measure.MeasuredQuantity::from_relative(
    @qgeometry.meters(10.0),
    0.02,
  )
  assert_eq(length.value(), 10.0)
  assert_eq(length.uncertainty(), 0.2)
}

///|
/// Density combines mass and volume units without hand-written conversion.
test "density measurement example" {
  let mass = @measure.MeasuredQuantity::new(
    @qmass.kilograms(12.0),
    @qmass.kilograms(0.1),
  )
  let volume = @measure.MeasuredQuantity::new(
    @qgeometry.liters(3.0),
    @qgeometry.liters(0.05),
  )
  let density = mass.div(volume)
  let density_si = density.to(@mass.kilogram_per_cubic_meter)
  assert_eq(density_si.value(), 4000.0)
}

///|
/// Electrical power composes voltage and current into watts.
test "electrical power measurement example" {
  let voltage = @measure.MeasuredQuantity::new(
    @qelectromagnetism.volts(12.0),
    @qelectromagnetism.volts(0.1),
  )
  let current = @measure.MeasuredQuantity::new(
    @qsi.amperes(2.0),
    @qsi.amperes(0.02),
  )
  let power = voltage.mul(current)
  assert_eq(power.value(), 24.0)
  assert_true(power.unit().is_compatible(@mechanics.watt))
}
