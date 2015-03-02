require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

BACKEND = 'mysqld'

class DatabaseInstallPreTest < Test::Unit::TestCase

  def test_mysqld_haproxy_backend_present
    assert HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_pacemaker_installed
    assert Pacemaker.online?, 'Pacemaker is not running!'
  end

end
