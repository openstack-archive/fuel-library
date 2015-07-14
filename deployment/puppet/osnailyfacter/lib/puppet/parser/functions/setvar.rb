Puppet::Parser::Functions::newfunction(
    :setvar,
    :arity => 2,
    :doc => <<-EOS
Set the value of a variable in the local scope.
Yes, now you actually can do it!

For example:

$var = '1'
notice($var) # -> '1'
setvar('var', '2')
notice($var) # -> '2'
EOS
) do |argv|

  variable = argv[0].to_s
  fail 'There is no variable name!' if variable.empty?

  value = argv[1]
  allowed_values = [NilClass, TrueClass, FalseClass, String, Array, Hash]
  value = value.to_s unless allowed_values.find { |av| value.instance_of? av }

  class << self
    attr_reader :ephemeral
  end unless self.respond_to? :ephemeral

  table = ephemeral.first

  class << table
    attr_reader :parent
  end unless table.respond_to? :parent

  fail 'Could not get the local scope!' unless table.parent.is_local_scope?

  local_scope = table.parent

  class << local_scope
    attr_reader :symbols
  end unless local_scope.respond_to? :symbols

  local_scope.symbols[variable] = value

end
