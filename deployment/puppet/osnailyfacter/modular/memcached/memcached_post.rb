require File.join File.dirname(__FILE__), '../test_common.rb'

class MemcachedPostTest < Test::Unit::TestCase
  def test_memcached_is_running
    assert TestCommon::Process.running?('memcached'), 'Memcached is not running!'
  end

  def test_memcached_on_internal
    ip = TestCommon::Settings.internal_address
    assert TestCommon::Network.connection?(ip, 11211), 'Cannot connect to memcached on the internal address!'
  end

  def test_memcached_no_public
    ip = TestCommon::Settings.public_address
    assert TestCommon::Network.no_connection?(ip, 11211), 'Memcached should not be accessible from the public network!'
  end
end
