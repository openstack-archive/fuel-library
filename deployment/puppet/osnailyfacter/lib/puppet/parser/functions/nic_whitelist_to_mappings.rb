Puppet::Parser::Functions::newfunction(:nic_whitelist_to_mappings, :type => :rvalue, :doc => <<-EOS
converts nic whitelist to bridge mappings
EOS
) do |argv|

  if argv.size > 1
    raise Puppet::ParseError, 'Only one argument is allowed.'
  elsif argv.size == 0
    return
  end

  nics = argv[0]
  return nics.map {|x| "#{x['physical_network']}:#{x['devname']}"}
end

