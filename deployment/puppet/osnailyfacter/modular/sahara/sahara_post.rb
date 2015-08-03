require File.join File.dirname(__FILE__), '../test_common.rb'

class SaharaPostTest < Test::Unit::TestCase

  def test_sahara_api_is_running
    assert TestCommon::Process.running?('sahara-api'), 'Sahara-api is not running!'
  end

  def test_sahara_engine_is_running
    assert TestCommon::Process.running?('sahara-engine'), 'Sahara-engine is not running!'
  end

  def test_sahara_haproxy_backend_online
    assert TestCommon::HAProxy.backend_up?('sahara'), 'Sahara HAProxy backend is not up!'
  end

end
