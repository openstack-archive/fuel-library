module Puppet::Parser::Functions
  newfunction(:get_provider_for, :type => :rvalue, :doc => <<-EOS
  Get resource provider by given name and type
  EOS
  ) do |argv|
    type_name = argv[0].to_s
    resource_name = argv[1].to_s
    fail('No type name provided!') if ! type_name
    # type.loadall()
    resource = catalog.resources.select{|res| res.type.to_s==type_name and res.title.to_s==resource_name }[0]
    ( resource.nil?  ?  nil  :  resource[:provider].to_s )
  end
end
