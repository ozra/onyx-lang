module Crystal::NumberVerificationUtils
  extend self

  IntrinsicIntegerSuffixes = Set{
    "i8", "i16", "i32", "i64",
    "u8", "u16", "u32", "u64",
    "int", "nat", "uint",
    "archint", "archnat", "archuint",
  }

  IntrinsicNonRealSuffixes = Set{
    "i8", "i16", "i32", "i64",
    "u8", "u16", "u32", "u64",
    "int", "nat", "uint",
    "archint", "archnat", "archuint",
    "str"
  }

  IntrinsicSuffixesToKind = {
    # The following recursive ugliness is for Crox–to_s
    "unspec" => :unspec,
    "unspec_int" => :unspec_int,
    "unspec_real" => :unspec_real,

    "i8" => :i8, "i16" => :i16, "i32" => :i32, "i64" => :i64,
    "u8" => :u8, "u16" => :u16, "u32" => :u32, "u64" => :u64,
    "f32" => :f32, "f64" => :f64,
    "f" => :f32, "d" => :f64,
    "int" => :int, "nat" => :nat, "uint" => :uint,
    "archint" => :archint, "archnat" => :archnat, "archuint" => :archuint,
    "nat" => :nat,   # *TODO*
    "real" => :real,
    "big" => :big,    # *TODO*
    "str" => :str
  }

  macro inline_int_fits_in_size_check(type, method, size)
    return true if num_size < {{size}}
    int_value = absolute_integer_value(string_value, is_negative)
    max = {{type}}::MAX.{{method}} + (is_negative ? 1 : 0)
    return int_value <= max
  end

  macro inline_uint_fits_in_size_check(type, size)
    return false if is_negative
    return true  if num_size < {{size}}
    int_value = absolute_integer_value(string_value, is_negative)
    return int_value <= {{type}}::MAX
  end

  def integer_literal_fits_in_size?(string_value, kind : Symbol, num_size, start : Int32, is_negative : Bool)
    case kind
    when :i8  then inline_int_fits_in_size_check Int8, to_u8, 3
    when :u8  then inline_uint_fits_in_size_check UInt8, 3
    when :i16 then inline_int_fits_in_size_check Int16, to_u16, 5
    when :u16 then inline_uint_fits_in_size_check UInt16, 5
    when :i32 then inline_int_fits_in_size_check Int32, to_u32, 10
    when :u32 then inline_uint_fits_in_size_check UInt32, 10
    when :i64 then inline_int_fits_in_size_check Int64, to_u64, 19
    when :u64 then return value_fits_in_u64? string_value, is_negative, num_size, start
    else      then raise "integer_literal_fits_in_size? called with kind '#{kind}' which it doesn't understand!"
    end
  end

  def deduce_integer_kind(string_value, kind : Symbol, num_size, start : Int32, is_negative : Bool, allow_implicit_bigint : Bool)
    return :i32 if num_size < 10

    if !value_fits_in_u64? string_value, is_negative, num_size, start
      return :unspec unless allow_implicit_bigint
      return :big
    end

    int_value = absolute_integer_value(string_value, is_negative)
    int64max = Int64::MAX.to_u64 + (is_negative ? 1 : 0)
    return :u64 if int_value > int64max

    int32max = Int32::MAX.to_u32 + (is_negative ? 1 : 0)
    return :i64 if int_value > int32max

    return :i32
  end

  def absolute_integer_value(string_value, is_negative)
    is_negative ? string_value[1..-1].to_u64 : string_value.to_u64
  end

  def value_fits_in_u64?(string_value, is_negative, num_size, start)
    return false if is_negative
    return false if num_size > 20
    return true  if num_size < 20

    i = 0
    "18446744073709551615".each_byte do |reference_byte|
      string_byte = string_value.byte_at(i)
      if string_byte > reference_byte
        return false
      elsif string_byte < reference_byte
        return true
      end
      i += 1
    end

    return true
  end

end
