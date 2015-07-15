require File.join File.dirname(__FILE__), '../test_common.rb'

class IronicPostTest < Test::Unit::TestCase
  def test_ironic_is_running
    assert TestCommon::Process.running?('ironic-api'), 'Ironic-api is not running!'
  end

  def test_ironic_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('ironic'), 'Ironic HAProxy backend is not up!'
  end
end
