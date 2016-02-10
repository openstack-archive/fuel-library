require File.join File.dirname(__FILE__), '../test_common.rb'

class MemcachedPostTest < Test::Unit::TestCase
  def test_memcached_is_running
    assert TestCommon::Process.running?('memcached'), 'Memcached is not running!'
  end

  def get_node
    metadata = TestCommon::Settings.network_metadata
    node_name = TestCommon::Settings.node_name
    return metadata['nodes'][node_name]
  end

  def test_memcached_listen
    ip = get_node['network_roles']['mgmt/memcache']
    assert TestCommon::Network.connection?('127.0.0.1', 11211), 'Cannot connect to memcached on the internal address!'
  end
end
