module Puppet::Parser::Functions
  newfunction(:default_provider_for, :type => :rvalue, :doc => <<-EOS
  Get the default provider of a type
  EOS
  ) do |argv|
    type_name = argv[0]
    fail 'No type name provided!' unless type_name
    type_name = type_name.to_s.downcase.to_sym
    type = Puppet::Type.type type_name
    return nil unless type
    provider = type.defaultprovider
    return nil unless provider
    provider_name = provider.name.to_s
    debug "default_provider_for() default provider for type '#{type_name}' is a '#{provider_name}'"
    return provider_name
  end
end