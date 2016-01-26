Puppet::Parser::Functions::newfunction(:nic_whitelist_to_mappings, :type => :rvalue, :doc => <<-EOS
converts nic whitelist to bridge mappings
EOS
) do |argv|

  raise Puppet::ParseError, 'Only one argument is allowed.' if argv.size != 1

  nics = argv[0]
  return nics.map {|x| "#{x['physical_network']}:#{x['devname']}"}
end

