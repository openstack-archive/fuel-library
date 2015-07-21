module Util
  # Splits the rightmost part of a string using '::' as delimiter
  # Returns an array of both parts or nil if either is empty.
  # An empty rightmost part is ignored and converted as 'string::' => 'string'
  #
  # Examples:
  # "foo"             -> ["foo", nil]
  # "foo::"           -> ["foo", nil]
  # "foo::bar"        -> ["foo", "bar"]
  # "foo::bar::"      -> ["foo", "bar"]
  # "::foo"           -> [nil, "foo"]
  # "::foo::"         -> [nil, "foo"]
  # "foo::bar::baz"   -> ["foo::bar", "baz"]
  # "foo::bar::baz::" -> ["foo::bar", "baz"]
  #
  def self.split_domain(str)
    left, right = nil, nil
    unless str.nil?
      left, delimiter, right = str.gsub(/::$/, '').rpartition('::')
      left, right = right, nil if delimiter.empty?
      left = nil if left.empty?
    end
    return [left, right]
  end
end
