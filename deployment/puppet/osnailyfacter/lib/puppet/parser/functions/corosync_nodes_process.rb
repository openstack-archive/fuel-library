Puppet::Parser::Functions::newfunction(:corosync_nodes_process, :type => :rvalue, :doc => <<-EOS
From a given input corosync_nodes structure,
return new structure comprising:
a) extracted node IPs as new 'ips' key
b) extracted corosync node IDs as new 'ids' key
Works only with the corosync_nodes hash and relies on the
related corosync_nodes function errors processing!
EOS
) do |argv|
  data={}
  data['ips'] = []
  data['ids'] = []

  struct = *argv[0]
  struct.each do |host,attrs|
    next unless attrs['ip']
    data['ips'] << attrs['ip']
  end

  struct.each do |host,attrs|
    next unless attrs['id']
    data['ids'] << attrs['id']
  end

  return data
end
