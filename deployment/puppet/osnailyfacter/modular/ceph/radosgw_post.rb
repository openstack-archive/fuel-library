require File.join File.dirname(__FILE__), '../test_common.rb'

class RadosgwPostTest < Test::Unit::TestCase
  def test_radosgw_process_running
    assert TestCommon::Process.running?('radosgw'), 'Radosgw process is not running!'
  end

  def test_radosgw_backend_online
    assert TestCommon::Network.connection?('localhost', 6780), 'Can not connect to radoswg port 6780 on this host!'
  end
end
