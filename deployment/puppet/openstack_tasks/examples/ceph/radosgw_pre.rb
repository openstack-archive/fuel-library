require File.join File.dirname(__FILE__), '../test_common.rb'

class RadosgwPreTest < Test::Unit::TestCase
  def test_keystone_backend_online
    assert TestCommon::HAProxy.backend_up?('keystone-1'), 'Haproxy keystone backend is down!'
  end
end
