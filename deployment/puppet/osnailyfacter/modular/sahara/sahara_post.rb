require File.join File.dirname(__FILE__), '../test_common.rb'

class SaharaPostTest < Test::Unit::TestCase

  def test_sahara_is_running
    assert TestCommon::Process.running?('sahara-all'), 'Sahara-all is not running!'
  end

  def test_sahara_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('sahara'), 'Sahara HAProxy backend is not up!'
  end

  def test_sahara_api_url_accessible
    ip = TestCommon::Settings.management_vip
    port = 8386
    url = "http://#{ip}:#{port}"
    assert TestCommon::Network.url_accessible?(url), "Sahara-api url '#{url}' is not accessible!"
  end

end
