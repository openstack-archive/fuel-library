Puppet::Parser::Functions::newfunction(:nic_whitelist_to_json, :type => :rvalue, :doc => <<-EOS
converts nic whitelist to json
EOS
) do |argv|

  if argv.size > 1
    raise Puppet::ParseError, 'Only one argument is allowed.'
  elsif argv.size == 0
    return
  end

  nic_whitelist = argv[0]
  return nil unless nic_whitelist
  nic_whitelist.to_json
end

