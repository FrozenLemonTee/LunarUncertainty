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
