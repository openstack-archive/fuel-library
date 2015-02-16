require 'hiera'
require 'test/unit'

class HostsPostTest < Test::Unit::TestCase

  def test_hosts_file_has_all_nodes
    hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    nodes_array = hiera.lookup 'nodes', nil, {}
    hosts_file = File.read '/etc/hosts'
    nodes_array.each do |node|
      host_regexp = Regexp.new "#{node['internal_address']}\\s+#{node['fqdn']}\\s+#{node['name']}"
      assert hosts_file =~ host_regexp, "Host #{node['name']} was not found in hosts file!"
    end
  end

end
