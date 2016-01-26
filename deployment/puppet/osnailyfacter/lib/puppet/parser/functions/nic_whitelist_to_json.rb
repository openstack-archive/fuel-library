Puppet::Parser::Functions::newfunction(:nic_whitelist_to_json, :type => :rvalue, :doc => <<-EOS
converts nic whitelist to json
EOS
) do |argv|

  raise Puppet::ParseError, 'Only one argument is allowed.' if argv.size != 1

  nics = argv[0]
  return nics.to_json
end

