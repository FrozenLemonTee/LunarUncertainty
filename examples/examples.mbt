///|
/// A speed measurement from distance and time measurements.
test "speed measurement example" {
  let distance = @measure.MeasuredQuantity::new(
    @quantity.Quantity::new(10.0, @si.meter),
    @quantity.Quantity::new(0.2, @si.meter),
  )
  let time = @measure.MeasuredQuantity::new(
    @quantity.Quantity::new(2.0, @si.second),
    @quantity.Quantity::new(0.1, @si.second),
  )
  let speed = distance.div(time)
  assert_eq(speed.value(), 5.0)
  assert_true(speed.unit().is_compatible(@si.meter / @si.second))
}
