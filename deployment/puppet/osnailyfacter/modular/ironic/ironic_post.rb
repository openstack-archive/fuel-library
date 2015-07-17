require File.join File.dirname(__FILE__), '../test_common.rb'

class IronicPostTest < Test::Unit::TestCase

  def test_ironic_is_running
    assert TestCommon::Process.running?('ironic-api'), 'Ironic-api is not running!'
  end

  def test_ironic_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('ironic-api'), 'Ironic-api HAProxy backend is not up!'
  end

  def test_ironic_baremetal_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('ironic-baremetal'), 'Ironic-baremetal HAProxy backend is not up!'
  end

  def test_ironic_api_url_accessible
    ip = TestCommon::Settings.management_vip
    port = 6385
    url = "http://#{ip}:#{port}"
    assert TestCommon::Network.url_accessible?(url), "Ironic-api url '#{url}' is not accessible!"
  end

end
