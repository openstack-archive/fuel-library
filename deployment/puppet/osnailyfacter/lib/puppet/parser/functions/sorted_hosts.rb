require 'ipaddr'

Puppet::Parser::Functions::newfunction(:sorted_hosts, :type => :rvalue, :doc => <<-EOS
Get an aray of sorted host names or IP addresses
from the hostname to IP mapping hash.
EOS
) do |argv|
  host_to_ip = argv[0]
  fail 'The first argument should be a host name to IP mapping!' unless host_to_ip.is_a? Hash
  extract_array = argv[1] || 'host'
  fail 'Only "hostname" or "ip" array can be extracted!' unless %w(host ip).include? extract_array
  sort_by = argv[2] || 'host'
  fail 'Sorting can be performed only by "hostname" or "ip"' unless %w(host ip).include? sort_by
  host_to_ip = host_to_ip.sort_by do |hostname, ip|
    if sort_by == 'host'
      hostname =~ /(\d+)/
      [$1.to_i, hostname]
    elsif sort_by == 'ip'
      IPAddr.new ip
    end
  end
  host_to_ip.map do |hostname, ip|
    if extract_array == 'host'
      hostname
    elsif extract_array == 'ip'
      ip
    end
  end
end
