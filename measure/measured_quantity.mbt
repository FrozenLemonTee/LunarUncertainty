///|
/// Raised when constructing a measured quantity with a negative standard
/// uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   let mut caught = false
///   try MeasuredQuantity::from_parts(1.0, -0.1, @si.meter) |> ignore catch {
///     NegativeUncertainty => caught = true
///   }
///   assert_true(caught)
/// }
/// ```
pub suberror NegativeUncertainty {
  NegativeUncertainty
} derive(Eq, Debug)

///|
/// Raised when a propagation rule needs relative uncertainty but a nominal value
/// is zero.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(0.0, 0.1, @si.meter)
///   let y = MeasuredQuantity::from_parts(2.0, 0.1, @si.second)
///   let mut caught = false
///   try x.div(y) |> ignore catch {
///     ZeroNominalForRelativeUncertainty => caught = true
///   }
///   assert_true(caught)
/// }
/// ```
pub suberror ZeroNominalForRelativeUncertainty {
  ZeroNominalForRelativeUncertainty
} derive(Eq, Debug)

///|
/// A measured value with a symmetric standard uncertainty.
///
/// `MeasuredQuantity` represents `value ± standard_uncertainty` in one shared
/// unit. Inputs may use compatible units, but construction normalizes the
/// uncertainty into the nominal value's unit.
///
/// # Example
///
/// ```mbt check
/// test {
///   let length = MeasuredQuantity::new(
///     @qgeometry.meters(10.0),
///     @qgeometry.centimeters(20.0),
///   )
///   assert_eq(length.value(), 10.0)
///   assert_eq(length.uncertainty(), 0.2)
/// }
/// ```
pub struct MeasuredQuantity {
  value : Double
  uncertainty : Double
  unit : @unit.Un
} derive(Eq, Debug)

///|
/// Manual `Show` for useful assertion diffs.
pub impl Show for MeasuredQuantity with fn output(self, logger) {
  logger.write_string(format_measured_quantity(self))
}

///|
/// Absolute value for doubles.
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
/// Absolute value for integers.
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
/// Integer power of a `Double`.
fn double_pow(base : Double, exponent : Int) -> Double {
  if exponent == 0 {
    return 1.0
  }
  let mut acc = 1.0
  let mut n = abs_int(exponent)
  while n > 0 {
    acc = acc * base
    n -= 1
  }
  if exponent < 0 {
    1.0 / acc
  } else {
    acc
  }
}

///|
/// Root-sum-square for two independent uncertainty components.
fn rss(a : Double, b : Double) -> Double {
  @math.pow(a * a + b * b, 0.5)
}

///|
/// Returns `uncertainty / abs(value)`, rejecting zero nominal values.
fn relative_component(
  value : Double,
  uncertainty : Double,
) -> Double raise ZeroNominalForRelativeUncertainty {
  if value == 0.0 {
    raise ZeroNominalForRelativeUncertainty
  }
  uncertainty / abs_double(value)
}

///|
/// Returns `uncertainty / abs(value)`, or `None` when the nominal value is zero.
fn checked_relative_component(value : Double, uncertainty : Double) -> Double? {
  if value == 0.0 {
    None
  } else {
    Some(uncertainty / abs_double(value))
  }
}

///|
/// Creates a measured quantity from a nominal value and standard uncertainty.
///
/// The uncertainty is converted into the nominal value's unit before storage.
/// Raises LunarUnits' `DimensionMismatch` for incompatible dimensions and
/// `NegativeUncertainty` when the converted uncertainty is negative.
///
/// # Example
///
/// ```mbt check
/// test {
///   let length = MeasuredQuantity::new(
///     @qgeometry.meters(10.0),
///     @qgeometry.centimeters(20.0),
///   )
///   assert_eq(length.uncertainty(), 0.2)
/// }
/// ```
pub fn MeasuredQuantity::new(
  value : @quantity.Quantity,
  uncertainty : @quantity.Quantity,
) -> MeasuredQuantity raise {
  let converted = uncertainty.to(value.unit())
  MeasuredQuantity::from_parts(value.value(), converted.value(), value.unit())
}

///|
/// Creates a measured quantity, returning `None` when dimensions are
/// incompatible or the uncertainty is negative.
///
/// # Example
///
/// ```mbt check
/// test {
///   let length = @qgeometry.meters(10.0)
///   let time = @qsi.seconds(1.0)
///   assert_true(MeasuredQuantity::checked_new(length, time) is None)
/// }
/// ```
pub fn MeasuredQuantity::checked_new(
  value : @quantity.Quantity,
  uncertainty : @quantity.Quantity,
) -> MeasuredQuantity? {
  match uncertainty.checked_to(value.unit()) {
    Some(converted) =>
      MeasuredQuantity::checked_from_parts(
        value.value(),
        converted.value(),
        value.unit(),
      )
    None => None
  }
}

///|
/// Creates a measured quantity from normalized parts.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   assert_eq(x.value(), 10.0)
///   assert_eq(x.uncertainty(), 0.2)
/// }
/// ```
pub fn MeasuredQuantity::from_parts(
  value : Double,
  uncertainty : Double,
  unit : @unit.Un,
) -> MeasuredQuantity raise NegativeUncertainty {
  if uncertainty < 0.0 {
    raise NegativeUncertainty
  }
  { value, uncertainty, unit }
}

///|
/// Creates a measured quantity from normalized parts, returning `None` for a
/// negative uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_true(
///     MeasuredQuantity::checked_from_parts(1.0, -0.1, @si.meter) is None,
///   )
/// }
/// ```
pub fn MeasuredQuantity::checked_from_parts(
  value : Double,
  uncertainty : Double,
  unit : @unit.Un,
) -> MeasuredQuantity? {
  if uncertainty < 0.0 {
    None
  } else {
    Some({ value, uncertainty, unit })
  }
}

///|
/// Creates a measured quantity from a nominal value and a relative standard
/// uncertainty.
///
/// `relative` is interpreted as `u(x) / abs(x)`. For example, `0.02` means a
/// two-percent standard uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   let length = MeasuredQuantity::from_relative(@qgeometry.meters(10.0), 0.02)
///   assert_eq(length.value(), 10.0)
///   assert_eq(length.uncertainty(), 0.2)
/// }
/// ```
pub fn MeasuredQuantity::from_relative(
  value : @quantity.Quantity,
  relative : Double,
) -> MeasuredQuantity raise NegativeUncertainty {
  if relative < 0.0 {
    raise NegativeUncertainty
  }
  {
    value: value.value(),
    uncertainty: abs_double(value.value()) * relative,
    unit: value.unit(),
  }
}

///|
/// Creates a measured quantity from a nominal value and relative standard
/// uncertainty, returning `None` when the relative uncertainty is negative.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_true(
///     MeasuredQuantity::checked_from_relative(@qgeometry.meters(10.0), -0.02)
///     is None,
///   )
/// }
/// ```
pub fn MeasuredQuantity::checked_from_relative(
  value : @quantity.Quantity,
  relative : Double,
) -> MeasuredQuantity? {
  if relative < 0.0 {
    None
  } else {
    Some({
      value: value.value(),
      uncertainty: abs_double(value.value()) * relative,
      unit: value.unit(),
    })
  }
}

///|
/// Returns the nominal value in this quantity's current unit.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_eq(MeasuredQuantity::from_parts(1.0, 0.1, @si.meter).value(), 1.0)
/// }
/// ```
pub fn MeasuredQuantity::value(self : MeasuredQuantity) -> Double {
  self.value
}

///|
/// Returns the standard uncertainty in this quantity's current unit.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_eq(
///     MeasuredQuantity::from_parts(1.0, 0.1, @si.meter).uncertainty(),
///     0.1,
///   )
/// }
/// ```
pub fn MeasuredQuantity::uncertainty(self : MeasuredQuantity) -> Double {
  self.uncertainty
}

///|
/// Returns the shared unit for the nominal value and uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   assert_true(
///     MeasuredQuantity::from_parts(1.0, 0.1, @si.meter)
///     .unit()
///     .is_compatible(@si.meter),
///   )
/// }
/// ```
pub fn MeasuredQuantity::unit(self : MeasuredQuantity) -> @unit.Un {
  self.unit
}

///|
/// Bridges the nominal value back to LunarUnits `Quantity`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
///   assert_eq(x.value_quantity().value(), 2.0)
/// }
/// ```
pub fn MeasuredQuantity::value_quantity(
  self : MeasuredQuantity,
) -> @quantity.Quantity {
  @quantity.Quantity::new(self.value, self.unit)
}

///|
/// Bridges the standard uncertainty back to LunarUnits `Quantity`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
///   assert_eq(x.uncertainty_quantity().value(), 0.1)
/// }
/// ```
pub fn MeasuredQuantity::uncertainty_quantity(
  self : MeasuredQuantity,
) -> @quantity.Quantity {
  @quantity.Quantity::new(self.uncertainty, self.unit)
}

///|
/// Returns the relative standard uncertainty `u(x) / abs(x)`.
///
/// This accessor follows `Double` division semantics for a zero nominal value.
/// Propagation operations that need relative uncertainty raise
/// `ZeroNominalForRelativeUncertainty` instead of silently using infinity.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   assert_eq(x.relative_uncertainty(), 0.02)
/// }
/// ```
pub fn MeasuredQuantity::relative_uncertainty(
  self : MeasuredQuantity,
) -> Double {
  self.uncertainty / abs_double(self.value)
}

///|
/// Returns the relative standard uncertainty, or `None` when the nominal value
/// is zero.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   match x.checked_relative_uncertainty() {
///     Some(relative) => assert_eq(relative, 0.02)
///     None => fail("expected relative uncertainty")
///   }
///   assert_true(
///     MeasuredQuantity::from_parts(0.0, 0.2, @si.meter).checked_relative_uncertainty()
///     is None,
///   )
/// }
/// ```
pub fn MeasuredQuantity::checked_relative_uncertainty(
  self : MeasuredQuantity,
) -> Double? {
  checked_relative_component(self.value, self.uncertainty)
}

///|
/// Converts both nominal value and uncertainty to a compatible target unit.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   let cm = x.to(@geometry.centimeter)
///   assert_eq(cm.value(), 1000.0)
///   assert_eq(cm.uncertainty(), 20.0)
/// }
/// ```
pub fn MeasuredQuantity::to(
  self : MeasuredQuantity,
  target : @unit.Un,
) -> MeasuredQuantity raise @quantity.DimensionMismatch {
  let value = self.value_quantity().to(target)
  let uncertainty = self.uncertainty_quantity().to(target)
  { value: value.value(), uncertainty: uncertainty.value(), unit: target }
}

///|
/// Converts both nominal value and uncertainty, returning `None` when
/// dimensions are incompatible.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   assert_true(x.checked_to(@si.second) is None)
/// }
/// ```
pub fn MeasuredQuantity::checked_to(
  self : MeasuredQuantity,
  target : @unit.Un,
) -> MeasuredQuantity? {
  match
    (
      self.value_quantity().checked_to(target),
      self.uncertainty_quantity().checked_to(target),
    ) {
    (Some(value), Some(uncertainty)) =>
      Some({
        value: value.value(),
        uncertainty: uncertainty.value(),
        unit: target,
      })
    _ => None
  }
}

///|
/// Adds two independent measured quantities, converting `other` into `self`'s
/// unit first. The uncertainty is propagated by root-sum-square.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.3, @si.meter)
///   let y = MeasuredQuantity::from_parts(5.0, 0.4, @si.meter)
///   let sum = x.add(y)
///   assert_eq(sum.value(), 15.0)
///   assert_eq(sum.uncertainty(), 0.5)
/// }
/// ```
pub fn MeasuredQuantity::add(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity raise @quantity.DimensionMismatch {
  let converted = other.to(self.unit)
  {
    value: self.value + converted.value,
    uncertainty: rss(self.uncertainty, converted.uncertainty),
    unit: self.unit,
  }
}

///|
/// Adds two measured quantities, returning `None` when dimensions differ.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(1.0, 0.1, @si.meter)
///   let y = MeasuredQuantity::from_parts(1.0, 0.1, @si.second)
///   assert_true(x.checked_add(y) is None)
/// }
/// ```
pub fn MeasuredQuantity::checked_add(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity? {
  match other.checked_to(self.unit) {
    Some(converted) =>
      Some({
        value: self.value + converted.value,
        uncertainty: rss(self.uncertainty, converted.uncertainty),
        unit: self.unit,
      })
    None => None
  }
}

///|
/// Subtracts two independent measured quantities, propagating uncertainty by
/// root-sum-square.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.3, @si.meter)
///   let y = MeasuredQuantity::from_parts(5.0, 0.4, @si.meter)
///   let diff = x.sub(y)
///   assert_eq(diff.value(), 5.0)
///   assert_eq(diff.uncertainty(), 0.5)
/// }
/// ```
pub fn MeasuredQuantity::sub(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity raise @quantity.DimensionMismatch {
  let converted = other.to(self.unit)
  {
    value: self.value - converted.value,
    uncertainty: rss(self.uncertainty, converted.uncertainty),
    unit: self.unit,
  }
}

///|
/// Subtracts two measured quantities, returning `None` when dimensions differ.
pub fn MeasuredQuantity::checked_sub(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity? {
  match other.checked_to(self.unit) {
    Some(converted) =>
      Some({
        value: self.value - converted.value,
        uncertainty: rss(self.uncertainty, converted.uncertainty),
        unit: self.unit,
      })
    None => None
  }
}

///|
/// Multiplies two independent measured quantities and propagates relative
/// uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   let width = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
///   let height = MeasuredQuantity::from_parts(3.0, 0.2, @si.meter)
///   let area = width.mul(height)
///   assert_eq(area.value(), 6.0)
///   assert_true(area.unit().is_compatible(@si.meter.pow(2)))
/// }
/// ```
pub fn MeasuredQuantity::mul(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity raise ZeroNominalForRelativeUncertainty {
  let value = self.value * other.value
  let rel = rss(
    relative_component(self.value, self.uncertainty),
    relative_component(other.value, other.uncertainty),
  )
  { value, uncertainty: abs_double(value) * rel, unit: self.unit * other.unit }
}

///|
/// Multiplies two measured quantities, returning `None` when relative
/// uncertainty cannot be computed because either nominal value is zero.
///
/// # Example
///
/// ```mbt check
/// test {
///   let zero = MeasuredQuantity::from_parts(0.0, 0.1, @si.meter)
///   let time = MeasuredQuantity::from_parts(2.0, 0.1, @si.second)
///   assert_true(zero.checked_mul(time) is None)
/// }
/// ```
pub fn MeasuredQuantity::checked_mul(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity? {
  match
    (
      checked_relative_component(self.value, self.uncertainty),
      checked_relative_component(other.value, other.uncertainty),
    ) {
    (Some(self_rel), Some(other_rel)) => {
      let value = self.value * other.value
      Some({
        value,
        uncertainty: abs_double(value) * rss(self_rel, other_rel),
        unit: self.unit * other.unit,
      })
    }
    _ => None
  }
}

///|
/// Divides two independent measured quantities and propagates relative
/// uncertainty.
///
/// # Example
///
/// ```mbt check
/// test {
///   let distance = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   let time = MeasuredQuantity::from_parts(2.0, 0.1, @si.second)
///   let speed = distance.div(time)
///   assert_eq(speed.value(), 5.0)
///   assert_true(speed.unit().is_compatible(@si.meter / @si.second))
/// }
/// ```
pub fn MeasuredQuantity::div(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity raise ZeroNominalForRelativeUncertainty {
  let value = self.value / other.value
  let rel = rss(
    relative_component(self.value, self.uncertainty),
    relative_component(other.value, other.uncertainty),
  )
  { value, uncertainty: abs_double(value) * rel, unit: self.unit / other.unit }
}

///|
/// Divides two measured quantities, returning `None` when relative uncertainty
/// cannot be computed because either nominal value is zero.
///
/// # Example
///
/// ```mbt check
/// test {
///   let distance = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   let zero_time = MeasuredQuantity::from_parts(0.0, 0.1, @si.second)
///   assert_true(distance.checked_div(zero_time) is None)
/// }
/// ```
pub fn MeasuredQuantity::checked_div(
  self : MeasuredQuantity,
  other : MeasuredQuantity,
) -> MeasuredQuantity? {
  match
    (
      checked_relative_component(self.value, self.uncertainty),
      checked_relative_component(other.value, other.uncertainty),
    ) {
    (Some(self_rel), Some(other_rel)) => {
      let value = self.value / other.value
      Some({
        value,
        uncertainty: abs_double(value) * rss(self_rel, other_rel),
        unit: self.unit / other.unit,
      })
    }
    _ => None
  }
}

///|
/// Scales a measured quantity by a dimensionless factor.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(2.0, 0.5, @si.meter).scale(-3.0)
///   assert_eq(x.value(), -6.0)
///   assert_eq(x.uncertainty(), 1.5)
/// }
/// ```
pub fn MeasuredQuantity::scale(
  self : MeasuredQuantity,
  factor : Double,
) -> MeasuredQuantity {
  {
    value: self.value * factor,
    uncertainty: self.uncertainty * abs_double(factor),
    unit: self.unit,
  }
}

///|
/// Raises a measured quantity to an integer power and propagates relative
/// uncertainty.
///
/// `n == 0` returns the dimensionless constant `1 ± 0`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let length = MeasuredQuantity::from_parts(2.0, 0.1, @si.meter)
///   let area = length.pow(2)
///   assert_eq(area.value(), 4.0)
///   assert_true(area.unit().is_compatible(@si.meter.pow(2)))
/// }
/// ```
pub fn MeasuredQuantity::pow(
  self : MeasuredQuantity,
  exponent : Int,
) -> MeasuredQuantity raise ZeroNominalForRelativeUncertainty {
  if exponent == 0 {
    return { value: 1.0, uncertainty: 0.0, unit: self.unit.pow(0) }
  }
  let value = double_pow(self.value, exponent)
  let rel = relative_component(self.value, self.uncertainty) *
    abs_int(exponent).to_double()
  { value, uncertainty: abs_double(value) * rel, unit: self.unit.pow(exponent) }
}

///|
/// Raises a measured quantity to an integer power, returning `None` when
/// relative uncertainty cannot be computed because the nominal value is zero.
///
/// `exponent == 0` is always valid and returns `1 ± 0`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let zero = MeasuredQuantity::from_parts(0.0, 0.1, @si.meter)
///   assert_true(zero.checked_pow(2) is None)
///   assert_eq(zero.checked_pow(0).unwrap().value(), 1.0)
/// }
/// ```
pub fn MeasuredQuantity::checked_pow(
  self : MeasuredQuantity,
  exponent : Int,
) -> MeasuredQuantity? {
  if exponent == 0 {
    return Some({ value: 1.0, uncertainty: 0.0, unit: self.unit.pow(0) })
  }
  match checked_relative_component(self.value, self.uncertainty) {
    Some(component) => {
      let value = double_pow(self.value, exponent)
      let rel = component * abs_int(exponent).to_double()
      Some({
        value,
        uncertainty: abs_double(value) * rel,
        unit: self.unit.pow(exponent),
      })
    }
    None => None
  }
}

///|
/// Formats a measured quantity as `<value> ± <uncertainty> <unit>` using
/// compact ASCII unit notation.
///
/// # Example
///
/// ```mbt check
/// test {
///   let x = MeasuredQuantity::from_parts(10.0, 0.2, @si.meter)
///   assert_eq(format_measured_quantity(x), "10 ± 0.2 m")
/// }
/// ```
pub fn format_measured_quantity(quantity : MeasuredQuantity) -> String {
  format_measured_quantity_with(quantity, @unit.FormatStyle::Ascii)
}

///|
/// Formats a measured quantity using a LunarUnits formatting style.
///
/// # Example
///
/// ```mbt check
/// test {
///   let speed = MeasuredQuantity::from_parts(5.0, 0.3, @si.meter / @si.second)
///   assert_eq(
///     format_measured_quantity_with(speed, @unit.FormatStyle::Ascii),
///     "5 ± 0.3 m/s",
///   )
/// }
/// ```
pub fn format_measured_quantity_with(
  quantity : MeasuredQuantity,
  style : @unit.FormatStyle,
) -> String {
  "\{quantity.value} ± \{quantity.uncertainty} \{@unit.format_unit_with(quantity.unit, style)}"
}
