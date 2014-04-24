module Puppet::Parser::Functions
  newfunction(:mongo_hosts, :type => :rvalue, :doc => <<-EOS
  Return a comma-separated list of hosts with roles 'primary-mongo' and 'mongo'
  Argument1: $nodes_hash, mandatory argument
  Argument2: 'array' or 'string' Return values as an array or a string? Default: string
  Argument3: roles to select, primary-mongo and mongo by default
  Returns: a string of ips, separated by a comma
  EOS
  ) do |args|
    nodes = args[0]
    type  = args[1] || 'string'
    roles = args[2] || %w(primary-mongo mongo)

    roles = Array(roles) unless roles.is_a?(Array)

    unless nodes.is_a?(Array) && nodes.any? && nodes.first.is_a?(Hash) && nodes.first['uid']
      raise Puppet::ParseError, 'You should provide $nodes_hash as the first argument of this fuction! It should be an array of hashes with node information.'
    end

    unless %w(array string).include? type
      raise Puppet::ParseError, 'Type should be either array or string!'
    end

    unless roles.any?
      raise Puppet::ParseError, 'You should give at list one role to filter!'
    end

    hosts = []
    roles.each do |r|
      nodes.inject(hosts) do |h,n|
        h.push(n['internal_address']) if (n['role'] == r) && n['internal_address']
        h
      end
    end

    if type == 'string'
      hosts.join(',')
    else
      hosts
    end

  end
end