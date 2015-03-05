require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

PUBLIC_BACKEND = 'keystone-1'
ADMIN_BACKEND  = 'keystone-2'

class KeystonePreTest < Test::Unit::TestCase

  def test_haproxy_public_backend_present
    assert HAProxy.backend_present?(PUBLIC_BACKEND), "There is no '#{PUBLIC_BACKEND}' HAProxy backend!"
  end

  def test_haproxy_admin_backend_present
    assert HAProxy.backend_present?(ADMIN_BACKEND), "There is no '#{ADMIN_BACKEND}' HAProxy backend!"
  end

  def test_mysql_accessible_for_keystone
    MySQL.pass = Settings.keystone['db_password']
    MySQL.user = 'keystone'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    MySQL.db = 'keystone'
    assert MySQL.connection?, 'Cannot connect to MySQL with Keystone auth!'
  end

  def test_amqp_accessible
    user = Settings.rabbit['user']
    password = Settings.rabbit['password']
    host = Settings.management_vip
    assert AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end

end
