require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

BACKEND = 'mysqld'

class DatabasePreTest < Test::Unit::TestCase

  def test_haproxy_stats_accessible
    assert Net.url_accessible?(HAProxy.stats_url), "Cannot connect to the HAProxy stats url '#{HAProxy.stats_url}'!"
  end

  def test_mysqld_haproxy_backend_present
    assert HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_pacemaker_installed
    assert Pacemaker.online?, 'Pacemaker is not running!'
  end

end
