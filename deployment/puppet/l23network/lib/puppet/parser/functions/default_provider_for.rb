
module Puppet::Parser::Functions
  newfunction(:default_provider_for, :type => :rvalue, :doc => <<-EOS
  Get the default provider of a type
  EOS
  ) do |argv|
    type_name = argv[0]
    fail('No type name provided!') if ! type_name
    Puppet::Type.loadall()
    type_name = type_name.capitalize.to_sym
    return 'undef' if ! Puppet::Type.const_defined? type_name
    type = Puppet::Type.const_get type_name
    provider = type.defaultprovider
    return 'undef' if ! provider
    rv = provider.name.to_s
    debug("Default provider for type '#{type_name}' is a '#{rv}'.")
    return rv
  end
end