require File.join File.dirname(__FILE__), '../test_common.rb'

class HorizonPreTest < Test::Unit::TestCase
  def test_memcached_is_running
    assert TestCommon::Process.running?('memcached'), 'Memcached is not running!'
  end

  def test_memcached_on_localhost
    ip = '127.0.0.1'
    assert TestCommon::Network.connection?(ip, 11211), 'Can not connect to memcached on this host!'
  end
end
