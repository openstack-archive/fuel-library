Puppet::Parser::Functions::newfunction(:corosync_nodes_process, :type => :rvalue, :doc => <<-EOS
Sort the given input corosync_nodes structure by node IDs.
Then return new structure comprising:
a) extracted node IPs as new 'ips' key
b) extracted corosync node IDs as new 'ids' key
c) extracted node names as new 'hosts' key.
Works only with the corosync_nodes hash and relies on the
related corosync_nodes function errors processing!
EOS
) do |argv|
  data={}
  data['hosts'] = []
  data['ips'] = []
  data['ids'] = []

  sorted = *argv[0].sort_by do |host,attrs|
    next unless attrs['id']
    attrs['id'].to_i
  end

  sorted.each do |host,attrs|
    next unless attrs['ip']
    data['hosts'] << host
    data['ips'] << attrs['ip']
  end

  sorted.each do |host,attrs|
    next unless attrs['id']
    data['ids'] << attrs['id']
  end

  return data
end
