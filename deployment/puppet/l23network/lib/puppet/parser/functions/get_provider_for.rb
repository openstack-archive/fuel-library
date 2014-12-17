
module Puppet::Parser::Functions
  newfunction(:get_provider_for, :type => :rvalue, :doc => <<-EOS
  Get the default provider of a type
  EOS
  ) do |argv|
    type_name = argv[0]
    res_name = argv[1]
    fail('No type name provided!') if ! type_name
    Puppet::Type.loadall()
    type_name = type_name.capitalize.to_sym
    return 'undef' if ! Puppet::Type.const_defined? type_name
    type = Puppet::Type.const_get type_name
# require 'pry'
# binding.pry
    type.loadall()
    rv = type.instances.select{|i| i.name.to_s.downcase == res_name.to_s.downcase}.map{|j| j[:provider].to_s}
# require 'pry'
# binding.pry
    rv = rv[0]
    debug("Provider for '#{type_name}[#{res_name}]' is a '#{rv}'.")
    return rv
  end
end