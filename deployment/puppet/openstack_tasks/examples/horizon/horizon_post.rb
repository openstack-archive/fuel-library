require File.join File.dirname(__FILE__), '../test_common.rb'

class HorizonPostTest < Test::Unit::TestCase
  def test_horizon_backend_online
    assert TestCommon::HAProxy.backend_up?('horizon'), 'Haproxy horizon backend is not online!'
  end
end

