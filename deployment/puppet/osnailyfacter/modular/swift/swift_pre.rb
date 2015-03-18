require File.join File.dirname(__FILE__), '../test_common.rb'

class SwiftPreTest < Test::Unit::TestCase
  def test_keystone_backend_online
    assert TestCommon::HAProxy.backend_up?('keystone-1'), 'Haproxy keystone-1 backend is down!'
    assert TestCommon::HAProxy.backend_up?('keystone-2'), 'Haproxy keystone-2 backend is down!'
  end
end
