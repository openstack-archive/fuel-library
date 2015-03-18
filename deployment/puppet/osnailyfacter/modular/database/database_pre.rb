require File.join File.dirname(__FILE__), '../test_common.rb'

BACKEND = 'mysqld'

class DatabasePreTest < Test::Unit::TestCase

  def test_haproxy_stats_accessible
    url = TestCommon::HAProxy.stats_url
    assert TestCommon::Network.url_accessible?(url), "Cannot connect to the HAProxy stats url '#{url}'!"
  end

  def test_mysqld_haproxy_backend_present
    assert TestCommon::HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_pacemaker_installed
    assert TestCommon::Pacemaker.online?, 'Pacemaker is not running!'
  end

end
