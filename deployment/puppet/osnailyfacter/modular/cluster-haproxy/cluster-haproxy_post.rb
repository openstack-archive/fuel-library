require File.join File.dirname(__FILE__), '../test_common.rb'

class ClusterHaproxyPostTest < Test::Unit::TestCase
  def test_haproxy_config_present
    assert File.file?('/etc/haproxy/haproxy.cfg'), 'No haproxy config file!'
  end

  def test_haproxy_is_running
    assert TestCommon::Process.running?('/usr/sbin/haproxy'), 'Haproxy is not running!'
  end

  def test_haproxy_stats_accessible
    url = TestCommon::HAProxy.stats_url
    assert TestCommon::Network.url_accessible?(url), "Cannot connect to the HAProxy stats url '#{url}'!"
  end
end
