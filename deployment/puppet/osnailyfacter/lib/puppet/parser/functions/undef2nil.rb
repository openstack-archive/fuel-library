module Puppet::Parser::Functions
  newfunction(
      :undef2nil,
      :type => :rvalue,
      :doc => <<-EOS
Replaces all :undef values with the "nil" values.
Useful for Puppet 4 compatibility problems.
  EOS
  ) do |argument|
    argument = argument.first

    undef2nil = lambda do |structure|
      if structure.is_a? Array
        structure.map do |element|
          undef2nil.call element
        end
      elsif structure.is_a? Hash
        hash = {}
        structure.each do |key, value|
          hash.store key, undef2nil.call(value)
        end
        hash
      else
        break nil if structure == :undef
        structure
      end
    end

    undef2nil.call argument
  end
end
