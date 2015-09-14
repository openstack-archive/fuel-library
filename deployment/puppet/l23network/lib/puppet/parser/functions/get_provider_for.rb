module Puppet::Parser::Functions
  newfunction(:get_provider_for, :type => :rvalue, :doc => <<-EOS
  Get the default provider of a type
  EOS
  ) do |argv|
    type_name = argv[0]
    res_name = argv[1]
    fail('No type name provided!') if ! type_name
    # type.loadall()
    family = catalog.resources.select{|r| r.type.to_s==type_name.to_s}
    res = family.select{|r| r.title.to_s=='br-ovs1'}[0]
    ( res.nil?  ?  nil  :  res[:provider].to_s )
  end
end