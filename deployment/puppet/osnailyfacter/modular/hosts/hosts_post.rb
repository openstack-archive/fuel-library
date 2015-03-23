require File.join File.dirname(__FILE__), '../test_common.rb'

class HostsPostTest < Test::Unit::TestCase

  def test_hosts_file_has_all_nodes
    nodes_array = TestCommon::Settings.nodes
    raise 'No nodes data!' unless nodes_array and nodes_array.is_a? Array
    hosts_file = File.read '/etc/hosts'
    nodes_array.each do |node|
      host_regexp1 = Regexp.new "#{node['internal_address']}\\s+#{node['fqdn']}\\s+#{node['name']}"
      host_regexp2 = Regexp.new "#{node['internal_address']}\\s+#{node['name']}\\s+#{node['fqdn']}"
      assert (hosts_file =~ host_regexp1 or hosts_file =~ host_regexp2), "Host #{node['name']} was not found in hosts file!"
    end
  end

end
