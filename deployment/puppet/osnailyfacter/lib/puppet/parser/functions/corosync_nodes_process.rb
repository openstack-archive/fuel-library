Puppet::Parser::Functions::newfunction(:corosync_nodes_process, :type => :rvalue, :doc => <<-EOS
From a given input corosync_nodes structure,
return new structure comprising:
a) extracted node IPs as new 'ips' key
b) extracted corosync node IDs as new 'ids' key
Works only with the corosync_nodes hash and relies on the
related corosync_nodes function errors processing!
EOS
) do |argv|
  data = {
   'ips' => [],
   'ids' => [],
  }

  argv.first.sort_by do |host, attrs|
    attrs['id'].to_i
  end.each do |host, attrs|
    next unless attrs['ip'] and attrs['id']
    data['ips'] << attrs['ip']
    data['ids'] << attrs['id']
  end

  return data
end
